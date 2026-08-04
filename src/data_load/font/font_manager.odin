package font

import sdl_ttf "vendor:sdl3/ttf"

import primatives "src:sdl_primatives"
import util "src:util"

import filepath "core:path/filepath"
import strings "core:strings"
import log "core:log"

Font_Manager :: struct {
    instances: map[string]Font_Instance,
    engine: ^sdl_ttf.TextEngine,
}

global_font_manager: Font_Manager

font_manager_create :: proc() {
    log.infof("Creating font manager")

    global_font_manager.instances = make(map[string]Font_Instance)
    global_font_manager.engine = sdl_ttf.CreateRendererTextEngine(primatives.global_renderer)

    font_manager_init_data()
}

font_manager_destroy :: proc() {
    log.infof("Destroying font manager")

    for tag, &instance in global_font_manager.instances {
        for size, _ in instance.size_map {
            font_unload(tag, size)
        }

        font_instance_destroy(&instance)
        delete(tag)
    }

    delete(global_font_manager.instances)

    sdl_ttf.DestroyRendererTextEngine(global_font_manager.engine)
}

@(private)
FONT_MASTER_FOLDER :: "assets/"
font_manager_init_data :: proc() {
    log.infof("Initializing font data")

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(FONT_MASTER_FOLDER, ".ttf", &results)

    for path in results {
        tag := strings.clone(filepath.stem(path))
        global_font_manager.instances[tag] = {}
        instance := &global_font_manager.instances[tag]
        
        instance.path = strings.clone(path)
        instance.size_map = make(map[f32]^sdl_ttf.Font)
    }
}

// TODO: support temporary fonts with non-loaded font-sizes
font_manager_get_font :: proc(tag: string, size: f32) -> (font: ^sdl_ttf.Font, success: bool) {
    instance, instance_ok := &global_font_manager.instances[tag]

    if !instance_ok {
        log.errorf("No font with tag %v", tag)
        return nil, false
    }

    if size not_in instance.size_map {
        log.errorf("Tried to get font with tag %v at unloaded size %v", tag, size)
        return nil, false
    }

    return instance.size_map[size], true
}