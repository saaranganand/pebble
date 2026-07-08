package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import primatives "sdl_primatives"
import color "color"
import horde "enemy/horde"
import camera "camera"

PLAYER_SIZE :: 100
AIM_DIST :: 30
AIM_SIZE :: 8
PLAYER_SPEED :: 200

TILE_SIZE :: 64

game := struct {
    player: Player,
    bullets: BulletPool,
    waves: PingWavePool,
    //enemies: EnemyPool,
    game_over: bool,
    input: Input,
    horde: horde.Horde,
}{}

game_loop :: proc() {
    // deltatime
    primatives.global_timer_update()

    game_input()
    game_update()
    game_draw()
}

/*
main :: proc() {
    

    // scope crosshair
    crosshair_surface := img.Load("assets/crosshair.png")
    crosshair_cursor := sdl.CreateColorCursor(crosshair_surface, 32, 32)
    sdl.DestroySurface(crosshair_surface)
    _ =sdl.SetCursor(crosshair_cursor)
    defer sdl.DestroyCursor(crosshair_cursor)

    // trace missile
    trace_tex := img.LoadTexture(primatives.global_renderer, "assets/trace.png")
    defer sdl.DestroyTexture(trace_tex)

    

    // setup
}
    */
game_init :: proc() {
    primatives.global_timer_init()

    game.player = player_init()

    game.horde = horde.create(&game.player.position)
    horde.leader_spawn(&game.horde, {200, 200})

    camera.global_camera_create(f32(app.window_width), f32(app.window_height))
    camera.camera_set_follow(&game.player.position, 0.5)
}

game_close :: proc() {
    horde.destroy(&game.horde)

    player_destroy(&game.player)
}

game_input :: proc() {
    game.input = process_input()
}
/*case sdl.K_1:
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
                }*/

game_update :: proc() {
    apply_movement_penalty()

    camera.camera_update()

    update_player()
    update_bullets()

    /*
    is_ping_selected := player.active_category == .Auto && player.weaponAuto == .Ping
    is_daemon_selected := player.active_category == .Auto && player.weaponAuto == .Daemon

    if (is_ping_selected && input.fire && !player.ping.is_active) ||
    (is_daemon_selected && input.fire && !player.daemon.is_active) {
        reset_auto_weapons(&player, &waves)
    }
    */

    update_waves()
    //update_ping(&player.ping, &waves, player.x, player.y, input, is_ping_selected, dt)
    //update_daemon(&player.daemon, &bullets, &enemies, player.x, player.y, is_daemon_selected, input, dt)

    //update_enemies(game.player.x, game.player.y)

    //detect_collision()
    //detect_bullet_collision()

    if game.player.ping.is_active {
        //detect_ping_damage()
    }
    
    if game.player.hp <=0 {
        game.game_over = true
    }

    horde.update(&game.horde, &game.player.allied_damage_areas)
}

draw_background :: proc() {
    space_width := f32(app.window_width)
    space_height := f32(app.window_height)

    /*
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
    }*/
}

game_draw :: proc() {
    color.sdl_set_color(color.Default_Palette_Colors.WHITE)
    sdl.RenderClear(primatives.global_renderer)

    // drawing
    draw_background()

    draw_player()

    horde.draw(&game.horde)

    draw_hud()
    draw_bullets()
    draw_ping_waves()
    
    
    /*
    if player.active_category == .Hold && player.weaponHold == .Bus {
        detect_bus_damage(&enemies, player.bus, player.x, player.y, player.aimAngle, input, dt)
        draw_bus(player.bus, input, player.x, player.y, player.aimAngle)
    }
    if player.daemon.is_active {
        draw_daemon(player.daemon)
    }*/

    //draw_enemies()
}