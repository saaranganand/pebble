package font

import sdl_ttf "vendor:sdl3/ttf"

import strings "core:strings"
import log "core:log"

Font_Instance :: struct {
    size_map: map[f32]^sdl_ttf.Font,
    path: string,
}

font_instance_destroy :: proc(instance: ^Font_Instance) {
    delete(instance.size_map)
    delete(instance.path)
}

@(private)
get_font_instance :: proc(tag: string) -> (instance: ^Font_Instance, success: bool) {
    instance, success = &global_font_manager.instances[tag]

    if !success {
        log.errorf("No font with tag %v", tag)
        return nil, false
    }

    return
}

font_load :: proc(tag: string, size: f32) {
    instance, success := get_font_instance(tag)
    if !success do return

    log.infof("Loading font %v with size %v.", tag, size)

    instance.size_map[size] = sdl_ttf.OpenFont(strings.unsafe_string_to_cstring(instance.path), size)
}

font_unload :: proc(tag: string, size: f32) {
    instance, success := get_font_instance(tag)
    if !success do return

    if size not_in instance.size_map {
        log.errorf("Tried unloading font %v at unloaded size %v", tag, size)
        return
    }

    log.infof("Unloading font %v at size %v", tag, size)
    sdl_ttf.CloseFont(instance.size_map[size])
}

font_create_text :: proc(font_tag: string, font_size: f32, text: cstring) -> (text_object: ^sdl_ttf.Text) {
    font, success := font_manager_get_font(font_tag, font_size)
    if !success do return

    text_object = sdl_ttf.CreateText(global_font_manager.engine, font, text, 0)

    return
}