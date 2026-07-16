package entity

import sdl "vendor:sdl3"
import yaml "../../libs/odin-yaml"

import yaml_parse "../assets/yaml_parse"
import assets "../assets"
import handle "../handle"

import runtime "base:runtime"
import log "core:log"
import fmt "core:fmt"
import mem "core:mem"

Effect_Handle :: handle.Handle(handle.Effect_Tag)

// Defines what happens when an effect is attempted to be applied to an entity that already has said effect.
// NONE:    the effect is not applied
// REFRESH: the effect is applied, and the exisiting effect is removed. If the effect is pulse, then an extra pulse occurs.
// STACK:   the effect is applied
// EXTEND:  the effect is applied with its duration absorbing the remaining time left of the existing effect. The exisiting effect is removed.
//          if the effect is pulse, then the new effect's max applications absorbs the remaining applications of the exisiting effect.
Stack_Behaviour :: enum { NONE, REFRESH, STACK, EXTEND }

Effect_Type :: enum { PULSE, CONTINUOUS }

Effect_Definition_Tag :: distinct string
Effect_Definition_ID :: distinct u32

// TODO: store definitions in a allocated slice (not dynamic array)
Effect_Definition :: struct {
    callback: Effect_Callback,
    unique_id: Effect_Definition_ID,
    unique_tag: Effect_Definition_Tag,
    stack_behaviour: Stack_Behaviour,
    type: Effect_Type,
}

effect_definitions_load :: proc(effect_manager: ^Effect_Manager) {
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

    pre_path := "assets/data/effect/definitions/"
    assets.data_tag_resursive_grab_and_process_precursors(pre_path, "*.yaml", &file_paths)

    for path in file_paths {
        effect_definition_load(effect_manager, pre_path, path, arena_alloc)
        delete(path)
    }
}

effect_definition_load :: proc(effect_manager: ^Effect_Manager, pre_path, file_path: string, arena_allocator: runtime.Allocator) {
    data_map, map_ok := yaml_parse.get_yaml_mapping(file_path, arena_allocator)
    if !map_ok {
        log.errorf("Failed in loading effect instance from path %v", file_path)
        return
    }


}

effect_definitions_unload :: proc(effect_manager: ^Effect_Manager) {
    defer delete(effect_manager.definitions)
}