package ui

import sdl_ttf "vendor:sdl3/ttf"
import mu "vendor:microui"
import sdl "vendor:sdl3"

import font "src:data_load/font"
import color "src:util/color"

import strings "core:strings"
import log "core:log"

MU_Text_Cache :: struct{
    cache: map[string]^sdl_ttf.Text,
    default_size: f32,
    default_color: color.Default_Palette_Color,
    default_font_tag: string
}

create_text_cache :: proc(def_size: f32, def_color: color.Default_Palette_Color, def_font: string) -> (cache: MU_Text_Cache) {
    cache.cache = make(map[string]^sdl_ttf.Text)

    cache.default_size = def_size
    cache.default_color = def_color
    cache.default_font_tag = def_font

    return
}

destroy_text_cache :: proc(text_cache: ^MU_Text_Cache) {
    for key, text in text_cache.cache {
        sdl_ttf.DestroyText(text)
    }
    delete(text_cache.cache)
}

append_text_cache :: proc(
    text_cache: ^MU_Text_Cache, key: string,
    font_size: f32 = 0, font_color: Maybe(color.Default_Palette_Color) = nil, font_tag: string = ""
) {
    font_size := font_size
    if font_size == 0 do font_size = text_cache.default_size

    font_color := font_color
    if font_color == nil do font_color = text_cache.default_color

    font_tag := font_tag
    if font_tag == "" do font_tag = text_cache.default_font_tag

    cstr_text := strings.clone_to_cstring(key)
    defer delete(cstr_text)

    text_cache.cache[key] = font.font_create_text(font_tag, font_size, cstr_text)
    
    col, _ := font_color.(color.Default_Palette_Color)
    color.sdl_set_text_color(text_cache.cache[key], col)
}

get_cache_text :: proc(text_cache: MU_Text_Cache, key: string) -> (text: ^sdl_ttf.Text, success: bool) {
    return text_cache.cache[key]
}

set_cache_text :: proc(text_cache: MU_Text_Cache, key: string, new_text: string) {
    cstr_text := strings.clone_to_cstring(new_text)
    defer delete(cstr_text)

    sdl_ttf.SetTextString(text_cache.cache[key], cstr_text, 0)
}

set_cache_color :: proc(text_cache: MU_Text_Cache, key: string, new_color: sdl.Color) {
    cstr_text := strings.clone_to_cstring(key)
    defer delete(cstr_text)

    sdl_ttf.SetTextColor(text_cache.cache[key], new_color.r, new_color.g, new_color.b, new_color.a)
}

draw_cache_text :: proc(text_cache: MU_Text_Cache, key: string, x, y: f32) {
    text_obj, success := text_cache.cache[key]
    sdl_ttf.DrawRendererText(text_obj, x, y)
}