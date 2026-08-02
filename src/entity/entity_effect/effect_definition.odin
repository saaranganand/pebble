package effect

import yaml_parse "src:data_load/yaml_parse"
import data_load "src:data_load"
import handle "src:handle"

import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import fmt "core:fmt"
import mem "core:mem"

Effect_Handle :: handle.Effect_Handle

// Defines what happens when an effect is attempted to be applied to an entity that already has said effect.
// NONE:    the effect is not applied
// REFRESH: the effect is applied, and the exisiting effect is removed. If the effect is pulse, then an extra pulse occurs.
// STACK:   the effect is applied
// EXTEND:  the effect is applied with its duration absorbing the remaining time left of the existing effect. The exisiting effect is removed.
//          if the effect is pulse, then the new effect's max applications absorbs the remaining applications of the exisiting effect.
Stack_Behaviour :: enum { NONE, REFRESH, STACK, EXTEND }

Effect_Type :: enum { PULSE, CONTINUOUS, SINGLE }

Effect_Definition_Tag :: string
Effect_Definition_ID :: u32

// TODO: store definitions in a allocated slice (not dynamic array)
Effect_Definition :: struct {
    callback: Effect_Callback,
    unique_id: Effect_Definition_ID,
    unique_tag: Effect_Definition_Tag,
    stack_behaviour: Stack_Behaviour,
    type: Effect_Type,
}

effect_definitions_load :: proc() {
    log.infof("Loading effect definitions")

    // Lib yaml binding requires use of arena allocator (good one)
    arena_memory := make([]byte, 1*mem.Megabyte)
    defer delete(arena_memory)

    // To be clear, only when explicitly using this new allocator is it used.
    // It is not replacing the context allocator for this scope, since we need to allocate things here
    // that will last until possibly shutdown.
    config_arena: mem.Arena
    mem.arena_init(&config_arena, arena_memory)
    arena_alloc := mem.arena_allocator(&config_arena)

    file_paths := make([dynamic]string)
    defer delete(file_paths)

    pre_path := "data/effect/definitions/"
    data_load.data_tag_resursive_grab_and_process_precursors(pre_path, "*.yaml", &file_paths)

    num_definitions := len(file_paths)
    global_effect_manager.unique_definition_ids = cast(u32) num_definitions
    global_effect_manager.definitions = make([]Effect_Definition, num_definitions)
    definition_id_counter: Effect_Definition_ID = 0

    for path in file_paths {
        effect_definition_load(pre_path, path, &definition_id_counter, arena_alloc)
        delete(path)
    }
}

effect_definition_load :: proc(
    pre_path, file_path: string, counter: ^Effect_Definition_ID, arena_allocator: runtime.Allocator
) {
    defer counter^ += 1

    full_path := fmt.aprint(data_load.DATA_TAG_DEFAULT_ASSET_FOLDER, file_path, sep = "")
    defer delete(full_path)
    data_map, map_ok := yaml_parse.get_yaml_mapping(full_path, arena_allocator)
    if !map_ok {
        log.errorf("Failed in loading effect definition from path %v", file_path)
        return
    }

    log.debugf("Loading effect definition %v", file_path)

    new_definition: Effect_Definition
    defer global_effect_manager.definitions[counter^] = new_definition

    new_definition.unique_id = counter^

    new_definition.unique_tag = strings.clone(strings.trim_prefix(strings.trim_suffix(file_path, ".yaml"), pre_path))

    new_type := yaml_parse.read_value_from_map(data_map, "type", string, default = "")
    new_behaviour := yaml_parse.read_value_from_map(data_map, "stack_behaviour", string, default = "")
    new_callback := yaml_parse.read_value_from_map(data_map, "callback", string, default = "")

    new_definition.callback = effect_callback_from_string(new_callback)

    switch new_type {
    case "PULSE":
        new_definition.type = .PULSE
    case "CONTINUOUS":
        new_definition.type = .CONTINUOUS
    case "SINGLE":
        new_definition.type = .SINGLE
    case:
        log.errorf("Error in reading effect definition %v, type was not one of pulse or continuous", new_definition.unique_tag)
    }

    switch new_behaviour {
    case "NONE":
        new_definition.stack_behaviour = .NONE
    case "EXTEND":
        new_definition.stack_behaviour = .EXTEND
    case "STACK":
        new_definition.stack_behaviour = .STACK
    case "REFRESH":
        new_definition.stack_behaviour = .REFRESH
    case:
        log.errorf("Error in reading effect definition %v, stack logic was not one of none, extend, stack, or refresh", new_definition.unique_tag)
    }

    global_effect_manager.definition_tag_to_id[new_definition.unique_tag] = new_definition.unique_id

    log.debugf("Loaded effect definition %v", file_path)
}

effect_definitions_unload :: proc() {
    log.infof("Unloading effect definitions")

    for &definition in &global_effect_manager.definitions {
        delete(definition.unique_tag)
    }
    defer delete(global_effect_manager.definitions)
}