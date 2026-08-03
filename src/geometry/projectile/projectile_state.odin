package projectile

import sdl "vendor:sdl3"

import animation "src:data_load/animation"
import primatives "src:sdl_primatives"
import entity "src:entity"
import geo "src:geometry"

Category :: enum { BULLET, RAY, AOE, RADIAL, LINE, TRACKING_ARROW }

Projectile_State :: struct {
    active: bool,
    position: sdl.FPoint,
    shape: Shape,

    category: Category,
    team: entity.Team,

    damage: f32,
    piercing: uint, // Determines how many times a fired projectile can register a hit before it is destroyed, -1 means ad infinitum
    speed: f32,
    lifetime: f32,
    shots: uint,

    apply_effect: Maybe(string),
    animation_controller: animation.Animation_Controller,

    total_lifetime: f32,
    shoot_angle: f32,
}

projectile_state_init :: proc(shell: Projectile_Shell, position: sdl.FPoint, shoot_angle: f32) -> (state: Projectile_State) {
    state.active = true
    state.position = position

    state.category = shell.category
    state.team = shell.team

    state.damage = shell.damage
    state.piercing = shell.piercing
    state.speed = shell.speed
    state.lifetime = shell.lifetime
    state.shots = max(1, shell.shots) 

    state.apply_effect = shell.apply_effect
    state.animation_controller = animation.animation_controller_create(shell.animation_source, shell.scale)

    state.total_lifetime = 0
    state.shoot_angle = shoot_angle

    projectile_init_procs[shell.category](&state, shell)

    return
} 

projectile_state_check_collision :: proc(state: Projectile_State, circle: geo.Circle) -> bool {
    return projectile_collision_procs[state.category](state, circle)
}

projectile_state_check_lifetime :: proc(state: ^Projectile_State, index: uint) {
    if state.total_lifetime > state.lifetime do projectile_manager_remove(index, state.team, state.category)
    if state.piercing == 0 do projectile_manager_remove(index, state.team, state.category)

    state.total_lifetime += primatives.dt
}

projectile_state_update :: proc(state: ^Projectile_State, index: uint) {
    if !state.active do return
    
    projectile_state_check_lifetime(state, index)

    projectile_update_procs[state.category](state)
}

projectile_state_draw :: proc(state: ^Projectile_State) {
    if !state.active do return

    projectile_draw_procs[state.category](state)
}