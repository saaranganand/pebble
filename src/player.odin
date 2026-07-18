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

    // TODO: move animation stuff into entity
    frame_count: f32,
    current_animation: assets.Animation_Tag,
    animation_tag: assets.Data_Tag,

    allied_damage_areas: [dynamic]geo.Circle,
}

player_init :: proc() -> (player: Player) {
    entity_data := entity.entity_make_data({0.0,0.0}, PLAYER_SPEED, game_config.player.max_hp, .ALLY, .PLAYER)
    player.entity = entity.entity_manager_add_entity(&game.entity_manager, entity_data)

    player.frame_count = 0

    player.current_animation = "dancing"
    player.animation_tag = "animations/entity/player.yaml"

    player.allied_damage_areas = make([dynamic]geo.Circle)
    return
}

player_destroy :: proc(player: ^Player) {
    delete(player.allied_damage_areas)
}

draw_player :: proc() {
    player := &game.player

    entity, ok := entity.entity_get(&game.entity_manager, player.entity)
    if !ok do return

    // aim reticle
    aim_circle := geo.Circle{ entity.position + { math.cos(player.aimAngle), math.sin(player.aimAngle) } * AIM_DIST, AIM_SIZE }

    color.sdl_set_color(color.Default_Palette_Colors.SKY_BLUE)
    camera.camera_fill_circle(aim_circle)

    camera.camera_draw_animation(player.animation_tag, player.current_animation, &player.frame_count, entity.position)

    color.sdl_set_color(color.Default_Palette_Colors.BABY_BLUE)
    camera.camera_fill_circle({{entity.position.x, entity.position.y}, 10})
}

update_player :: proc() {
    
    player := &game.player
    bullets := &game.bullets
    waves := &game.waves
    input := &game.input

    entity, ok := entity.entity_get(&game.entity_manager, player.entity)
    if !ok do return

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

    if input.direction.x > 0 do player.current_animation = "moving_facing_right"
    else if input.direction.x < 0 do player.current_animation = "moving_facing_left"
    else do player.current_animation = "idle"
    
    // always centers player
    entity.position += input.direction * PLAYER_SPEED * primatives.dt

    player_view_position := camera.world_position_to_view(entity.position)
    player.aimAngle = math.atan2(input.mouseY - player_view_position.y, input.mouseX - player_view_position.x)
}