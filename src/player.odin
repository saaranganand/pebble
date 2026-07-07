// player drawing and handling

package main
import sdl "vendor:sdl3"
import "core:math"

import primatives "global_primatives"
import geo "geometry"
import color "color"

Player :: struct {
    position: sdl.FPoint,
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
    daemon: Daemon,

    allied_damage_areas: [dynamic]geo.Circle,
}

player_init :: proc() -> (player: Player) {
    player.position = {0,0}
    player.hp = game_config.player.max_hp

    player.allied_damage_areas = make([dynamic]geo.Circle)
    return
}

player_destroy :: proc(player: ^Player) {
    delete(player.allied_damage_areas)
}

draw_player :: proc() {
    player := &game.player

    // player rectangle
    playerRect := sdl.FRect{
        x = player.position.x - PLAYER_SIZE / 2,
        y = player.position.y - PLAYER_SIZE / 2,
        w = PLAYER_SIZE,
        h = PLAYER_SIZE
    }
    sdl.SetRenderDrawColor(primatives.global_renderer, 255, 0, 0, 255)
    sdl.RenderFillRect(primatives.global_renderer, &playerRect)

    // player aim cube
    aimX := player.position.x + math.cos(player.aimAngle) * AIM_DIST
    aimY := player.position.y + math.sin(player.aimAngle) * AIM_DIST
    aimRect:=sdl.FRect{
        x = aimX - AIM_SIZE / 2,
        y = aimY - AIM_SIZE / 2,
        w = AIM_SIZE,
        h = AIM_SIZE
    }
    sdl.SetRenderDrawColor(primatives.global_renderer, 100, 255, 100, 255)
    sdl.RenderFillRect(primatives.global_renderer, &aimRect)

    color.sdl_set_color(color.Default_Palette_Colors.WHITE)
    geo.fill_circle({{player.position.x, player.position.y}, 20})
}

update_player :: proc() {
    
    player := &game.player
    camera := &game.camera
    //enemies := &game.enemies
    bullets := &game.bullets
    waves := &game.waves
    input := &game.input

    switch player.active_category { 
    case .Manual:
        switch player.weaponManual {
        case .BitPistol:
            update_bitpistol(&player.bitPistol, player.position.x, player.position.y, player.aimAngle)
        case .Scope:
            update_scope(&player.scope, player.position.x, player.position.y, player.aimAngle)    
        }

    case .Hold:
        switch player.weaponHold {
        case .Bus:
            update_bus(&player.bus)
        case .Trace:
            update_trace(&player.trace, player.position.x, player.position.y, player.aimAngle)
        }

    case .Auto:
        #partial switch player.weaponAuto {
        // case .Ping:
        //     update_ping(&player.ping, waves, player.position.x, player.position.y, input, is_selected, dt)
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
    player.position.x += (targetX - player.position.x) * NUDGE_SPEED
    player.position.y += (targetY - player.position.y) * NUDGE_SPEED
    player.aimAngle = math.atan2(input.mouseY - player.position.y, input.mouseX - player.position.x)
}