package projectile

import sdl "vendor:sdl3"

import animation "src:data_load/animation"
import primatives "src:sdl_primatives"
import entity "src:entity"
import geo "src:geometry"

import xar "core:container/xar"

Category :: enum { BULLET, RAY, AOE, RADIAL, LINE, TRACKING_ARROW }

State :: struct {
    active: bool,
    position: sdl.FPoint,
    shape: Shape,

    category: Category,
    team: entity.Team,

    damage: f32,
    piercing: uint, // Determines how many times a fired projectile can register a hit before it is destroyed, -1 means ad infinitum
    speed: f32,
    max_lifetime: f32,

    apply_effect: Maybe(string),
    animation_controller: animation.Animation_Controller,

    total_lifetime: f32,
    shoot_angle: f32,
}

state_init :: proc(shell: Shell, position: sdl.FPoint, shoot_angle: f32) -> (state: State) {
    state.active = true
    state.position = position

    state.category = shell.category
    state.team = shell.team

    state.damage = shell.damage
    state.piercing = shell.piercing
    state.speed = shell.speed
    state.max_lifetime = shell.lifetime

    state.apply_effect = shell.apply_effect
    state.animation_controller = animation.animation_controller_create(shell.animation_source, shell.scale)

    state.total_lifetime = 0
    state.shoot_angle = shoot_angle

    init_procs[shell.category](&state, shell)

    return
} 

state_spawn :: proc(shell: Shell, position: sdl.FPoint, shoot_angle: f32) {
    state := state_init(shell, position, shoot_angle)
    xar.array_push_back_elem(&global_projectile_manager.projectiles[shell.team], state)
}

state_check_collision :: proc(state: State, circle: geo.Circle) -> bool {
    return collision_procs[state.category](state, circle)
}

state_check_lifetime :: proc(state: ^State, index: uint) {
    if state.total_lifetime > state.max_lifetime do projectile_manager_remove(index, state.team, state.category)
    else if state.piercing == 0 do projectile_manager_remove(index, state.team, state.category)

    state.total_lifetime += primatives.dt
}

state_update :: proc(state: ^State, index: uint) {
    if !state.active do return
    
    state_check_lifetime(state, index)

    update_procs[state.category](state)
}

state_draw :: proc(state: ^State) {
    if !state.active do return

    draw_procs[state.category](state)
}