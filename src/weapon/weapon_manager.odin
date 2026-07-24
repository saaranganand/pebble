package weapon

import sdl "vendor:sdl3"

import yaml_parse "../assets/yaml_parse"
import assets "../assets"
import handle "../handle"

import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import fmt "core:fmt"
import mem "core:mem"

@(private)
global_weapon_manager: Weapon_Manager

Weapon_Manager :: struct {
    weapons: []Weapon_Definition,
    num_weapons: Weapon_Definition_ID,
    definition_tag_to_id: map[Weapon_Definition_Tag]Weapon_Definition_ID,
    unique_definition_ids: Weapon_Definition_ID,
}

weapon_manager_create :: proc() -> ^Weapon_Manager {
    log.infof("Created weapon manager")
    return &global_weapon_manager
}

weapon_manager_destroy :: proc() {
    for &weapon in global_weapon_manager.weapons {
        weapon_definition_unload(&weapon)
    }
    delete(global_weapon_manager.weapons)
    delete(global_weapon_manager.definition_tag_to_id)

    log.infof("Destroyed weapon manager")
}

weapon_manager_num_definitions :: proc() -> Weapon_Definition_ID {
    return global_weapon_manager.unique_definition_ids
}

weapon_manager_get_definition_id :: proc(definition_tag: Weapon_Definition_Tag) -> (id: Weapon_Definition_ID, ok: bool) {
    id, ok = global_weapon_manager.definition_tag_to_id[definition_tag]
    return
}

weapon_manager_get_definition :: proc(definition_tag: Weapon_Definition_Tag) -> ^Weapon_Definition {
    definition_ID, def_ok := global_weapon_manager.definition_tag_to_id[definition_tag]
    if !def_ok {
        log.errorf("Attempted to get weapon definition ID from tag %v that does not have an ID mapping", definition_tag)
        return nil
    }

    return &global_weapon_manager.weapons[definition_ID]
}

weapon_manager_load :: proc() {
    log.infof("Loading weapon manager")

    global_weapon_manager.definition_tag_to_id = make(map[Weapon_Definition_Tag]Weapon_Definition_ID)

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

    pre_path := "data/weapon/"
    assets.data_tag_resursive_grab_and_process_precursors(pre_path, "*.yaml", &file_paths, "")

    num_definitions := len(file_paths)
    global_weapon_manager.unique_definition_ids = cast(u32) num_definitions
    global_weapon_manager.weapons = make([]Weapon_Definition, num_definitions)
    definition_id_counter: Weapon_Definition_ID = 0

    for path in file_paths {
        weapon_definition_load(pre_path, path, &definition_id_counter, arena_alloc)
        delete(path)
    }
}