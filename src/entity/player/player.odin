package player_character

import sdl "vendor:sdl3"

import camera "src:camera"
import entity "src:entity"
import weapon "src:item/weapon"
import color "src:util/color"
import input "src:input"
import util "src:util"

import log "core:log"

Player_Character :: struct {
    entity: util.Handle,

    tracking_position: sdl.FPoint,

    aimAngle: f32,

    weapon_controller: weapon.Weapon_Controller,
    weapon_select: int,
}

PLAYER_SPEED :: 400
MAX_HP :: 100
AIM_DIST :: 50

player_init :: proc() -> (player: Player_Character) {
    entity_data := entity.entity_make_data({0.0,0.0}, PLAYER_SPEED, MAX_HP, 5, .ALLY, "player.animation")
    player.entity = entity.entity_manager_add_entity(entity_data)

    weapon.weapon_controller_create(&player.weapon_controller)
    weapon.weapon_controller_add_weapon(&player.weapon_controller, "bit_pistol.weapon", true)
    weapon.weapon_controller_add_weapon(&player.weapon_controller, "bit_rifle.weapon", true)
    weapon.weapon_controller_add_weapon(&player.weapon_controller, "bit_scope.weapon", true)
    weapon.weapon_controller_add_weapon(&player.weapon_controller, "energy_charge.weapon", true)
    weapon.weapon_controller_add_weapon(&player.weapon_controller, "tracking_bow.weapon", true)
    weapon.weapon_controller_init(&player.weapon_controller, AIM_DIST, .ALLY)
    player.weapon_select = 0
    return
}

player_destroy :: proc(player: ^Player_Character) {
    weapon.weapon_controller_destroy(&player.weapon_controller)
}

draw_player_accessories :: proc(player: ^Player_Character) {
    player_entity, ok := entity.entity_get(player.entity, .ALLY)
    if !ok do return

    color.sdl_set_color(color.Default_Palette_Color.BABY_BLUE)
    camera.fill_circle({{player_entity.collision.position.x, player_entity.collision.position.y}, player_entity.collision.radius})

    weapon.weapon_controller_draw(&player.weapon_controller, player_entity.collision.position)
}

update_player :: proc(player: ^Player_Character, input: input.Input) {
    player_entity, ok := entity.entity_get(player.entity, .ALLY)
    if !ok do return

    if input.select != player.weapon_controller.active_weapon do weapon.weapon_controller_select_weapon(&player.weapon_controller, input.select)

    player.tracking_position = player_entity.collision.position

    if input.direction.x > 0 {
        entity.entity_set_animation(player_entity, "moving_facing_right")
    }
    else if input.direction.x < 0 do entity.entity_set_animation(player_entity, "moving_facing_left")
    else do entity.entity_set_animation(player_entity, "idle")
    
    // always centers player
    player_entity.direction = input.direction

    player_view_position := camera.world_position_to_view(player_entity.collision.position)

    weapon.weapon_controller_update(&player.weapon_controller, input.mouse_pos, input.fire, player_entity.collision.position)    
}