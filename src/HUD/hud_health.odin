package HUD

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import primatives "../sdl_primatives"
import color "../color"
import entity "../entity"
import assets "../assets"
import player "../player"
import input "../input"
import weapon "../weapon"

draw_hud_health_bar :: proc(health, max_health: f32) {
    HEALTH_BAR_WIDTH :: 300
    HEALTH_BAR_HEIGHT :: 20

    bar_rect :=    sdl.FRect{10, 10, HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT}
    color.sdl_set_color(color.Default_Palette_Color.DARK_GRAY)
    sdl.RenderFillRect(primatives.global_renderer, &bar_rect)

    health_ratio := health / max_health
    health_rect := sdl.FRect{10, 10, HEALTH_BAR_WIDTH * health_ratio, HEALTH_BAR_HEIGHT}
    color.sdl_set_color(color.Default_Palette_Color.GRASS_GREEN)
    sdl.RenderFillRect(primatives.global_renderer, &health_rect)
}