package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

PLAYER_SIZE :: 100
AIM_DIST :: 80 // distance of indicator from player
AIM_SIZE :: 16

CAM_SPEED :: 250.0 // how far world moves under player
NUDGE_RADIUS :: 30.0 // how far player leans from center when moving
NUDGE_SPEED :: 0.15 // how fast they lean

TILE_SIZE :: 64

game := struct {
    dt: f32,
    last_time: u64,
    camera: Camera,
    player: Player,
    bullets: BulletPool,
    waves: PingWavePool,
    enemies: EnemyPool,
    game_over: bool,
    input: Input,
}{
    dt = 0.16,
}

game_loop :: proc() {
    // deltatime
    current_time := sdl.GetTicks()
    game.dt = f32(current_time - game.last_time) / 1000.0
    game.last_time = current_time

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
    trace_tex := img.LoadTexture(global_renderer, "assets/trace.png")
    defer sdl.DestroyTexture(trace_tex)

    

    // setup
}
    */
game_init :: proc() {
    game.last_time = sdl.GetTicks()

    game.player = player_init()
}

game_close :: proc() {

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

    update_enemies(game.player.x, game.player.y)

    detect_collision()
    detect_bullet_collision()

    if game.player.ping.is_active {
        detect_ping_damage()
    }
    
    if game.player.hp <=0 {
        game.game_over = true
    }
}

game_draw :: proc() {
    sdl_set_color(Default_Palette_Colors.WHITE)
    sdl.RenderClear(global_renderer)

    // drawing
    draw_camera()
    draw_player()
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

    draw_enemies()
}