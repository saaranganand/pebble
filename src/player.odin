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
    entity_data := entity.entity_make_data({0.0,0.0}, game_config.player.speed, game_config.player.max_hp, .ALLY, .PLAYER, "animations/entity/player.yaml")
    player.entity = entity.entity_manager_add_entity(entity_data)

    player.allied_damage_areas = make([dynamic]geo.Circle)

    weapon.weapon_controller_create(&player.weapon_controller)
    weapon.weapon_controller_add_weapon(&player.weapon_controller, "bit_pistol", true)
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

    entity, ok := entity.entity_get(player.entity)
    if !ok do return

    // aim reticle
    //aim_circle := geo.Circle{ entity.position + { math.cos(player.aimAngle), math.sin(player.aimAngle) } * AIM_DIST, AIM_SIZE }

    //color.sdl_set_color(color.Default_Palette_Color.SKY_BLUE)
    //camera.camera_fill_circle(aim_circle)

    camera.camera_draw_animation(&entity.animation_controller, entity.position)

    color.sdl_set_color(color.Default_Palette_Color.BABY_BLUE)
    camera.camera_fill_circle({{entity.position.x, entity.position.y}, 10})

    weapon.weapon_controller_draw(&player.weapon_controller, entity.position)
}

update_player :: proc() {
    
    player := &game.player
    bullets := &game.bullets
    waves := &game.waves
    input := &game.input

    entity, ok := entity.entity_get(player.entity)
    if !ok do return

    if input.select == 1 && player.weapon_select != 1 {
        player.weapon_select = 1
        weapon.weapon_controller_select_weapon(&player.weapon_controller, "bit_pistol")
    }

    player.tracking_position = entity.position

    entity.move_speed = entity.base_move_speed

    switch player.active_category { 
    case .Manual:
        switch player.weaponManual {
        case .BitPistol:
            update_bitpistol(&player.bitPistol, entity.position.x, entity.position.y, player.aimAngle)
        case .Scope:
            update_scope(&player.scope, entity.position.x, entity.position.y, player.aimAngle)    
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
    }

    if input.direction.x > 0 do entity.animation_controller.current_animation = "moving_facing_right"
    else if input.direction.x < 0 do entity.animation_controller.current_animation = "moving_facing_left"
    else do entity.animation_controller.current_animation = "idle"
    
    // always centers player
    entity.position += input.direction * game_config.player.speed * primatives.dt

    player_view_position := camera.world_position_to_view(entity.position)
    player.aimAngle = math.atan2(input.mouseY - player_view_position.y, input.mouseX - player_view_position.x)

    weapon.weapon_controller_update(&player.weapon_controller, input^, entity.position)
}