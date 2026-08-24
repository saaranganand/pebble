package ui

import sdl_ttf "vendor:sdl3/ttf"
import mu "vendor:microui"
import sdl "vendor:sdl3"

import font "src:data_load/font"
import color "src:util/color"

import strings "core:strings"
import log "core:log"

Cache_Text :: struct {
    obj: ^sdl_ttf.Text,
    mu_label: bool,
}

Text_Cache :: struct{
    cache: map[string]Cache_Text,
    default_size: f32,
    default_color: color.Default_Palette_Color,
    default_font_tag: string
}

create_text_cache :: proc(def_size: f32, def_color: color.Default_Palette_Color, def_font: string) -> (cache: Text_Cache) {
    cache.cache = make(map[string]Cache_Text)

    cache.default_size = def_size
    cache.default_color = def_color
    cache.default_font_tag = def_font

    return
}

destroy_text_cache :: proc(text_cache: ^Text_Cache) {
    for key, text in text_cache.cache {
        sdl_ttf.DestroyText(text.obj)
    }
    delete(text_cache.cache)
}

Text_Cache_Append :: struct {
    key: string,
    size: Maybe(f32),
    font: Maybe(string),
    color: Maybe(color.Default_Palette_Color),
    mu_label: bool,
}

default_text_cache_append :: proc(
    key: string,
    size: Maybe(f32) = nil, font: Maybe(string) = nil, color: Maybe(color.Default_Palette_Color) = nil,
    mu_label: bool = true,
) -> (cache: Text_Cache_Append){
    return { key, size, font, color, mu_label }
}

append_cache_texts :: proc(
    text_cache: ^Text_Cache, appends: ..Text_Cache_Append
) {
    for append in appends {
        text_size, ts_ok := append.size.(f32)
        if !ts_ok do text_size = text_cache.default_size

        text_font, tf_ok := append.font.(string)
        if !tf_ok do text_font = text_cache.default_font_tag

        text_color, tc_ok := append.color.(color.Default_Palette_Color)
        if !tc_ok do text_color = text_cache.default_color

        append_cache_text(text_cache, append.key, text_size, text_color, text_font, append.mu_label)
    }
}

append_cache_text :: proc(
    text_cache: ^Text_Cache, key: string,
    font_size: f32, font_color: color.Default_Palette_Color, font_tag: string = "",
    mu_label: bool = true,
) {
    font_size := font_size
    if font_size == 0 do font_size = text_cache.default_size

    font_color := font_color
    if font_color == nil do font_color = text_cache.default_color

    font_tag := font_tag
    if font_tag == "" do font_tag = text_cache.default_font_tag

    cstr_text := strings.clone_to_cstring(key)
    defer delete(cstr_text)

    text_cache.cache[key] = { obj = font.font_create_text(font_tag, font_size, cstr_text), mu_label = mu_label }
    
    color.sdl_set_text_color(text_cache.cache[key].obj, font_color)
}

get_cache_text :: proc(text_cache: Text_Cache, key: string) -> (text: Cache_Text, success: bool) {
    return text_cache.cache[key]
}

set_cache_text :: proc(text_cache: Text_Cache, key: string, new_text: string) {
    cstr_text := strings.clone_to_cstring(new_text, context.temp_allocator)
    
    t_cache, success := get_cache_text(text_cache, key)
    if !success do return

    sdl_ttf.SetTextString(t_cache.obj, cstr_text, 0)
}

set_cache_color :: proc(text_cache: Text_Cache, key: string, new_color: sdl.Color) {
    cstr_text := strings.clone_to_cstring(key, context.temp_allocator)

    t_cache, success := get_cache_text(text_cache, key)
    if !success do return

    sdl_ttf.SetTextColor(t_cache.obj, new_color.r, new_color.g, new_color.b, new_color.a)
}

draw_cache_text :: proc(text_cache: Text_Cache, key: string, x, y: f32) {
    t_cache, success := get_cache_text(text_cache, key)
    if !success do return

    sdl_ttf.DrawRendererText(t_cache.obj, x, y)
}