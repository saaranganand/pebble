package main
import sdl "vendor:sdl3"
import "core:math"

import primatives "global_primatives"
import color "color"

Camera :: struct {
    x, y: f32
}

// draws background texutre: this needs to be refactored, moved, renamed and reconceptualized
draw_camera :: proc() {
    cam := &game.camera
    space_width := f32(app.window_width)
    space_height := f32(app.window_height)

    // bg texture
    color.sdl_set_color(color.Default_Palette_Colors.BLACK)

    x := -math.mod(cam.x, f32(TILE_SIZE))
    for x < space_width {
        sdl.RenderLine(primatives.global_renderer, x, 0, x, space_height)
        x += TILE_SIZE
    }

    y := -math.mod(cam.y, f32(TILE_SIZE))
    for y < space_height {
        sdl.RenderLine(primatives.global_renderer, 0, y, space_width, y)
        y += TILE_SIZE
    }
}

update_camera :: proc(dx, dy: f32) {
    cam := &game.camera

    cam.x += dx * CAM_SPEED * primatives.dt
    cam.y += dy * CAM_SPEED * primatives.dt
}
