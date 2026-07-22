package weapon

import sdl "vendor:sdl3"

import primatives "../sdl_primatives"
import input "../input"
import camera "../camera"

import math "core:math"
import log "core:log"


// Weapon controllers are owned by weapon-wielding entities.
// It describes the entities current weapon capabilities via what weapons they have available,
// what weapon they are currently using, and how they can use it.
// TODO: add support for having no active weapon
Weapon_Controller :: struct {
    aim_angle: f32,
    weapons: map[Weapon_Definition_Tag]Weapon_State,
    active_weapon: Weapon_Definition_Tag,
    gcd_counter: f32,
    draw_distance: f32,
}

weapon_controller_create :: proc(controller: ^Weapon_Controller) {
    controller.weapons = make(map[Weapon_Definition_Tag]Weapon_State)
}

weapon_controller_destroy :: proc(controller: ^Weapon_Controller) {
    delete(controller.weapons)
}

weapon_controller_init :: proc(controller: ^Weapon_Controller, draw_distance: f32) {
    for key, _ in controller.weapons {
        controller.active_weapon = key
    }
    controller.gcd_counter = 0.0
    controller.draw_distance = draw_distance
}

weapon_controller_add_weapon :: proc(controller: ^Weapon_Controller, definition_tag: Weapon_Definition_Tag, animated: bool = false) {
    controller.weapons[definition_tag] = weapon_state_create(definition_tag, animated)
}

weapon_controller_remove_weapon :: proc(controller: ^Weapon_Controller, definition_tag: Weapon_Definition_Tag) {
    if definition_tag not_in controller.weapons {
        log.errorf("Attempt to remove weapon %v from weapon controller that does not have weapon", definition_tag)
        return
    }

    delete_key(&controller.weapons, definition_tag)
}

weapon_controller_select_weapon :: proc(controller: ^Weapon_Controller, definition_tag: Weapon_Definition_Tag) {
    if definition_tag not_in controller.weapons {
        log.errorf("Attempt to select weapon %v from weapon controller that does not have weapon", definition_tag)
        return
    }

    controller.active_weapon = definition_tag
    weapon_state_select(&controller.weapons[controller.active_weapon])    
}

weapon_controller_update :: proc(controller: ^Weapon_Controller, controller_input: input.Input, controller_position: sdl.FPoint) {
    if controller.gcd_counter > 0 do controller.gcd_counter -= primatives.dt

    controller_view_position := camera.world_position_to_view(controller_position)
    controller.aim_angle = math.atan2(controller_input.mouseY - controller_view_position.y, controller_input.mouseX - controller_view_position.x)
    if controller.aim_angle < 0 {
        controller.aim_angle += 2 * math.PI
    }

    // Update all weapons
    for _, &weapon in controller.weapons {
        weapon_state_update(&weapon)
    }

    // Update active weapon
    active_state := &controller.weapons[controller.active_weapon]
    weapon_state_active_update(controller, active_state, controller_input)
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