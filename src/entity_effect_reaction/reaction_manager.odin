package reaction

import sdl "vendor:sdl3"

import assets "../assets"
import handle "../handle"
import entity "../entity"
import effect "../entity_effect"

import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import fmt "core:fmt"
import mem "core:mem"

@(private)
global_reaction_manager: Reaction_Manager

Reaction_Manager :: struct {
    // 1-1 with effect definition ID
    table: []Reaction_Set,
}

reaction_manager_create :: proc(unique_effect_definition_ids: u32) -> (reaction_manager: ^Reaction_Manager) {
    log.infof("Creating reaction manager")

    global_reaction_manager.table = make([]Reaction_Set, unique_effect_definition_ids)

    reaction_manager = &global_reaction_manager

    return
}

reaction_manager_destroy :: proc() {
    log.infof("Destroying reaction manager")
    
    for &set in global_reaction_manager.table {
        reaction_set_destroy(&set)
    } 

    delete(global_reaction_manager.table)
}

reaction_manager_load :: proc(effect_definition_tag_to_id: effect.Effect_Definition_Tag_To_ID_Map) {
    log.infof("Loading effect reaction manager")

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

    pre_path := "data/effect/reactions/"
    assets.data_tag_resursive_grab_and_process_precursors(pre_path, "*.yaml", &file_paths, "")

    for path in file_paths {
        reaction_data_load(pre_path, path, effect_definition_tag_to_id, arena_alloc)
        delete(path)
    }
}

reaction_manager_get_data_from_enums :: proc(
    team: entity.Team, category: entity.Category, definition_id: effect.Effect_Definition_ID
) -> (data: Reaction_Data, ok: bool) {
    reaction_set := global_reaction_manager.table[definition_id]

    // First, try specific combo
    base_key := reaction_data_tag_create(team, category)
    defer reaction_data_tag_destroy(base_key)

    data, ok = reaction_set.reaction_data_map[base_key]
    if ok do return data, true

    // Then, try matching team with any category
    team_key := fmt.aprint(team, "ANY", sep = ",")
    defer delete(team_key)

    data, ok = reaction_set.reaction_data_map[team_key]
    if ok do return data, true

    // Then, category with any team
    category_key := fmt.aprint("ANY", category, sep = ",")
    defer delete(category_key)

    data, ok = reaction_set.reaction_data_map[category_key]
    if ok do return data, true

    // Finally, try default
    data, ok = reaction_set.default_reaction_data.(Reaction_Data)
    if ok do return data, true

    return {}, false
}

reaction_manager_update :: proc(effect_manager: ^effect.Effect_Manager) {
    for event in effect_manager.events {
        // Get entity
        target_entity, entity_ok := entity.entity_get(event.target)
        if !entity_ok do continue

        data, data_ok := reaction_manager_get_data_from_enums(target_entity.team, target_entity.category, event.definition_id)
        if !data_ok do continue

        // trigger the reaction
        reaction_event_trigger(event, data, target_entity)
    }

    clear(&effect_manager.events)
}