package reaction

import audio "src:data_load/audio"
import entity "src:entity"
import effect "src:entity/effect"

reaction_event_trigger :: proc(event: effect.Effect_Event, data: Reaction_Data, target_entity: ^entity.Entity) {
    switch event.type {
    case .APPLY:
        sound, sound_ok := data.apply_sound.(string)
        if sound_ok do audio.sound_play(sound)

        // trigger flash in entity
        // entity_trigger_flash(target_entity, data.flash_duration, data.flash_color)

        // screen shake
        // trigger_screen_shake(data.screen_shake_magnitude)

        // damage number
        // if data.show_damage_number do entity_spawn_damage_indicator(target_entity, event.magnitude)

        // spawn external animation
        // bruh idk data.external_animation_tag
    case .TRIGGER:
        
        sound, sound_ok := data.trigger_sound.(string)
        if sound_ok do audio.sound_play(sound)

        // apply internal animation
        // entity_queue_animation(data.entity_animation_tag)
    case .REMOVE:
        sound, sound_ok := data.remove_sound.(string)
        if sound_ok do audio.sound_play(sound)
    }
}