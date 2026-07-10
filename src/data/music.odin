package data

import ma "vendor:miniaudio"

import log "core:log"
import fmt "core:fmt"

@(private)
music_get_miniaudio_flags :: proc(looping: bool = true) -> (flags: ma.sound_flags) {
    flags = ma.sound_flags{ma.sound_flag.STREAM}
    if looping do flags += {ma.sound_flag.LOOPING}
    return
}

@(private)
music_get_entry :: proc(tag: Data_Tag) -> (^Audio_Entry, bool) {
    entry, ok := audio_entry_get(tag)

    if entry.type != .MUSIC {
        log.errorf("Tried to get non-existent music with tag %v.", tag)
        if entry.type == .SOUND do log.infof("Perhaps you wanted to get the tag as sound instead?")
        return nil, false
    }

    return entry, true
}

music_play :: proc(tag: Data_Tag) {
    entry, success := music_get_entry(tag)
    if !success do return

    ma.sound_start(entry.source_audio)
}

music_pause :: proc(tag: Data_Tag) {
    entry, success := music_get_entry(tag)
    if !success do return

    ma.sound_stop(entry.source_audio)
}

music_reset :: proc(tag: Data_Tag) {
    entry, success := music_get_entry(tag)
    if !success do return

    ma.sound_stop(entry.source_audio)
    ma.sound_seek_to_pcm_frame(entry.source_audio, 0)
}