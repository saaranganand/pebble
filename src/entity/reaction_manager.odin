package entity

import sdl "vendor:sdl3"

import assets "../assets"

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
    events: [dynamic]Reaction_Event,
}

reaction_manager_create :: proc() -> (reaction_manager: ^Reaction_Manager) {
    log.infof("Creating reaction manager")

    global_reaction_manager.table = make([]Reaction_Set, global_effect_manager.unique_definition_ids)
    global_reaction_manager.events = make([dynamic]Reaction_Event)

    reaction_manager = &global_reaction_manager

    return
}

reaction_manager_destroy :: proc() {
    log.infof("Destroying reaction manager")
    
    for &set in global_reaction_manager.table {
        reaction_set_destroy(&set)
    } 

    delete(global_reaction_manager.table)
    delete(global_reaction_manager.events)
}

reaction_manager_load :: proc() {
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
    assets.data_tag_resursive_grab_and_process_precursors(pre_path, "*.yaml", &file_paths)

    for path in file_paths {
        reaction_data_load(pre_path, path, arena_alloc)
        delete(path)
    }
}

reaction_manager_queue_event :: proc(event_data: Reaction_Event) {
    append(&global_reaction_manager.events, event_data)
}

reaction_manager_get_data_from_enums :: proc(
    team: Entity_Team, category: Entity_Category, definition_id: Effect_Definition_ID
) -> (data: Reaction_Data, ok: bool) {
    reaction_set := global_reaction_manager.table[definition_id]

    // First, try specific combo
    base_key := reaction_data_tag_create(team, category)
    defer reaction_data_tag_destroy(base_key)

    data, ok = reaction_set.reaction_data_map[base_key]
    if ok do return data, true

    // Then, try matching team with any category
    team_key := cast(Reaction_Data_Tag) fmt.aprint(team, "ANY", sep = ",")
    defer delete(cast(string) team_key)

    data, ok = reaction_set.reaction_data_map[team_key]
    if ok do return data, true

    // Then, category with any team
    category_key := cast(Reaction_Data_Tag) fmt.aprint("ANY", category, sep = ",")
    defer delete(cast(string) category_key)

    data, ok = reaction_set.reaction_data_map[category_key]
    if ok do return data, true

    // Finally, try default
    data, ok = reaction_set.default_reaction_data.(Reaction_Data)
    if ok do return data, true

    return {}, false
}

reaction_manager_update :: proc() {
    for event in global_reaction_manager.events {
        // Get entity
        target_entity, entity_ok := entity_get(event.target)
        if !entity_ok do continue

        data, data_ok := reaction_manager_get_data_from_enums(target_entity.team, target_entity.category, event.definition_id)
        if !data_ok do continue

        // trigger the reaction
        reaction_event_trigger(event, data, target_entity)
    }

    clear(&global_reaction_manager.events)
}