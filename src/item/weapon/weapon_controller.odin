package weapon

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import camera "src:camera"
import entity "src:entity"

import math "core:math"
import log "core:log"


// Weapon controllers are owned by weapon-wielding entities.
// It describes the entities current weapon capabilities via what weapons they have available,
// what weapon they are currently using, and how they can use it.
// TODO: add support for having no active weapon
Weapon_Controller :: struct {
    aim_angle: f32,
    weapons: [dynamic]Weapon_State,
    active_weapon: int,
    gcd_counter: f32,
    draw_distance: f32,
    team: entity.Team,
}

weapon_controller_create :: proc(controller: ^Weapon_Controller) {
    controller.weapons = make([dynamic]Weapon_State)
}

weapon_controller_destroy :: proc(controller: ^Weapon_Controller) {
    delete(controller.weapons)
}

weapon_controller_init :: proc(controller: ^Weapon_Controller, draw_distance: f32, team: entity.Team) {
    controller.active_weapon = 0
    controller.gcd_counter = 0.0
    controller.draw_distance = draw_distance
    controller.team = team
}

weapon_controller_add_weapon :: proc(controller: ^Weapon_Controller, definition_tag: string, animated: bool = false) {
    append(&controller.weapons, weapon_state_create(definition_tag, controller.team, animated))
}

weapon_controller_clear_weapons :: proc(controller: ^Weapon_Controller) {
    clear(&controller.weapons)
}

weapon_controller_select_weapon_num :: proc(controller: ^Weapon_Controller, index: int) {
    if index >= len(controller.weapons) {
        log.errorf("Attempt to select weapon %v from weapon controller with %v weapons", index + 1, len(controller.weapons))
        return
    }

    controller.active_weapon = index
    weapon_state_select(&controller.weapons[controller.active_weapon])    
}

weapon_controller_select_weapon_tag :: proc(controller: ^Weapon_Controller, definition_tag: string) {
    i := 0
    for weapon_state in controller.weapons {
        defer i += 1
        if weapon_state.definition.unique_tag != definition_tag do continue

        controller.active_weapon = i
        weapon_state_select(&controller.weapons[controller.active_weapon])
        return
    }
    
    log.errorf("Attempt to select weapon %v from weapon controller that does not have weapon", definition_tag)
}

weapon_controller_select_weapon :: proc{
    weapon_controller_select_weapon_num,
    weapon_controller_select_weapon_tag
}

weapon_controller_update :: proc(controller: ^Weapon_Controller, mouse_pos: sdl.FPoint, fire: bool, controller_position: sdl.FPoint) {
    if controller.gcd_counter > 0 do controller.gcd_counter -= primatives.dt

    controller_view_position := camera.world_position_to_view(controller_position)
    controller.aim_angle = math.atan2(mouse_pos.y - controller_view_position.y, mouse_pos.x - controller_view_position.x)
    if controller.aim_angle < 0 {
        controller.aim_angle += 2 * math.PI
    }

    // Update all weapons
    for &weapon in controller.weapons {
        weapon_state_update(&weapon)
    }

    shoot_position := controller_position + { math.cos(controller.aim_angle), math.sin(controller.aim_angle) } * controller.draw_distance

    // Update active weapon
    active_state := &controller.weapons[controller.active_weapon]
    weapon_state_active_update(controller, active_state, fire, shoot_position)
}

weapon_controller_draw :: proc(controller: ^Weapon_Controller, controller_position: sdl.FPoint) {
    active_state := &controller.weapons[controller.active_weapon]

    draw_position := controller_position + { math.cos(controller.aim_angle), math.sin(controller.aim_angle) } * controller.draw_distance

    // TODO:
    // 1 this should be abstracted
    // 2 this is way too adhoc, needs to be simpler
    natural_draw_angle := controller.aim_angle - active_state.definition.animation_default_angle

    flip_mode := sdl.FlipMode.NONE
    if natural_draw_angle >= math.PI / 2.0 && natural_draw_angle <= (3.0 * math.PI) / 2.0 do flip_mode = .VERTICAL
    weapon_state_active_draw(active_state, draw_position, f64(natural_draw_angle), flip_mode)
}