package weapon

import yaml "../../libs/odin-yaml"

import assets "../assets"
import yaml_parse "../assets/yaml_parse"

import strings "core:strings"
import log "core:log"

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

Sound_Set :: [Weapon_Sound_Event]Maybe(assets.Data_Tag)

sound_set_load :: proc(set: ^Sound_Set, data_map: yaml.Mapping) {
    for event in Weapon_Sound_Event {
        yaml_label := weapon_sound_event_to_string(event)
        data_tag := yaml_parse.read_value_from_map(data_map, yaml_label, string, default = "")
        if data_tag != "" do set[event] = cast(assets.Data_Tag) strings.clone(data_tag)
    }
}

sound_set_destroy :: proc(set: ^Sound_Set) {
    for event in Weapon_Sound_Event {
        remove_sound, has_remove_sound := set[event].(assets.Data_Tag)
        if has_remove_sound do delete(cast(string) remove_sound)
    }
}

sound_set_play :: proc(set: ^Sound_Set, play_event: Weapon_Sound_Event) {
    for sound_event in Weapon_Sound_Event {
        if sound_event != play_event do continue
        
        play_sound, has_play_sound := set[play_event].(assets.Data_Tag)
        if has_play_sound do assets.sound_play(play_sound)
    }
}

sound_stop_loop :: proc(set: ^Sound_Set, play_event: Weapon_Sound_Event) {
    for sound_event in Weapon_Sound_Event {
        if sound_event != play_event do continue
        
        play_sound, has_play_sound := set[play_event].(assets.Data_Tag)
        if has_play_sound do assets.sound_stop_loop(play_sound)
    }
}

sound_set_play_and_loop :: proc(set: ^Sound_Set, play_event: Weapon_Sound_Event) {
    for sound_event in Weapon_Sound_Event {
        if sound_event != play_event do continue
        
        play_sound, has_play_sound := set[play_event].(assets.Data_Tag)
        if has_play_sound do assets.sound_play(play_sound, true)
    }
}