package effect

import sdl "vendor:sdl3"
import yaml "../../../libs/odin-yaml"

import yaml_parse "../../data_load/yaml_parse"
import data_load "src:data_load"
import handle "../../handle"

import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import fmt "core:fmt"
import mem "core:mem"

Effect_Instance_Tag :: string

Effect_Instance_ID :: u32

// TODO: store instances in a allocated slice (not dynamic array)
Effect_Instance :: struct {
    definition: ^Effect_Definition,
    unique_tag: Effect_Instance_Tag,
    unique_id: Effect_Instance_ID,

    duration: f32,
    interval: f32,

    callback_data: Effect_Callback_Data,
}

effect_instances_load :: proc() {
    log.infof("Loading effect instances")

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

    pre_path := "data/effect/instances/"
    data_load.data_tag_resursive_grab_and_process_precursors(pre_path, "*.yaml", &file_paths)

    num_instances := len(file_paths) + 1
    global_effect_manager.unique_instance_ids = cast(u32) num_instances
    global_effect_manager.instances = make([]Effect_Instance, num_instances)
    instance_id_counter: Effect_Instance_ID = 0

    for path in file_paths {
        effect_instance_load(pre_path, path, &instance_id_counter, arena_alloc)
        delete(path)
    }
}

effect_instance_load :: proc(
    pre_path, file_path: string, counter: ^Effect_Instance_ID, arena_allocator: runtime.Allocator
) {
    defer counter^ += 1

    log.debugf("Loading effect instance %v", file_path)

    full_path := fmt.aprint(data_load.DATA_TAG_DEFAULT_ASSET_FOLDER, file_path, sep = "")
    defer delete(full_path)
    data_map, map_ok := yaml_parse.get_yaml_mapping(full_path, arena_allocator)
    if !map_ok {
        log.errorf("Failed in loading effect instance from path %v", full_path)
        return
    }

    new_instance: Effect_Instance
    defer global_effect_manager.instances[counter^] = new_instance

    new_instance.unique_id = counter^

    definition_tag := yaml_parse.read_value_from_map(data_map, "definition", string, default = "")
    definition_id, found := global_effect_manager.definition_tag_to_id[definition_tag]
    if !found {
        log.errorf("Could not find matching definition of tag %v for new instance from file %v", definition_tag, file_path)
        return
    }

    definition := &global_effect_manager.definitions[definition_id]

    new_instance.definition = definition

    new_instance.unique_tag = strings.clone(strings.trim_prefix(strings.trim_suffix(file_path, ".yaml"), pre_path))

    new_instance.duration = cast(f32) yaml_parse.read_value_from_map(data_map, "duration", f64, default = 0.0)
    new_instance.interval = cast(f32) yaml_parse.read_value_from_map(data_map, "interval", f64, default = 0.0)

    // Loading variable data
    callback_type, odin_callback := new_instance.definition.callback.(Odin_Effect_Callback)
    if !odin_callback do return

    new_instance.callback_data.type = callback_type

    switch callback_type {
    case .DAMAGE:
        var_data := Effect_Damage_Fn_Data{}
        var_data.damage = cast(f32) yaml_parse.read_value_from_map(data_map, "damage", f64, default = 0.0)

        new_instance.callback_data.data = var_data
    case .SPEED:
        var_data := Effect_Speed_Fn_Data{}
        var_data.add = cast(f32) yaml_parse.read_value_from_map(data_map, "damage", f64, default = 0.0)
        var_data.mult = cast(f32) yaml_parse.read_value_from_map(data_map, "damage", f64, default = 0.0)

        new_instance.callback_data.data = var_data
    case .POSITION:
        var_data := Effect_Position_Fn_Data{}

        direction_map := yaml_parse.read_value_from_map(data_map, "direction", yaml.Mapping, default = nil)
        var_data.direction.x = cast(f32) yaml_parse.read_value_from_map(direction_map, "x", f64, default = 0.0)
        var_data.direction.y = cast(f32) yaml_parse.read_value_from_map(direction_map, "y", f64, default = 0.0)

        var_data.speed = cast(f32) yaml_parse.read_value_from_map(data_map, "speed", f64, default = 0.0)

        new_instance.callback_data.data = var_data
    case .FORCE:
        var_data := Effect_Force_Fn_Data{}

        direction_map := yaml_parse.read_value_from_map(data_map, "direction", yaml.Mapping, default = nil)
        var_data.direction.x = cast(f32) yaml_parse.read_value_from_map(direction_map, "x", f64, default = 0.0)
        var_data.direction.y = cast(f32) yaml_parse.read_value_from_map(direction_map, "y", f64, default = 0.0)

        var_data.force = cast(f32) yaml_parse.read_value_from_map(data_map, "force", f64, default = 0.0)

        var_data.decay_rate = cast(f32) yaml_parse.read_value_from_map(data_map, "decay_rate", f64, default = 0.0)

        new_instance.callback_data.data = var_data
    }

    global_effect_manager.instance_tag_to_id[new_instance.unique_tag] = new_instance.unique_id

    log.debugf("Loaded effect instance %v", file_path)
}

effect_instances_unload :: proc() {
    log.infof("Unloading effect instances")

    for &instance in &global_effect_manager.instances {
        delete(instance.unique_tag)
    }
    defer delete(global_effect_manager.instances)
}