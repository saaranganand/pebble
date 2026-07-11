package data

import ttf "vendor:sdl3/ttf"
import sdl "vendor:sdl3"

import primatives "../sdl_primatives"

import strings "core:strings"
import log "core:log"
import fmt "core:fmt"

Font_Instance :: struct {
    size_map: map[f32]^ttf.Font,
    path_prefix: string,
}

Font_Master :: struct {
    instances: map[Data_Tag]^Font_Instance,
    engine: ^ttf.TextEngine,
}

@(private)
font_master_create :: proc(master: ^Font_Master) {
    log.infof("Creating font data master")

    master.instances = make(map[Data_Tag]^Font_Instance)
    master.engine = ttf.CreateRendererTextEngine(primatives.global_renderer)
}

@(private)
font_master_destroy :: proc(master: ^Font_Master) {
    for tag, instance in master.instances {
        for size, _ in instance.size_map {
            font_unload(tag, size)
        }

        log.debugf("Destroying size map for font %v", tag)
        delete(instance.size_map)

        delete(cast(string) tag)

        free(instance)
    }

    log.infof("Destroying font data manager")

    delete(master.instances)

    ttf.DestroyRendererTextEngine(master.engine)
}

// TODO: find some way to get multiple basic paths in here, to allow for mods to add their own asset folders to the load path
@(private)
font_master_scrape_data :: proc(master: ^Font_Master) {
    log.infof("Creating data tags for font")

    tags := make([dynamic]string)
    defer delete(tags)
    data_tag_resursive_grab_and_process_precursors("fonts/", "*.ttf", &tags)
    font_master_create_maps_from_scraped_tags(master, tags)
}

@(private)
font_master_create_maps_from_scraped_tags :: proc(master: ^Font_Master, tags: [dynamic]string) {
    for tag in tags {
        defer delete(tag)
        copied_tag := strings.clone(tag)
        
        log.infof("Creating font size map for font %v", copied_tag)
        instance := new(Font_Instance)
        instance.size_map = make(map[f32]^ttf.Font)
        // TODO: use an actual path prefix instead of the default one
        instance.path_prefix = DATA_TAG_DEFAULT_ASSET_FOLDER

        master.instances[cast(Data_Tag) copied_tag] = instance
    }
}

font_load :: proc(tag: Data_Tag, size: f32) {
    instance, ok := global_manager.font_master.instances[tag]

    if !ok {
        log.errorf("Tried to load non-existent font with tag %v.", tag)
        return
    }

    if size in instance.size_map {
        log.errorf("Tried to load font with tag %v at size %v, which has already been loaded.", tag, size)
        return
    }

    log.infof("Loaded font %v with size %v.", tag, size)

    file_path := fmt.caprint(instance.path_prefix, tag, sep = "")
    defer delete(file_path)

    instance.size_map[size] = ttf.OpenFont(file_path, size)
}

font_unload :: proc(tag: Data_Tag, size: f32) {
    instance, ok := global_manager.font_master.instances[tag]

    if !ok {
        log.errorf("Tried to unload non-existent font with tag %v.", tag)
        return
    }

    if size not_in instance.size_map {
        log.errorf("Tried to unload font with tag %v at size %v, which does not exist.", tag, size)
        return
    }

    log.infof("Unloading font %v at size %v", tag, size)
    ttf.CloseFont(instance.size_map[size])
}

// TODO: support temporary fonts with non-loaded font-sizes
font_master_get_font :: proc(tag: Data_Tag, size: f32) -> (font: ^ttf.Font) {
    instance, ok := global_manager.font_master.instances[tag]
    font = nil

    if !ok {
        log.errorf("Tried to get non-existent font with tag %v.", tag)
        return
    }

    if size not_in instance.size_map {
        log.errorf("Tried to get font with tag %v at size %v, which does not exist.", tag, size)
        return
    }

    font = instance.size_map[size]
    return
}

font_create_text :: proc(font_tag: Data_Tag, font_size: f32, text: cstring) -> (text_object: ^ttf.Text) {
    font := font_master_get_font(font_tag, font_size)

    text_object = ttf.CreateText(global_manager.font_master.engine, font, text, 0)

    return
}