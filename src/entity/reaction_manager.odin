package entity

import sdl "vendor:sdl3"

import handle "../handle"

import log "core:log"
import fmt "core:fmt"

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

    delete(global_reaction_manager.table)
    delete(global_reaction_manager.events)
}

reaction_manager_queue_event :: proc(event_data: Reaction_Event) {
    append(&global_reaction_manager.events, event_data)
}

reaction_manager_update :: proc() {
    for event in global_reaction_manager.events {
        // Get entity
        target_entity, entity_ok := entity_get(event.target)
        if !entity_ok do continue

        log.warnf("checking event as reaction with type %v", event.type)

        // Get reaction key
        reaction_key := reaction_data_tag_create(target_entity.team, target_entity.category)
        defer reaction_data_tag_destroy(reaction_key)

        // Get team,cateogry linked reaction
        reaction_set := global_reaction_manager.table[event.definition_id]
        reaction_data, reaction_data_ok := reaction_set.reaction_data_map[reaction_key]
        if !reaction_data_ok {
            // Get default reaction
            default_reation_data_ok: bool
            reaction_data, default_reation_data_ok = reaction_set.default_reaction_data.(Reaction_Data)
            if !default_reation_data_ok do continue
        }

        // trigger the reaction
        reaction_event_trigger(event, reaction_data, target_entity)
    }

    clear(&global_reaction_manager.events)
}