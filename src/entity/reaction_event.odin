package entity

import sdl "vendor:sdl3"

import assets "../assets"
import color "../color"

import log "core:log"
import fmt "core:fmt"

Reaction_Event_Type :: enum { APPLY, TRIGGER, REMOVE }

Reaction_Event :: struct {
    type: Reaction_Event_Type,
    target: Entity_Handle,
    definition_id: Effect_Definition_ID,
    // Kind of a catch all value.
    // Can be used to display damage amount as floating text,
    // or in an equation to determine screen shake based on amount of damage taken.
    magnitude: f32,
}

reaction_event_trigger :: proc(event: Reaction_Event, data: Reaction_Data, target_entity: ^Entity) {
    switch event.type {
    case .APPLY:
        sound, sound_ok := data.apply_sound.(assets.Data_Tag)
        if sound_ok do assets.sound_play(sound)

        // trigger flash in entity
        // entity_trigger_flash(target_entity, data.flash_duration, data.flash_color)

        // screen shake
        // trigger_screen_shake(data.screen_shake_magnitude)

        // damage number
        // if data.show_damage_number do entity_spawn_damage_indicator(target_entity, event.magnitude)

        // spawn external animation
        // bruh idk data.external_animation_tag
    case .TRIGGER:
        sound, sound_ok := data.trigger_sound.(assets.Data_Tag)
        if sound_ok do assets.sound_play(sound)

        // apply internal animation
        // entity_queue_animation(data.entity_animation_tag)
    case .REMOVE:
        sound, sound_ok := data.remove_sound.(assets.Data_Tag)
        if sound_ok do assets.sound_play(sound)
    }
}