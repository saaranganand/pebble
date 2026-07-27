package assets

import ma "vendor:miniaudio"

import log "core:log"
import fmt "core:fmt"

// TODO: look more into miniaudio flags
@(private)
sound_get_miniaudio_flags :: proc() -> (flags: ma.sound_flags) {
    flags = ma.sound_flags{ma.sound_flag.DECODE}
    return
}

@(private)
sound_get_entry :: proc(tag: Data_Tag) -> (^Audio_Entry, bool) {
    entry, ok := audio_entry_get(tag)

    if entry.type != .SOUND {
        log.errorf("Tried to get non-existent sound with tag %v.", tag)
        if entry.type == .MUSIC do log.infof("Perhaps you wanted to get the tag as music instead?")
        return nil, false
    }

    return entry, true
}

@(private)
sound_play_from_audio_entry :: proc(entry: ^Audio_Entry, loop: bool = false) {
    for copy in entry.pool {
        if ma.sound_at_end(copy) {
            result := ma.sound_seek_to_pcm_frame(copy, 0)
            if result != .SUCCESS {
                log.errorf("Miniaudio error when playing sound with tag %v: %v", entry.tag, ma.result_description(result))
            }
            ma.sound_set_looping(copy, cast(b32) loop)
            ma.sound_start(copy)
            return
        }
    }

    // First, try to play the sound using the existing copies weve made
    if audio_entry_play_sound_from_pool(entry) do return

    // If that is unsuccessful, add a new entry to the pool
    copy := audio_entry_add_to_pool(entry)
    // And play it
    ma.sound_set_looping(copy, cast(b32) loop)
    ma.sound_start(copy)
}

// TODO: allow setting and removing loop functionality for SFX.
// This is useful for things like charging sounds that need to play continuously for a variable amount of time
sound_play :: proc(tag: Data_Tag, loop: bool = false) {
    entry, success := sound_get_entry(tag)
    if !success do return

    sound_play_from_audio_entry(entry, loop)
}

sound_stop_loop :: proc(tag: Data_Tag) {
    entry, success := sound_get_entry(tag)
    if !success do return

    for copy in entry.pool {
        if ma.sound_is_looping(copy) {
            ma.sound_set_looping(copy, cast(b32) false)
            return
        }
    }
}