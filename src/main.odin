package main

import "core:fmt"
import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import img "vendor:sdl3/image"

WINDOW_W :: 1280
WINDOW_H :: 720
PLAYER_SIZE :: 100
AIM_DIST :: 80 // distance of indicator from player
AIM_SIZE :: 16

CAM_SPEED :: 250.0 // how far world moves under player
NUDGE_RADIUS :: 30.0 // how far player leans from center when moving
NUDGE_SPEED :: 0.15 // how fast they lean

TILE_SIZE :: 64

reset_auto_weapons :: proc(player: ^Player, pool: ^PingWavePool) {
    player.ping.is_active = false
    for &w in pool.waves {
        w.alive = false
    }
    player.daemon.is_active = false
}

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

    // font
    ttf.Init()
    font := ttf.OpenFont("assets/font1.ttf", 24)
    defer ttf.CloseFont(font)

    // scope crosshair
    crosshair_surface := img.Load("assets/crosshair.png")
    crosshair_cursor := sdl.CreateColorCursor(crosshair_surface, 32, 32)
    sdl.DestroySurface(crosshair_surface)
    _ =sdl.SetCursor(crosshair_cursor)
    defer sdl.DestroyCursor(crosshair_cursor)

    // trace missile
    trace_tex := img.LoadTexture(renderer, "assets/trace.png")
    defer sdl.DestroyTexture(trace_tex)

    sdl.SetRenderVSync(renderer, 1)

    centerX: f32 = WINDOW_W / 2
    centerY: f32 = WINDOW_H / 2
    camera := Camera{}
    player := player_init()
    bullets := BulletPool{}
    waves := PingWavePool{}
    enemies := EnemyPool{}
    game_over: bool

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
                            player.active_category = WeaponCategory.Manual
                        case sdl.K_2:
                            player.active_category = WeaponCategory.Hold
                        case sdl.K_3:
                            player.active_category = WeaponCategory.Auto
                    }
                case .MOUSE_WHEEL:
                    switch player.active_category {
                        case .Manual:
                            player.weaponManual = WeaponManual((int(player.weaponManual)+1) % len(WeaponManual)) //autowrap
                        case .Hold:
                            player.weaponHold = WeaponHold((int(player.weaponHold)+1) % len(WeaponHold))
                        case .Auto:
                            player.weaponAuto = WeaponAuto((int(player.weaponAuto)+1) % len(WeaponAuto))
                    }
            }
        }
        update_cursor(player, crosshair_cursor)
        
        // deltatime
        current_time := sdl.GetTicks()
        dt := f32(current_time - last_time) / 1000.0
        last_time = current_time

        if !game_over{
            // updates
            input := process_input()
            update_player(&player, &camera, &bullets, &waves, centerX, centerY, input, dt)
            update_bullets(&bullets, &enemies, dt, input)
            is_ping_selected := player.active_category == .Auto && player.weaponAuto == .Ping
            is_daemon_selected := player.active_category == .Auto && player.weaponAuto == .Daemon

            if (is_ping_selected && input.fire && !player.ping.is_active) ||
            (is_daemon_selected && input.fire && !player.daemon.is_active) {
                reset_auto_weapons(&player, &waves)
            }

            update_ping(&player.ping, &waves, player.x, player.y, input, is_ping_selected, dt)
            update_daemon(&player.daemon, is_daemon_selected, input, dt)
            update_enemies(&enemies, player.x, player.y, input, dt)

            detect_collision(&enemies, &player, dt)
            detect_bullet_collision(&enemies, &bullets, dt)
            
            // drawing
            draw_camera(renderer, camera)
            draw_player(renderer, player)
            draw_hud(renderer, font, player, input)
            draw_bullets(renderer, &bullets, trace_tex)
            if player.active_category == .Hold && player.weaponHold == .Bus {
                detect_bus_damage(&enemies, player.bus, player.x, player.y, player.aimAngle, input, dt)
                draw_bus(renderer, player.bus, input, player.x, player.y, player.aimAngle)
            }
            if player.ping.is_active {
                detect_ping_damage(&enemies, &waves, dt)
                draw_ping_waves(renderer, &waves)
            }
            if player.daemon.is_active{
                draw_daemon(renderer, player.daemon, player.x, player.y)
            }
            draw_enemies(renderer, &enemies)

            if player.hp <=0 {
                game_over = true
            }
        } else {
            draw_camera(renderer, camera) // clrscr
            surf := ttf.RenderText_Blended(font, "GAME OVER", 0, sdl.Color{0, 0, 0, 255})
            texture := sdl.CreateTextureFromSurface(renderer, surf)
            sdl.DestroySurface(surf)

            w, h : f32
            sdl.GetTextureSize(texture, &w, &h)

            dst := sdl.FRect{x = WINDOW_W/2 - w/2, y = WINDOW_H/2 - h/2, w = w, h = h}
            sdl.RenderTexture(renderer, texture, nil, &dst)
            sdl.DestroyTexture(texture)
        }

        sdl.RenderPresent(renderer)
    }
}