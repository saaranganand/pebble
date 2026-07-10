package data

import ma "vendor:miniaudio"

import log "core:log"
import fmt "core:fmt"

Audio_Type :: enum { SOUND, MUSIC, }

// TODO: Add loading state, and start loading audio asynchronously with threads
Audio_Load_State :: enum {
    UNLOADED,
    LOADED,
    FAILED,
}

Audio_Entry :: struct {
    // For SFX, this is only the source
    // This base should never be played on its own.
    source_audio: ^ma.sound,
    type: Audio_Type,
    state: Audio_Load_State,
    tag: Data_Tag,
    path_prefix: string,
    // Only SFX uses the pool
    // The pool contains instances via ma.sound_init_copy.
    // These are cheaper to play 
    pool: Sound_Pool,
}


// Create the audio entry for the tag.
// Note that this does NOT load the sound in.
@(private)
audio_entry_create :: proc(tag: Data_Tag, path_prefix: string, type: Audio_Type = .SOUND) {
    log.infof("Creating audio entry for tag %v", tag)

    entry := new(Audio_Entry)

    entry.source_audio = new(ma.sound)
    entry.type = type
    entry.state = .UNLOADED
    entry.tag = tag
    entry.path_prefix = path_prefix

    audio_entry_create_pool(entry)

    global_manager.audio_master.data_map[tag] = entry
}

@(private)
audio_entry_destroy :: proc(entry: ^Audio_Entry) {
    log.infof("Destroying audio entry for tag %v", entry.tag)

    if entry.state == .LOADED do audio_entry_unload(entry.tag)

    // Destruction of the pool MUST be done after unloading the entry
    // Unloading an audio entry clears the pool, since we may be unloading audio before destroying it
    // If the pool is destroyed before, it will be trying to clear an 
    audio_entry_destroy_pool(entry)

    delete(cast(string) entry.tag)

    free(entry.source_audio)

    free(entry)
}

@(private)
audio_entry_get :: proc(tag: Data_Tag) -> (^Audio_Entry, bool) {
    entry, ok := global_manager.audio_master.data_map[tag]

    if !ok {
        log.errorf("Tried to get non-existent audio entry with tag %v.", tag)
        return nil, false
    }

    if entry.state != .LOADED {
        log.errorf("Tried to get unloaded audio entry with tag %v", tag)
        return nil, false
    }

    return entry, true
}

audio_entry_load :: proc(tag: Data_Tag) {
    log.infof("Loading audio entry for tag %v", tag)

    entry, ok := global_manager.audio_master.data_map[tag]

    if !ok {
        log.errorf("Tried to get non-existent audio entry with tag %v.", tag)
        return
    }

    if entry.state != .UNLOADED {
        // Panics!!
        // This might be lazy to just force a crash,
        // But we, like, really never want to be doing this.
        // Theres no point and bad things are sure to follow.
        log.panicf("Trying to load audio entry of tag %v that is either already loaded, or failed to load.", entry.tag)
    }

    file_path := fmt.caprint(entry.path_prefix, entry.tag, sep = "")
    defer delete(file_path)

    flags := sound_get_miniaudio_flags()
    if entry.type == .MUSIC do flags = music_get_miniaudio_flags()
    // TODO: check out fences and sound groups
    result := ma.sound_init_from_file(&global_manager.audio_master.audio_engine, file_path, flags, nil, nil, entry.source_audio)
    
    if result != .SUCCESS {
        log.errorf("Miniaudio error, failed loading audio entry for tag %v: %v", entry.tag, ma.result_description(result))
        entry.state = .FAILED
        return
    }

    entry.state = .LOADED
}

audio_entry_unload :: proc(tag: Data_Tag) {
    entry, ok := audio_entry_get(tag)

    log.infof("Unloading audio entry for tag %v", entry.tag)

    audio_entry_clear_pool(entry)

    ma.sound_uninit(entry.source_audio)
    entry.state = .UNLOADED
}