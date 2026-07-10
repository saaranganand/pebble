package data

import ma "vendor:miniaudio"

import log "core:log"
import fmt "core:fmt"

Sound_Pool :: distinct [dynamic]^ma.sound

@(private)
audio_entry_create_pool :: proc(entry: ^Audio_Entry) {
    log.debugf("Creating sound pool for audio tag %v", entry.tag)
    entry.pool = make(Sound_Pool)
}

@(private)
audio_entry_destroy_pool :: proc(entry: ^Audio_Entry) {
    log.debugf("Destroying sound pool for audio tag %v", entry.tag)
    
    audio_entry_clear_pool(entry)
    delete(entry.pool)
}

audio_entry_clear_pool :: proc(entry: ^Audio_Entry) {
    log.debugf("Clearing pool copies for %v", entry.tag)

    for copy in entry.pool {
        ma.sound_uninit(copy)
        free(copy)
    }

    clear(&entry.pool)
}

@(private)
audio_entry_play_sound_from_pool :: proc(entry: ^Audio_Entry) -> bool {
    for copy in entry.pool {
        // Checks if the sound is finished playing
        if !ma.sound_at_end(copy) do continue

        // Starts the sound 
        result := ma.sound_seek_to_pcm_frame(copy, 0)
        if result != .SUCCESS {
            log.errorf("Miniaudio error when playing sound with tag %v: %v", entry.tag, ma.result_description(result))
            continue
        }

        return true
    }

    return false
}

@(private)
audio_entry_add_to_pool :: proc(entry: ^Audio_Entry) -> (copy: ^ma.sound) {
    copy = new(ma.sound)
    result := ma.sound_init_copy(&global_manager.audio_master.audio_engine, entry.source_audio, sound_get_miniaudio_flags(), nil, copy)

    if result != .SUCCESS {
        free(copy)
        log.errorf("Miniaudio error when adding sound copy to pool with tag %v: %v", entry.tag, ma.result_description(result))
        return
    }

    append(&entry.pool, copy)

    return
}