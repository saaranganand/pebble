package audio

import ma "vendor:miniaudio"

import util "src:util"

import filepath "core:path/filepath"
import strings "core:strings"
import log "core:log"

Engine_Type :: enum { GLOBAL, GAME, UI }

// TODO: add split sliders for sfx volume, music volume,
// maybe even seperate sfx volume sliders
// will rquire an extra enum for each audio entry at least
Audio_Manager :: struct {
    engines: [Engine_Type]ma.engine,

    data_map: map[string]Audio_Entry,
}

global_audio_manager: Audio_Manager

audio_manager_create :: proc() {
    log.infof("Creating audio manager")

    // TODO: create an engine_config item to pass through for extra options
    for &engine in global_audio_manager.engines {
        result := ma.engine_init(nil, &engine)
        if result != .SUCCESS do log.panicf("Failed to init Miniaudio: %v", ma.result_description(result))

        ma.engine_set_volume(&engine, .50)
    }    

    global_audio_manager.data_map = make(map[string]Audio_Entry)

    audio_manager_init_data()
}

audio_manager_destroy :: proc() {
    log.infof("Destroying audio manager")

    for tag, &entry in global_audio_manager.data_map {
        audio_entry_destroy(&entry, tag)
        delete(tag)
    }

    delete(global_audio_manager.data_map)

    for &engine in global_audio_manager.engines {
        ma.engine_uninit(&engine)
    }    
}

@(private)
AUDIO_MASTER_FOLDER :: "assets/"
audio_manager_init_data :: proc() {
    log.infof("Initializing audio data")

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(AUDIO_MASTER_FOLDER, ".wav", &results)
    util.scrape_files(AUDIO_MASTER_FOLDER, ".ogg", &results)

    

    for path in results {
        // In this case, include the ext with volume name rather than stem.
        // .wav and .ogg differentiate between audio and music,
        // and allow us to store both simeultaneously
        tag := strings.clone(filepath.base(path))
        global_audio_manager.data_map[tag] = {}
        entry := &global_audio_manager.data_map[tag]

        type := Audio_Type.SOUND
        if filepath.ext(path) == ".ogg" do type = .MUSIC

        audio_entry_create(entry, tag, strings.clone(path), type)
    }
}

pause_audio :: proc(engine_type: Engine_Type) {
    ma.engine_stop(&global_audio_manager.engines[engine_type])
}

resume_audio :: proc(engine_type: Engine_Type) {
    ma.engine_start(&global_audio_manager.engines[engine_type])
}