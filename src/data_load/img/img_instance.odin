package img

import sdl_img "vendor:sdl3/image"
import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import util "src:util"

import strings "core:strings"
import math "core:math"
import log "core:log"

Img_Instance :: struct {
    texture: ^sdl.Texture,
    path: string,
    state: util.Data_Load_State,
}

@(private)
img_get_instance :: proc(tag: string, expected_state: util.Data_Load_State) -> (instance: ^Img_Instance, ok: bool) {
    instance, ok = &global_img_manager[tag]

    if !ok {
        log.errorf("Tried to get non-existent img with tag %v.", tag)
        return nil, false
    }

    if instance.state != expected_state {
        log.errorf("Tried to get %v img with tag %v that was %v.", expected_state, tag, instance.state)
        return nil, false
    }

    return
}

img_load :: proc(tag: string) {
    instance, ok := img_get_instance(tag, .UNLOADED)
    if !ok do return

    log.infof("Loading texture %v", tag)

    cstr_path := strings.clone_to_cstring(instance.path)
    defer delete(cstr_path)
    instance.texture = sdl_img.LoadTexture(primatives.global_renderer, cstr_path)
    
    sdl.SetTextureBlendMode(instance.texture, {.BLEND})
    sdl.SetTextureScaleMode(instance.texture, .PIXELART)

    instance.state = .LOADED
}

img_unload :: proc(tag: string) {
    instance, ok := img_get_instance(tag, .LOADED)
    if !ok do return

    log.infof("Destroying texture %v", instance.path)

    sdl.DestroyTexture(instance.texture)
    instance.state = .UNLOADED
}

img_draw :: proc(
    img_tag: string, dest: ^sdl.FRect, src: ^sdl.FRect = nil, angle: f64 = 0, flip_mode: sdl.FlipMode = .NONE, center: ^sdl.FPoint = nil
) {
    instance, ok := img_get_instance(img_tag, .LOADED)
    if !ok do return

    sdl.RenderTextureRotated(primatives.global_renderer, instance.texture, src, dest, angle * math.DEG_PER_RAD, center, flip_mode)
}