package entity

import sdl "vendor:sdl3"
import yaml "../../libs/odin-yaml"

import yaml_parse "../assets/yaml_parse"
import assets "../assets"
import handle "../handle"

import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import fmt "core:fmt"
import mem "core:mem"

Effect_Instance_Tag :: distinct string

Effect_Instance_ID :: distinct u32

// TODO: store instances in a allocated slice (not dynamic array)
Effect_Instance :: struct {
    definition: ^Effect_Definition,
    unique_tag: Effect_Instance_Tag,
    unique_id: Effect_Instance_ID,

    duration: f32,
    interval: f32,

    callback_data: Effect_Callback_Data,
}

effect_instances_load :: proc(effect_manager: ^Effect_Manager) {
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

    pre_path := "assets/data/effect/instances/"
    assets.data_tag_resursive_grab_and_process_precursors(pre_path, "*.yaml", &file_paths)

    num_instances := len(file_paths) + 1
    effect_manager.unique_instance_ids = cast(Effect_Instance_ID) num_instances
    effect_manager.instances = make([]Effect_Instance, num_instances)
    instance_id_counter: Effect_Instance_ID = 0

    for path in file_paths {
        effect_instance_load(effect_manager, pre_path, path, &instance_id_counter, arena_alloc)
        delete(path)
    }
}

effect_instance_load :: proc(
    effect_manager: ^Effect_Manager, pre_path, file_path: string, counter: ^Effect_Instance_ID, arena_allocator: runtime.Allocator
) {
    defer counter^ += 1

    data_map, map_ok := yaml_parse.get_yaml_mapping(file_path, arena_allocator)
    if !map_ok {
        log.errorf("Failed in loading effect instance from path %v", file_path)
        return
    }

    new_instance: Effect_Instance
    defer effect_manager.instances[counter^] = new_instance

    new_instance.unique_id = counter^

    definition_tag := cast(Effect_Definition_Tag) yaml_parse.read_value_from_map(data_map, "definition", string, default = "")
    definition_id, found := effect_manager.definition_tag_to_id[definition_tag]
    if !found {
        log.errorf("Could not find matching definition of tag %v for new instance from file %v", definition_tag, file_path)
        return
    }

    definition := &effect_manager.definitions[definition_id]

    new_instance.definition = definition

    new_instance.unique_tag = cast(Effect_Instance_Tag) strings.clone(strings.trim_prefix(strings.trim_suffix(file_path, ".yaml"), pre_path))

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
    case .FORCE:
    }

    /*
    instance.source_img_tag = cast(Data_Tag) strings.clone(yaml_parse.read_value_from_map(data_map, "img_tag", string, default = ""))

    instance.animations = make(map[Animation_Tag]Animation_Data)

    animation_list := yaml_parse.read_value_from_map(data_map, "animations", yaml.Mapping, default = nil)
    for name, _ in animation_list {
        tag := cast(Animation_Tag) strings.clone(name)
        animation_data := yaml_parse.read_value_from_map(animation_list, name, yaml.Mapping, default = nil)

        read_fps := yaml_parse.read_value_from_map(animation_data, "fps", f64, default = 1)
        read_looping := yaml_parse.read_value_from_map(animation_data, "looping", bool, default = false)
        read_scale := yaml_parse.read_value_from_map(animation_data, "scale", f64, default = 1)
        read_frame_data := yaml_parse.read_value_from_map(animation_data, "frames", yaml.Sequence, default = nil)

        instance.animations[tag] = animation_data_create(cast(f32) read_fps, read_looping, cast(f32) read_scale, read_frame_data)
    }*/
}

effect_instances_unload :: proc(effect_manager: ^Effect_Manager) {
    for &instance in &effect_manager.instances {
        delete(cast(string) instance.unique_tag)
    }
    defer delete(effect_manager.instances)
}