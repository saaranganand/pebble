package weapon

import sdl "vendor:sdl3"
import primatives "../sdl_primatives"

import projectile "../projectile"
import assets "../assets"
import camera "../camera"
import input "../input"
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
    animation_controller: assets.Animation_Controller,
}

weapon_state_create :: proc(definition_tag: Weapon_Definition_Tag, animated: bool = false) -> (state: Weapon_State) {
    state.definition = weapon_manager_get_definition(definition_tag)

    state.cooldown_counter = 0.0
    state.uses_since_cooldown = 0

    state.charging = false
    state.time_since_charge_start = 0.0

    state.animated = animated
    state.animation_controller.data_tag = state.definition.animation_source
    state.animation_controller.current_animation = "idle"

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

weapon_state_active_update :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, controller_input: input.Input, shoot_position: sdl.FPoint) {
    state.animation_controller.current_animation = "idle"
    
    if state.charging do state.time_since_charge_start += primatives.dt
    else do state.time_since_charge_start = 0

    if controller_input.fire do weapon_fire(controller, state, shoot_position)
}

weapon_state_active_draw :: proc(state: ^Weapon_State, draw_position: sdl.FPoint, natural_draw_angle: f64, flip_mode: sdl.FlipMode) {
    if !state.animated do return

    camera.camera_draw_animation(&state.animation_controller, draw_position, natural_draw_angle, flip_mode)

    color.sdl_set_color(color.Default_Palette_Color.SKY_BLUE)
    camera.camera_fill_circle(geo.Circle{draw_position, 5.0})
}

weapon_fire :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint) {
    state.animation_controller.current_animation = "fire"

    if controller.gcd_counter > 0 || weapon_on_cooldown(state^) do return

    weapon_shoot(controller, state, shoot_position)
}

weapon_shoot :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint) {
    state.animation_controller.current_animation = "shoot"

    // weapon buffs from programs
    mults := STAT_MULTS_IDENTITY
    if controller.stat_mults != nil do mults = controller.stat_mults[state.definition.unique_id]

    // gcd
    controller.gcd_counter = state.definition.gcd_interval * mults[.GCD_INTERVAL]

    // cooldown
    state.uses_since_cooldown += 1
    if state.uses_since_cooldown >= state.definition.uses_before_cooldown do state.cooldown_counter = state.definition.cooldown * mults[.COOLDOWN]

    // shoot callback

    shell := state.definition.projectile_shell
    shell.speed *= mults[.PROJECTILE_SPEED]

    // program hit effects are on the projectile
    for instance_id in controller.hit_effects {
        if shell.num_extra_effects >= projectile.MAX_EXTRA_EFFECTS {
            log.errorf("Weapon %v dropped program hit effects past the projectile cap of %v", state.definition.unique_tag, projectile.MAX_EXTRA_EFFECTS)
            break
        }
        shell.extra_effects[shell.num_extra_effects] = instance_id
        shell.num_extra_effects += 1
    }

    projectile.projectile_manager_spawn(shell, shoot_position, controller.aim_angle, state.definition.damage * mults[.DAMAGE])
    sound_set_play(&state.definition.sounds, .SHOOT)
}