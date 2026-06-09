package main

import "core:fmt"
import sdl "vendor:sdl3"

WINDOW_W :: 1280
WINDOW_H :: 720
PLAYER_SIZE :: 100
AIM_DIST :: 80 // distance of indicator from player
AIM_SIZE :: 16

CAM_SPEED :: 250.0 // how far world moves under player
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
    bullets := BulletPool{}

    last_time := sdl.GetTicks()
    // game loop
    running := true
    for running {
        event: sdl.Event

        for sdl.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    running = false
                case .KEY_DOWN:
                    switch event.key.key {
                        case sdl.K_ESCAPE:
                            running = false
                        case sdl.K_1:
                            player.weaponManual = WeaponManual((int(player.weaponManual)+1) % len(WeaponManual)) //autowrap
                        case sdl.K_2:
                            player.weaponHold = WeaponHold((int(player.weaponHold)+1) % len(WeaponHold))
                        case sdl.K_3:
                            player.weaponAuto = WeaponAuto((int(player.weaponAuto)+1) % len(WeaponAuto))
                    }
                case .MOUSE_WHEEL:
                    // scroll
                }
            }

        current_time := sdl.GetTicks()
        dt := f32(current_time - last_time) / 1000.0
        last_time = current_time

        input := process_input()
        update_player(&player, &camera, &bullets, centerX, centerY, input, dt)
        update_bullets(&bullets, dt, &input)

        draw_camera(renderer, camera)
        draw_player(renderer, player)
        draw_bullets(renderer, &bullets)

        sdl.RenderPresent(renderer)
    }
}