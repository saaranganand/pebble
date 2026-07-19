package entity

import sdl "vendor:sdl3"

import assets "../assets"
import color "../color"

import log "core:log"
import fmt "core:fmt"

// For example, if an entity with an active burn effect should draw an animation of flames around them,
// said animation will be accessed from this data source.
REACTION_ANIMATION_SOURCE: assets.Data_Tag: "animations/reactions.yaml"


Reaction_Data_Tag :: distinct string

reaction_data_tag_create :: proc(team: Entity_Team, category: Entity_Category) -> (tag: Reaction_Data_Tag) {
    return cast(Reaction_Data_Tag) fmt.aprint(team, category, sep = "")
}

reaction_data_tag_destroy :: proc(tag: Reaction_Data_Tag) {
    delete(cast(string) tag)
}

// Reaction data contains a collection of data related to possible reaction outcomes.
// Some effects might play a sound on their trigger, while some may display an animation while active.
// Some may do both.
// Reaction sets are children to effect definitions, and there is the potential for one for each combination of entity team and category.
// For example: a burn effect show a burning animation around the entity, and might play a sound every time it ticks.
// However, we only want to play the sound for allied members in combat: not allied NPCs/bullets, and not enemies.
// So, the allied player reaction set would contain a sound_on_trigger, and a external_animation_tag,
// while the default reaction set would contain just an external_animation_tag.
Reaction_Data :: struct {
    apply_sound:  Maybe(assets.Data_Tag),
    trigger_sound:   Maybe(assets.Data_Tag),
    remove_sound: Maybe(assets.Data_Tag),

    flash_color:    Maybe(color.Default_Palette_Color),
    flash_duration: f32,

    entity_animation_tag:   Maybe(assets.Animation_Tag),
    external_animation_tag: Maybe(assets.Animation_Tag),

    screen_shake_magnitude: f32,

    show_damage_number: bool,
}

// All reaction sets have at least a default data object.
// For each necessary combination of team and category, a tag is created through the enum names in a comma seperated string
Reaction_Set :: struct {
    default_reaction_data: Maybe(Reaction_Data),
    reaction_data_map: map[Reaction_Data_Tag]Reaction_Data,
}

reaction_set_create :: proc(set: ^Reaction_Set, default_data: Maybe(Reaction_Data) = nil) {
    set.default_reaction_data = default_data

    set.reaction_data_map = make(map[Reaction_Data_Tag]Reaction_Data)
}

reaction_set_destroy :: proc(set: ^Reaction_Set) {
    for key, _ in set.reaction_data_map {
        delete(cast(string) key)
    }
    delete(set.reaction_data_map)
}

// TODO
reaction_set_load :: proc(set: ^Reaction_Set) {
    // grab every yaml file in assets/data/effect/reactions

    // parse out every listed default and team,category reaction for each definition, if there is any
    
    // create the reaction datas and assign them to the map with a created key
}