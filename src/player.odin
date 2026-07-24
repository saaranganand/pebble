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
import program "program"

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
    program_loadout: program.Program_Loadout,

    allied_damage_areas: [dynamic]geo.Circle,
}

PLAYER_SPEED :: 400

player_init :: proc() -> (player: Player) {
    entity_data := entity.entity_make_data({0.0,0.0}, game_config.player.speed, game_config.player.max_hp, 10, .ALLY, .PLAYER, "animations/entity/player.yaml")
    player.entity = entity.entity_manager_add_entity(entity_data)

    player.allied_damage_areas = make([dynamic]geo.Circle)

    weapon.weapon_controller_create(&player.weapon_controller)
    weapon.weapon_controller_add_weapon(&player.weapon_controller, "bit_pistol", true)
    weapon.weapon_controller_add_weapon(&player.weapon_controller, "bit_rifle", true)
    weapon.weapon_controller_init(&player.weapon_controller, AIM_DIST)
    player.weapon_controller.active_weapon = "bit_pistol" // default
    player.weapon_select = 0
    return
}

player_destroy :: proc(player: ^Player) {
    delete(player.allied_damage_areas)
    program.program_loadout_destroy(&player.program_loadout)
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

    if input.select != 0 && input.select != player.weapon_select {
        switch input.select {
            case 1: 
                weapon.weapon_controller_select_weapon(&player.weapon_controller, "bit_pistol")
            case 2:
                weapon.weapon_controller_select_weapon(&player.weapon_controller, "bit_rifle")
        }
        player.weapon_select = input.select
    }

    player.tracking_position = player_entity.position

    if input.direction.x > 0 do entity.entity_set_animation(player_entity, "moving_facing_right")
    else if input.direction.x < 0 do entity.entity_set_animation(player_entity, "moving_facing_left")
    else do entity.entity_set_animation(player_entity, "idle")
    
    // always centers player
    player_entity.move_direction = input.direction

    // log.warnf("player dt=%v dir=%v speed=%v pos=%v", primatives.dt, input.direction, player_entity.move_speed, player_entity.position)

    player_view_position := camera.world_position_to_view(player_entity.position)
    player.aimAngle = math.atan2(input.mouseY - player_view_position.y, input.mouseX - player_view_position.x)

    weapon.weapon_controller_update(&player.weapon_controller, input^, player_entity.position)

}