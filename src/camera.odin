package main
import sdl "vendor:sdl3"
import "core:math"

Camera :: struct {
    x, y: f32
}

draw_camera :: proc(renderer: ^sdl.Renderer, cam: Camera) {
    //background
    sdl.SetRenderDrawColor(renderer, 255, 255, 255, 255)
    sdl.RenderClear(renderer)

    // bg texture
    sdl.SetRenderDrawColor(renderer, 40, 40, 50, 255)
    startX:= -math.mod(cam.x, f32(TILE_SIZE))
    for x:=startX; x < WINDOW_W; x += TILE_SIZE {
        sdl.RenderLine(renderer, x, 0, x, WINDOW_H)
    }
    startY:= -math.mod(cam.y, f32(TILE_SIZE))
    for y:=startY; y < WINDOW_H; y += TILE_SIZE {
        sdl.RenderLine(renderer, 0, y, WINDOW_W, y)
    }
}

update_camera :: proc(cam: ^Camera, dx, dy: f32, dt: f32) {
    cam.x += dx * CAM_SPEED * dt
    cam.y += dy * CAM_SPEED * dt
}
