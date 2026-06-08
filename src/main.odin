package main

import "core:fmt"
import "core:math"
import sdl "vendor:sdl3"

WINDOW_W :: 1280
WINDOW_H :: 720
PLAYER_SIZE :: 100
AIM_DIST :: 80 // distance of indicator from player
AIM_SIZE :: 16

CAM_SPEED :: 4.0 // how far world moves under player
NUDGE_RADIUS :: 30.0 // how far player leans from center when moving
NUDGE_SPEED :: 0.15 // how fast they lean

TILE_SIZE :: 64

main :: proc() {
    if !sdl.Init({.VIDEO}) {
        fmt.eprintln("sdl Init fail", sdl.GetError())
        return
    }
    defer sdl.Quit()

    // window
    window := sdl.CreateWindow("Pebble",WINDOW_W,WINDOW_H,{})
    if window == nil {
        fmt.eprintln("window creation failed", sdl.GetError())
        return
    }
    defer sdl.DestroyWindow(window)

    // renderer
    renderer := sdl.CreateRenderer(window,nil)
    if renderer == nil {
        fmt.println("renderer creation failed")
        return
    }
    defer sdl.DestroyRenderer(renderer)

    sdl.SetRenderVSync(renderer, 1)

    centerX: f32 = WINDOW_W / 2
    centerY: f32 = WINDOW_H / 2
    camera := Camera{}
    player := player_init()

    // game loop
    running := true
    for running {
        event: sdl.Event

        for sdl.PollEvent(&event) {
            if event.type == sdl.EventType.QUIT {
                running = false
            }
            if event.type == sdl.EventType.KEY_DOWN { // key pressed
                if event.key.key == sdl.K_ESCAPE { // esc key pressed
                    running = false
                }
            }
        }

        input := process_input()
        update_camera(&camera, input.dx, input.dy)
        update_player(&player, centerX, centerY, input)

        draw_camera(renderer, camera)
        draw_player(renderer, player)

        sdl.RenderPresent(renderer)
    }
}