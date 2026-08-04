package projectile

import sdl "vendor:sdl3"

import animation "src:data_load/animation"
import primatives "src:sdl_primatives"
import camera "src:camera"
import entity "src:entity"
import handle "src:handle"
import geo "src:geometry"
import util "src:util"

import xar "core:container/xar"
import rand "core:math/rand"
import math "core:math"


Tracking_Arrow_State :: struct {
    active: bool,
    position: sdl.FPoint,

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

    length: f32,
    tracking: util.Handle,
    tracking_team: entity.Team,
    turn_speed: f32,
}

tracking_arrow_init :: proc(shell: Shell, position: sdl.FPoint, shoot_angle: f32) -> (state: Tracking_Arrow_State) {
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

    // Tracking
    state.length = shell.shape_length
    state.turn_speed = shell.shape_turn_speed

    state.tracking_team = entity.Team.ALLY
    if state.team == .ALLY do state.tracking_team = .ENEMY
    tracking, success := entity.entity_manager_get_random_handle(state.tracking_team)
    state.tracking = tracking

    RANDOM_SPAWN_RANGE :: 10
    state.position += { rand.float32_range(-RANDOM_SPAWN_RANGE, RANDOM_SPAWN_RANGE), rand.float32_range(-RANDOM_SPAWN_RANGE, RANDOM_SPAWN_RANGE) }

    return
}

tracking_arrow_spawn :: proc(shell: Shell, position: sdl.FPoint, shoot_angle: f32) {
    state := tracking_arrow_init(shell, position, shoot_angle)
    xar.array_push_back_elem(&global_projectile_manager.tracking_arrows[shell.team], state)
}

tracking_arrows_update :: proc(team: entity.Team) {
    list := &global_projectile_manager.tracking_arrows[team]

    it := xar.iterator(list)
    for state, idx in xar.iterate_by_ptr(&it) {
        tracking_arrow_update(state, uint(idx))
    }

    queue := &global_projectile_manager.tracking_arrow_remove_queues[team]

    #reverse for idx in queue {
        xar.unordered_remove(list, idx)
    }

    clear(queue)
}

tracking_arrow_check_lifetime :: proc(state: ^Tracking_Arrow_State, index: uint) {
    if state.total_lifetime > state.max_lifetime do projectile_manager_remove(index, state.team, state.category)
    if state.piercing == 0 do projectile_manager_remove(index, state.team, state.category)

    state.total_lifetime += primatives.dt
}

tracking_arrow_update :: proc(state: ^Tracking_Arrow_State, index: uint) {
    if !state.active do return
    
    tracking_arrow_check_lifetime(state, index)
    
    direction: sdl.FPoint

    defer state.position += direction * state.speed * primatives.dt

    defer direction = sdl.FPoint{
        math.cos(state.shoot_angle),
        math.sin(state.shoot_angle),
    }

    target_entity, target_ok := entity.entity_get(state.tracking, state.tracking_team)
    if !target_ok do return

    to_target := target_entity.collision.position - state.position
    target_angle := math.atan2(to_target.y, to_target.x)

    diff := math.atan2(math.sin(target_angle - state.shoot_angle), math.cos(target_angle - state.shoot_angle))

    max_step := state.turn_speed * primatives.dt

    if abs(diff) > max_step {
        state.shoot_angle += max_step * math.sign(diff)
    }
}

tracking_arrow_collision :: proc(state: Tracking_Arrow_State, circle: geo.Circle) -> bool {
    return geo.line_angle_segment_circle_colliding(state.position, state.length, state.shoot_angle, circle)
}

tracking_arrows_draw :: proc(team: entity.Team) {
    list := &global_projectile_manager.tracking_arrows[team]

    it := xar.iterator(list)
    for state, idx in xar.iterate_by_ptr(&it) {
        tracking_arrow_draw(state)
    }
}

tracking_arrow_draw :: proc(state: ^Tracking_Arrow_State) {
    if !state.active do return
    
    camera.camera_draw_animation(&state.animation_controller, state.position, f64(state.shoot_angle))
}