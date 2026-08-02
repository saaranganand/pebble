package projectile

import sdl "vendor:sdl3"

import animation "src:data_load/animation"
import primatives "src:sdl_primatives"
import effect "src:entity/entity_effect"
import entity "src:entity"
import data_load "src:data_load"
import geo "src:geometry"

import log "core:log"

Projectile_State :: struct {
    position: sdl.FPoint,
    shape: Shape,
    category: Category,
    speed: f32,
    piercing: int, // Determines how many times a fired projectile can register a hit before it is destroyed, -1 means ad infinitum
    damage: f32,
    shots: int,
    total_lifetime: f32,
    lifetime: f32,
    shoot_angle: f32,
    team: entity.Team,
    apply_effect: Maybe(effect.Effect_Instance_Tag),
    animation_controller: animation.Animation_Controller,
    active: bool,
}

projectile_state_init :: proc(state: ^Projectile_State, position: sdl.FPoint, shoot_angle: f32) {
    state.active = true
    state.position = position
    state.damage = state.damage
    state.shoot_angle = shoot_angle

    #partial switch &s in state.shape {
    case Tracking_Line:
        projectile_Shape_tracking_line_init(state, &s)
    }
} 

projectile_state_check_collision :: proc(state: Projectile_State, circle: geo.Circle) -> bool {
    switch s in state.shape {
    case Circle:
        //log.warnf("%v\n%v\ndist = %v\n\n", geo.Circle{state.position, s.radius}, circle, geo.get_point_distance(state.position, circle.position))
        return geo.are_circles_colliding({state.position, s.radius}, circle)
    case Ray:
        return geo.line_circle_colliding(state.position, state.shoot_angle, circle)
    case Line:
        return false
    case Tracking_Line:
        shape := state.shape.(Tracking_Line)
        return geo.line_angle_segment_circle_colliding(state.position, shape.length, state.shoot_angle,circle)
    }
    return false
}

projectile_state_update :: proc(state: ^Projectile_State, index: u32) {
    if !state.active do return
    defer state.lifetime -= primatives.dt

    if state.category == .RAY && state.lifetime < state.total_lifetime do projectile_manager_remove(index, state.team, state.category)
    if state.lifetime <= 0 do projectile_manager_remove(index, state.team, state.category)
    if state.piercing == 0 do projectile_manager_remove(index, state.team, state.category)

    switch state.category {
        case .BULLET:
            projectile_category_bullet_update(state, state.shape.(Circle))
        case .RAY:
            projectile_category_ray_update(state, state.shape.(Ray))
        case .AOE:
            projectile_category_aoe_update(state, state.shape.(Circle))
        case .RADIAL:
            projectile_category_radial_update(state, state.shape.(Circle))
        case .LINE:
            projectile_category_line_update(state, state.shape.(Line))
        case .TRACKING_ARROW:
            projectile_category_tracking_arrow_update(state, state.shape.(Tracking_Line))
    }
}

projectile_state_draw :: proc(state: ^Projectile_State) {
    if !state.active do return
    switch state.category {

        case .BULLET:
            projectile_category_bullet_draw(state, state.shape.(Circle))
        case .RAY:
            projectile_category_ray_draw(state, state.shape.(Ray))
        case .AOE:
            projectile_category_aoe_draw(state, state.shape.(Circle))
        case .RADIAL:
            projectile_category_radial_draw(state, state.shape.(Circle))
        case .LINE:
            projectile_category_line_draw(state, state.shape.(Line))
        case .TRACKING_ARROW:
            projectile_category_tracking_arrow_draw(state, state.shape.(Tracking_Line))
    }
}