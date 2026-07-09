// player drawing and handling

package main
import sdl "vendor:sdl3"

import math "core:math"
import log "core:log"

import primatives "sdl_primatives"
import geo "geometry"
import camera "camera"
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

    // aim reticle
    aim_circle := geo.Circle{ player.position + { math.cos(player.aimAngle), math.sin(player.aimAngle) } * AIM_DIST, AIM_SIZE }

    color.sdl_set_color(color.Default_Palette_Colors.SKY_BLUE)
    camera.camera_fill_circle(aim_circle)

    color.sdl_set_color(color.Default_Palette_Colors.BABY_BLUE)
    camera.camera_fill_circle({{player.position.x, player.position.y}, 40})
}

update_player :: proc() {
    
    player := &game.player
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
    player.position += sdl.FPoint{ input.dx, input.dy } * PLAYER_SPEED * primatives.dt

    player_view_position := camera.world_position_to_view(player.position)
    player.aimAngle = math.atan2(input.mouseY - player_view_position.y, input.mouseX - player_view_position.x)
}