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
audio_create :: proc(master: ^Audio_Master) {
    log.infof("Creating audio data manager")

    // TODO: create an engine_config item to pass through for extra options
    log.infof("Creating microaudio engine")
    result := ma.engine_init(nil, &master.audio_engine)
    if result != .SUCCESS {
        log.panicf("Miniaudio error: %v", ma.result_description(result))
    }

    master.data_map = make(map[Data_Tag]^Audio_Entry)
}

@(private)
audio_destroy :: proc(master: ^Audio_Master) {
    log.infof("Destroying audio data manager")

    for tag, entry in master.data_map {
        audio_entry_destroy(entry)
    }

    delete(master.data_map)

    log.infof("Destroying microaudio engine")
    ma.engine_uninit(&master.audio_engine)
}


DEFAULT_ASSET_FOLDER :: "assets/"

// TODO: find some way to get multiple basic paths in here, to allow for mods to add their own asset folders to the load path
@(private)
audio_scrape_audio_entries :: proc() {
    log.infof("Creating data tags for audio")

    flags := sdl.GlobFlags{ .CASEINSENSITIVE }

    tags := make([dynamic]string)
    defer delete(tags)

    process_tags :: proc(outer_strings: [^][^]u8, path: string, num_strings: i32, tags: ^[dynamic]string) {
        inner_strings := outer_strings[:num_strings]
        for data in inner_strings {
            cstr := cstring(data)
            // This isnt a clone, but a view into the raw cstring data
            str := string(cstr)

            // This IS a clone, aka allocates new_tag, which means it must be freed eventually.
            new_tag := fmt.aprint(path, str, sep = "")

            append(tags, new_tag)
        }
    }

    // Grab all matching files
    music_path := fmt.caprint(DEFAULT_ASSET_FOLDER, "music/", sep = "")
    defer delete(music_path)
    num_music_oggs: i32 = 0
    music_oggs := sdl.GlobDirectory(music_path, "*.ogg", flags, &num_music_oggs)
    // Process them into correctly formatted tags (example: music/subfolder/track_name.ogg)
    process_tags(music_oggs, "music/", num_music_oggs, &tags)

    // Clone the tags and create audio entries from them
    for tag in tags {
        clone_tag := strings.clone(tag)
        audio_entry_create(cast(Data_Tag) clone_tag, DEFAULT_ASSET_FOLDER, .MUSIC)
        delete(tag)
    }

    sdl.free(music_oggs)

    // reset tag array to begin again with sfx
    clear(&tags)

    // Grab all matching files
    sound_path := fmt.caprint(DEFAULT_ASSET_FOLDER, "sounds/", sep = "")
    defer delete(sound_path)
    num_sound_wavs: i32 = 0
    sound_wavs := sdl.GlobDirectory(sound_path, "*.wav", flags, &num_sound_wavs)
    // Process them into correctly formatted tags (example: sounds/subfolder/explosion.wav)
    process_tags(sound_wavs, "sounds/", num_sound_wavs, &tags)

    // Clone the tags and create audio entries from them
    for tag in tags {
        copied_tag := strings.clone(tag)
        audio_entry_create(cast(Data_Tag) copied_tag, DEFAULT_ASSET_FOLDER, .SOUND)
        delete(tag)
    }

    sdl.free(sound_wavs)
}