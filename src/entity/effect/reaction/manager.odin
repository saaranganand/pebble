package reaction

import entity "src:entity"
import effect "src:entity/effect"
import util "src:util"

import log "core:log"
import fmt "core:fmt"

@(private)
global_reaction_manager: Reaction_Manager

Reaction_Manager :: struct {
    // 1-1 with effect definition ID
    table: []Reaction_Set,
}

reaction_manager_create :: proc(
    effect_num_definitions: uint, effect_definition_id_map: map[string]uint
) -> (reaction_manager: ^Reaction_Manager) {
    log.infof("Creating reaction manager")

    global_reaction_manager.table = make([]Reaction_Set, effect_num_definitions)

    reaction_manager = &global_reaction_manager

    reaction_manager_load(effect_definition_id_map)

    return
}

reaction_manager_destroy :: proc() {
    log.infof("Destroying reaction manager")
    
    for &set in global_reaction_manager.table {
        reaction_set_destroy(&set)
    } 

    delete(global_reaction_manager.table)
}

EFFECT_REACTION_MASTER_FOLDER :: "assets/"
EFFECT_REACTION_DATA_EXTENSION :: ".effect.reaction.json"
@(private)
reaction_manager_load :: proc(effect_definition_id_map: map[string]uint) {
    log.infof("Loading effect reactions")

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(EFFECT_REACTION_MASTER_FOLDER, EFFECT_REACTION_DATA_EXTENSION, &results)
    
    for path in results {
        set: Reaction_Set
        reaction_set_load(&set, path)

        definition_id := effect_definition_id_map[set.definition_tag]

        global_reaction_manager.table[definition_id] = set
    }
}

reaction_manager_get_data_from_enums :: proc(
    team: entity.Team, category: entity.Category, definition_id: uint
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
        // Get t
        target_entity, entity_ok := entity.entity_get(event.target, event.target_team)
        if !entity_ok do continue

        data, data_ok := reaction_manager_get_data_from_enums(target_entity.team, target_entity.category, event.definition_id)
        if !data_ok do continue

        // trigger the reaction
        reaction_event_trigger(event, data, target_entity)
    }

    clear(&effect_manager.events)
}