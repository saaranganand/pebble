package entity

import sdl "vendor:sdl3"

import handle "../handle"

import log "core:log"
import fmt "core:fmt"

// Reaction data contains a collection of data related to possible reaction outcomes.
// Some effects might play a sound on their callback, while some may display an animation while active.
// Some may do both.
// Reaction sets are children to effect definitions, and there is the potential for one for each combination of entity team and category.
// For example: a burn effect show a burning animation around the entity, and might play a sound every time it ticks.
// However, we only want to play the sound for allied members in combat: not allied NPCs/bullets, and not enemies.
// So, the allied player reaction set would contain a sound_on_callback, and a external_animation_tag,
// while the default reaction set would contain just an external_animation_tag.
Reaction_Data :: struct {
    sound_on_apply:   Maybe(string),
    sound_on_tick:    Maybe(string),
    sound_on_remove:  Maybe(string),

    flash_color:      Maybe([4]f32),
    flash_duration:   f32,

    attached_anim_tag: Maybe(string), // starts on Applied, stops on Removed

    shake_amount:     f32,            // 0 = none
}

Reaction_Data_Tag :: distinct string

reaction_data_tag_create :: proc(team: Entity_Team, category: Entity_Category) -> (tag: Reaction_Data_Tag) {
    return cast(Reaction_Data_Tag) fmt.aprint(team, category, sep = "")
}

reaction_data_tag_destroy :: proc(tag: Reaction_Data_Tag) {
    delete(cast(string) tag)
}

// All reaction sets have at least a default data object.
// For each necessary combination of team and category, a tag is created through the enum names in a comma seperated string
Reaction_Set :: struct {
    default_reaction_data: Reaction_Data,
    reaction_data_map: map[Reaction_Data_Tag]Reaction_Data,
}

@(private)
global_reaction_manager: Reaction_Manager

Reaction_Manager :: struct {
    // 1-1 with effect definition ID
    table: []Reaction_Set,
}

reaction_manager_create :: proc() -> (reaction_manager: ^Reaction_Manager) {
    log.infof("Creating reaction manager")
    global_reaction_manager.table = make([]Reaction_Set, global_effect_manager.unique_definition_ids)

    reaction_manager = &global_reaction_manager
    return
}