// player drawing and handling

package main
import sdl "vendor:sdl3"

import math "core:math"
import log "core:log"

import primatives "sdl_primatives"
import geo "geometry"
import camera "camera"
import color "color"
import assets "assets" 
import entity "entity"
import weapon "weapon"

Player :: struct {
    entity: entity.Entity_Handle,

    tracking_position: sdl.FPoint,

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

    weapon_controller: weapon.Weapon_Controller,
    weapon_select: int,

    allied_damage_areas: [dynamic]geo.Circle,
}

player_init :: proc() -> (player: Player) {
    entity_data := entity.entity_make_data({0.0,0.0}, PLAYER_SPEED, game_config.player.max_hp, 10, .ALLY, .PLAYER, "animations/entity/player.yaml")
    player.entity = entity.entity_manager_add_entity(entity_data)

    player.allied_damage_areas = make([dynamic]geo.Circle)

    weapon.weapon_controller_create(&player.weapon_controller)
    weapon.weapon_controller_add_weapon(&player.weapon_controller, "bit_pistol", true)
    weapon.weapon_controller_add_weapon(&player.weapon_controller, "bit_rifle", true)
    weapon.weapon_controller_init(&player.weapon_controller, AIM_DIST)
    player.weapon_select = 0
    return
}

player_destroy :: proc(player: ^Player) {
    delete(player.allied_damage_areas)
    weapon.weapon_controller_destroy(&player.weapon_controller)
}

draw_player :: proc() {
    player := &game.player

    entity, ok := entity.entity_get(player.entity, .ALLY)
    if !ok do return

    color.sdl_set_color(color.Default_Palette_Color.BABY_BLUE)
    camera.camera_fill_circle({{entity.position.x, entity.position.y}, 10})

    weapon.weapon_controller_draw(&player.weapon_controller, entity.position)
}

update_player :: proc() {
    
    player := &game.player
    bullets := &game.bullets
    waves := &game.waves
    input := &game.input

    player_entity, ok := entity.entity_get(player.entity, .ALLY)
    if !ok do return

    if input.select == 1 && player.weapon_select != 1 {
        player.weapon_select = 1
        weapon.weapon_controller_select_weapon(&player.weapon_controller, "bit_pistol")
    }

    if input.select == 2 && player.weapon_select != 2 {
        player.weapon_select = 2
        weapon.weapon_controller_select_weapon(&player.weapon_controller, "bit_rifle")
    }

    player.tracking_position = player_entity.position

    if input.direction.x > 0 do entity.entity_set_animation(player_entity, "moving_facing_right")
    else if input.direction.x < 0 do entity.entity_set_animation(player_entity, "moving_facing_left")
    else do entity.entity_set_animation(player_entity, "idle")
    
    // always centers player
    player_entity.move_direction = input.direction

    player_view_position := camera.world_position_to_view(player_entity.position)
    player.aimAngle = math.atan2(input.mouseY - player_view_position.y, input.mouseX - player_view_position.x)

    weapon.weapon_controller_update(&player.weapon_controller, input^, player_entity.position)

    /*switch player.active_category { 
    case .Manual:
        switch player.weaponManual {
        case .BitPistol:
            update_bitpistol(&player.bitPistol, player_entity.position.x, player_entity.position.y, player.aimAngle)
        case .Scope:
            update_scope(&player.scope, player_entity.position.x, player_entity.position.y, player.aimAngle)    
        }

    case .Hold:
        switch player.weaponHold {
        case .Bus:
            update_bus(&player.bus)
        case .Trace:
            update_trace(&player.trace, entity.position.x, entity.position.y, player.aimAngle)
        }

    case .Auto:
        #partial switch player.weaponAuto {
        // case .Ping:
        //     update_ping(&player.ping, waves, player.position.x, player.position.y, input, is_selected, dt)
        // case .Daemon:
        //     update_daemon(&player.daemon, is_selected, input, dt)
        }
    }*/

    
}