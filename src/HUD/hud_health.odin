package HUD

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import primatives "src:sdl_primatives"
import color "src:util/color"

draw_hud_health_bar :: proc(health, max_health, base_max_health: f32) {
    HEALTH_BAR_WIDTH :: 300
    HEALTH_BAR_HEIGHT :: 20

    max_health_scale: f32 = 1
    if base_max_health > 0 do max_health_scale = max_health / base_max_health
    bar_width := HEALTH_BAR_WIDTH * max_health_scale

    bar_rect :=    sdl.FRect{10, 10, bar_width, HEALTH_BAR_HEIGHT}
    color.sdl_set_color(color.Default_Palette_Color.DARK_GRAY)
    sdl.RenderFillRect(primatives.global_renderer, &bar_rect)

    health_ratio := health / max_health
    health_rect := sdl.FRect{10, 10, bar_width * health_ratio, HEALTH_BAR_HEIGHT}
    color.sdl_set_color(color.Default_Palette_Color.GRASS_GREEN)
    sdl.RenderFillRect(primatives.global_renderer, &health_rect)
}