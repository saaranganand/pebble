package weapon

import sdl "vendor:sdl3"
import primatives "../sdl_primatives"

import animation "../assets/animation"
import projectile "../projectile"
import assets "../assets"
import camera "../camera"
import entity "../entity"
import color "../color"
import geo "../geometry"

import log "core:log"

Weapon_State :: struct {
    definition: ^Weapon_Definition,

    cooldown_counter: f32,
    uses_since_cooldown: int,

    charging: bool,
    time_since_charge_start: f32,
    animated: bool,
    animation_controller: animation.Animation_Controller,
}

weapon_state_create :: proc(definition_tag: Weapon_Definition_Tag, team: entity.Team, animated: bool = false) -> (state: Weapon_State) {
    state.definition = weapon_manager_get_definition(definition_tag)

    state.cooldown_counter = 0.0
    state.uses_since_cooldown = 0

    state.charging = false
    state.time_since_charge_start = 0.0

    state.definition.projectile_shell.team = team

    state.animated = animated
    state.animation_controller = animation.animation_controller_create(state.definition.animation_source)

    return
}

weapon_state_init :: proc(state: ^Weapon_State) {
    state.charging = false
    state.time_since_charge_start = 0.0
}

weapon_state_select :: proc(state: ^Weapon_State) {
    weapon_state_init(state)
    sound_set_play(&state.definition.sounds, .SELECT)
}

weapon_on_cooldown :: proc(state: Weapon_State) -> bool {
    return state.cooldown_counter > 0
}

weapon_state_update :: proc(state: ^Weapon_State) {
    if state.cooldown_counter > 0 do state.cooldown_counter -= primatives.dt
}

weapon_state_active_update :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, fire: bool, shoot_position: sdl.FPoint) {
    state.animation_controller.current_animation = "idle"
    
    if state.charging do state.time_since_charge_start += primatives.dt
    else do state.time_since_charge_start = 0

    if fire do weapon_fire(controller, state, shoot_position)
    else if state.charging {
        weapon_shoot(controller, state, shoot_position)
    }
}

weapon_state_active_draw :: proc(state: ^Weapon_State, draw_position: sdl.FPoint, natural_draw_angle: f64, flip_mode: sdl.FlipMode) {
    if !state.animated do return

    camera.camera_draw_animation(&state.animation_controller, draw_position, natural_draw_angle, flip_mode)

    color.sdl_set_color(color.Default_Palette_Color.SKY_BLUE)
    camera.camera_fill_circle(geo.Circle{draw_position, 5.0})
}

weapon_fire :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint) {
    if controller.gcd_counter > 0 || weapon_on_cooldown(state^) do return
    
    state.animation_controller.current_animation = "fire"

    if state.definition.max_charge_time > 0 {
        weapon_charge(controller, state, shoot_position)
        return
    }

    weapon_shoot(controller, state, shoot_position)
}

weapon_charge :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint) {
    state.charging = true

    if state.time_since_charge_start == 0 {
        sound_set_play_and_loop(&state.definition.sounds, .CHARGE)
    }
    state.time_since_charge_start += primatives.dt
    if state.time_since_charge_start > state.definition.max_charge_time do state.time_since_charge_start = state.definition.max_charge_time
}

weapon_shoot :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint) {
    state.animation_controller.current_animation = "shoot"

    // gcd
    controller.gcd_counter = state.definition.gcd_interval

    // cooldown
    state.uses_since_cooldown += 1
    if state.uses_since_cooldown >= state.definition.uses_before_cooldown do state.cooldown_counter = state.definition.cooldown

    proj_shell := state.definition.projectile_shell
    proj_shell.damage = state.definition.damage

    // charging
    if state.charging {
        charge_ratio := state.time_since_charge_start / state.definition.max_charge_time
        proj_shell.speed *= charge_ratio
        proj_shell.damage *= charge_ratio
        proj_shell.piercing = max(int(f32(proj_shell.piercing) * charge_ratio), 1)
        shape := proj_shell.shape.(projectile.Circle)
        shape.radius *= charge_ratio

        proj_shell.animation_controller.scale = 1 + 4 * charge_ratio
        
        sound_stop_loop(&state.definition.sounds, .CHARGE)
        state.charging = false
        state.time_since_charge_start = 0.0
    }

    // shoot callback
    for i in 0..<proj_shell.shots {
        projectile.projectile_manager_spawn(proj_shell, shoot_position, controller.aim_angle)
    }
    sound_set_play(&state.definition.sounds, .SHOOT)
}