// player drawing and handling

package main
import sdl "vendor:sdl3"
import "core:math"



Player :: struct {
    x, y: f32,
    hp: f32,
    aimAngle: f32,
    weaponManual: WeaponManual,
    weaponHold: WeaponHold,
    weaponAuto: WeaponAuto,
    active_category: WeaponCategory,
    bitPistol: BitPistol,
    scope: Scope,
    bus: Bus,
    trace: Trace,
    ping: Ping,
    daemon: Daemon
}

player_init :: proc() -> Player {
    return Player{x = 0, y = 0, hp = game_config.player.max_hp}
}

draw_player :: proc() {
    player := &game.player

    // player rectangle
    playerRect := sdl.FRect{
        x = player.x - PLAYER_SIZE / 2,
        y = player.y - PLAYER_SIZE / 2,
        w = PLAYER_SIZE,
        h = PLAYER_SIZE
    }
    sdl.SetRenderDrawColor(global_renderer, 255, 0, 0, 255)
    sdl.RenderFillRect(global_renderer, &playerRect)

    // player aim cube
    aimX := player.x + math.cos(player.aimAngle) * AIM_DIST
    aimY := player.y + math.sin(player.aimAngle) * AIM_DIST
    aimRect:=sdl.FRect{
        x = aimX - AIM_SIZE / 2,
        y = aimY - AIM_SIZE / 2,
        w = AIM_SIZE,
        h = AIM_SIZE
    }
    sdl.SetRenderDrawColor(global_renderer, 100, 255, 100, 255)
    sdl.RenderFillRect(global_renderer, &aimRect)

    sdl_set_color(Default_Palette_Colors.WHITE)
    fill_circle(player.x, player.y, 20)
}

update_player :: proc() {
    
    player := &game.player
    camera := &game.camera
    enemies := &game.enemies
    bullets := &game.bullets
    waves := &game.waves
    input := &game.input

    switch player.active_category { 
    case .Manual:
        switch player.weaponManual {
        case .BitPistol:
            update_bitpistol(&player.bitPistol, player.x, player.y, player.aimAngle)
        case .Scope:
            update_scope(&player.scope, player.x, player.y, player.aimAngle)    
        }

    case .Hold:
        switch player.weaponHold {
        case .Bus:
            update_bus(&player.bus)
        case .Trace:
            update_trace(&player.trace, player.x, player.y, player.aimAngle)
        }

    case .Auto:
        #partial switch player.weaponAuto {
        // case .Ping:
        //     update_ping(&player.ping, waves, player.x, player.y, input, is_selected, dt)
        // case .Daemon:
        //     update_daemon(&player.daemon, is_selected, input, dt)
        }
    }
    
    // always centers player
    update_camera(input.dx, input.dy)

    centerX := f32(app.window_width) / 2
    centerY := f32(app.window_height) / 2

    targetX := centerX + input.dx * NUDGE_RADIUS
    targetY := centerY + input.dy * NUDGE_RADIUS
    player.x += (targetX - player.x) * NUDGE_SPEED
    player.y += (targetY - player.y) * NUDGE_SPEED
    player.aimAngle = math.atan2(input.mouseY - player.y, input.mouseX - player.x)
}