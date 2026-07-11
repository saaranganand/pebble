package data

import sdl "vendor:sdl3"
import ma "vendor:miniaudio"

import strings "core:strings"
import log "core:log"
import fmt "core:fmt"

Audio_Master :: struct {
    audio_engine: ma.engine,
    data_map: map[Data_Tag]^Audio_Entry,
}

@(private)
audio_master_create :: proc(master: ^Audio_Master) {
    log.infof("Creating audio data master")

    // TODO: create an engine_config item to pass through for extra options
    log.infof("Creating microaudio engine")
    result := ma.engine_init(nil, &master.audio_engine)
    if result != .SUCCESS {
        log.panicf("Miniaudio error: %v", ma.result_description(result))
    }

    master.data_map = make(map[Data_Tag]^Audio_Entry)
}

@(private)
audio_master_destroy :: proc(master: ^Audio_Master) {
    log.infof("Destroying audio data master")

    for tag, entry in master.data_map {
        audio_entry_destroy(entry)
    }

    delete(master.data_map)

    log.infof("Destroying microaudio engine")
    ma.engine_uninit(&master.audio_engine)
}


DATA_TAG_DEFAULT_ASSET_FOLDER :: "assets/"

// TODO: find some way to get multiple basic paths in here, to allow for mods to add their own asset folders to the load path
@(private)
audio_master_scrape_data :: proc() {
    log.infof("Creating data tags for audio")

    music_tags := make([dynamic]string)
    defer delete(music_tags)
    data_tag_resursive_grab_and_process_precursors("music/", "*.ogg", &music_tags)
    audio_create_entries_from_scraped_tags(music_tags, .MUSIC)

    sound_tags := make([dynamic]string)
    defer delete(sound_tags)
    data_tag_resursive_grab_and_process_precursors("sounds/", "*.wav", &sound_tags)
    audio_create_entries_from_scraped_tags(sound_tags, .SOUND)
}

@(private)
audio_create_entries_from_scraped_tags :: proc(tags: [dynamic]string, type: Audio_Type) {
    for tag in tags {
        copied_tag := strings.clone(tag)
        // TODO: pass an actual path prefix instead of the default one
        audio_entry_create(cast(Data_Tag) copied_tag, DATA_TAG_DEFAULT_ASSET_FOLDER, type)
        delete(tag)
    }
}