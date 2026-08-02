package audio

import ma "vendor:miniaudio"

import util "../../util"

import strings "core:strings"
import log "core:log"

Audio_Type :: enum { SOUND, MUSIC, }

Audio_Entry :: struct {
    // For SFX, this is only the source
    // This base should never be played on its own.
    source_audio: ^ma.sound,
    type: Audio_Type,
    state: util.Data_Load_State,
    tag_copy, path: string,

    // Only SFX uses the pool
    // The pool contains instances via ma.sound_init_copy.
    // These are cheaper to play 
    pool: Sound_Pool,
}


// Create the audio entry for the tag.
// Note that this does NOT load the sound in.
@(private)
audio_entry_create :: proc(entry: ^Audio_Entry, tag, path: string, type: Audio_Type) {
    entry.source_audio = new(ma.sound)
    entry.type = type
    entry.state = .UNLOADED
    entry.tag_copy = tag
    entry.path = path

    audio_entry_create_pool(entry)
}

@(private)
audio_entry_destroy :: proc(entry: ^Audio_Entry, tag: string) {
    delete(entry.path)

    if entry.state == .LOADED do audio_unload(tag)

    // Destruction of the pool MUST be done after unloading the entry
    // Unloading an audio entry clears the pool, since we may be unloading audio before destroying it
    // If the pool is destroyed before, it will be trying to clear an 
    audio_entry_destroy_pool(entry)

    free(entry.source_audio)
}

@(private)
audio_entry_get :: proc(tag: string, expected_state: util.Data_Load_State) -> (^Audio_Entry, bool) {
    entry, ok := &global_audio_manager.data_map[tag]

    if !ok {
        log.errorf("Tried to get non-existent audio entry with tag %v.", tag)
        return nil, false
    }

    if entry.state != expected_state {
        log.errorf("Tried to get %v audio with tag %v that was %v.", expected_state, tag, entry.state)
        return nil, false
    }

    return entry, true
}

audio_load :: proc(tag: string) {
    log.infof("Loading audio %v", tag)

    entry, ok := audio_entry_get(tag, .UNLOADED)
    if !ok do return

    flags := sound_get_miniaudio_flags()
    if entry.type == .MUSIC do flags = music_get_miniaudio_flags()
    
    // TODO: check out fences and sound groups
    result := ma.sound_init_from_file(
        &global_audio_manager.audio_engine, strings.unsafe_string_to_cstring(entry.path), flags, nil, nil, entry.source_audio
    )
    
    if result != .SUCCESS {
        log.errorf("Miniaudio error, failed loading audio entry for tag %v: %v", tag, ma.result_description(result))
        entry.state = .FAILED
        return
    }

    entry.state = .LOADED
}

audio_unload :: proc(tag: string) {
    entry, ok := audio_entry_get(tag, .LOADED)
    if !ok do return

    log.infof("Unloading audio data %v", tag)

    audio_entry_clear_pool(entry)

    ma.sound_uninit(entry.source_audio)
    entry.state = .UNLOADED
}