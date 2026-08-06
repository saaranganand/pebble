package level_creator

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import color "src:util/color"

import log "core:log"
import fmt "core:fmt"
import os "core:os"

Creator :: struct {}

creator: Creator

creator_init :: proc() {
    //ui_init()
}

creator_destroy :: proc() {
    //ui_destroy()
}

creator_loop :: proc() {
    creator_input()
    creator_update()
    creator_draw()
}

creator_input :: proc() {

}

creator_update :: proc() {
    //ui_update()
}

creator_draw :: proc() {
    color.sdl_set_color(color.Default_Palette_Color.WHITE)
    sdl.RenderClear(primatives.global_renderer)

    //ui_draw()
}