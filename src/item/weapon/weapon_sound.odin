package weapon

import audio "src:data_load/audio"

Weapon_Sound_Event :: enum { SELECT, MOVE, CHARGE, FIRE, SHOOT, RELOAD }

weapon_sound_event_to_string :: proc(event: Weapon_Sound_Event) -> string {
    switch event {
    case .SELECT:
        return "select"
	case .MOVE:
        return "move"
	case .CHARGE:
        return "charge"
	case .FIRE:
        return "fire"
    case .SHOOT:
        return "shoot"
	case .RELOAD:
        return "reload"
    }

    return ""
}

Sound_Set :: [Weapon_Sound_Event]Maybe(string)

sound_set_destroy :: proc(set: ^Sound_Set) {
    for event in Weapon_Sound_Event {
        remove_sound, has_remove_sound := set[event].(string)
        if has_remove_sound do delete(cast(string) remove_sound)
    }
}

sound_set_play :: proc(set: ^Sound_Set, play_event: Weapon_Sound_Event) {
    for sound_event in Weapon_Sound_Event {
        if sound_event != play_event do continue
        
        play_sound, has_play_sound := set[play_event].(string)
        if has_play_sound do audio.sound_play(play_sound)
    }
}

sound_stop_loop :: proc(set: ^Sound_Set, play_event: Weapon_Sound_Event) {
    for sound_event in Weapon_Sound_Event {
        if sound_event != play_event do continue
        
        play_sound, has_play_sound := set[play_event].(string)
        if has_play_sound do audio.sound_stop_loop(play_sound)
    }
}

sound_set_play_and_loop :: proc(set: ^Sound_Set, play_event: Weapon_Sound_Event) {
    for sound_event in Weapon_Sound_Event {
        if sound_event != play_event do continue
        
        play_sound, has_play_sound := set[play_event].(string)
        if has_play_sound do audio.sound_play(play_sound, true)
    }
}