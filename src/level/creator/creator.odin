package level_creator

import mu "vendor:microui"
import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import color "src:util/color"
import util "src:util"

import log "core:log"

mu_ctx: mu.Context

atlas_tex: ^sdl.Texture

creator_init :: proc() {
    util.mu_ctx_init(&mu_ctx, primatives.global_renderer, &atlas_tex)
}

creator_destroy :: proc() {
    sdl.DestroyTexture(atlas_tex)
}

creator_loop :: proc() {
    creator_input()
    creator_update()
    creator_draw()

}

creator_input :: proc() {

}

creator_update :: proc() {
    mu.begin(&mu_ctx)
    if mu.window(&mu_ctx, "Menu", {40, 40, 300, 200}) {
        if .SUBMIT in mu.button(&mu_ctx, "Start") {
            // handle click
        }
    }
    mu.end(&mu_ctx)
}

creator_draw :: proc() {
    color.sdl_set_color(color.Default_Palette_Color.WHITE)
    sdl.RenderClear(primatives.global_renderer)

    util.mu_ctx_draw(&mu_ctx, primatives.global_renderer, atlas_tex)
}