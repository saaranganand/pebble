package reaction

import color "src:util/color"
import entity "src:entity"

import json "core:encoding/json"
import os "core:os"
import log "core:log"
import fmt "core:fmt"

// For example, if an entity with an active burn effect should draw an animation of flames around them,
// said animation will be accessed from this data source.
REACTION_ANIMATION_SOURCE: string: "reactions.animation"

reaction_data_tag_create :: proc(team: entity.Team, category: entity.Category) -> (tag: string) {
    return fmt.aprint(team, category, sep = ",")
}

reaction_data_tag_destroy :: proc(tag: string) {
    delete(tag)
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
    apply_sound:  Maybe(string),
    trigger_sound:   Maybe(string),
    remove_sound: Maybe(string),

    flash_color:    Maybe(color.Default_Palette_Color),
    flash_duration: f32,

    entity_animation_tag:   Maybe(string),
    external_animation_tag: Maybe(string),

    screen_shake_magnitude: f32,

    show_damage_number: bool,
    show_damage_number_color: Maybe(color.Default_Palette_Color)
}

reaction_data_empty_struct :: proc() -> (data: Reaction_Data) {
    data.apply_sound = nil
    data.trigger_sound = nil
    data.remove_sound = nil

    data.flash_color = nil
    data.flash_duration = 0.0

    data.entity_animation_tag = nil
    data.external_animation_tag = nil

    data.screen_shake_magnitude = 0.0

    data.show_damage_number = false
    data.show_damage_number_color = nil

    return
}

reaction_data_destroy :: proc(data: ^Reaction_Data) {
    apply_sound, has_apply_sound := data.apply_sound.(string)
    if has_apply_sound do delete(cast(string) apply_sound)

    trigger_sound, has_trigger_sound := data.trigger_sound.(string)
    if has_trigger_sound do delete(cast(string) trigger_sound)

    remove_sound, has_remove_sound := data.remove_sound.(string)
    if has_remove_sound do delete(cast(string) remove_sound)

    entity_animation_tag, has_entity_animation_tag := data.entity_animation_tag.(string)
    if has_entity_animation_tag do delete(cast(string) entity_animation_tag)

    external_animation_tag, has_external_animation_tag := data.external_animation_tag.(string)
    if has_external_animation_tag do delete(cast(string) external_animation_tag)
}
