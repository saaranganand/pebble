package projectile

import sdl "vendor:sdl3"

import animation "src:data_load/animation"
import primatives "src:sdl_primatives"
import effect "src:entity/entity_effect"
import entity "src:entity"
import data_load "src:data_load"
import geo "src:geometry"

import log "core:log"

Projectile_Shell :: struct {
    category: Category,
    team: entity.Team,
    damage: f32,
    piercing: uint,
    speed: f32,
    lifetime: f32,
    shots: uint,
    scale: f32,

    animation_source: string,
    apply_effect: Maybe(string),

    shape_radius: f32,
    shape_length: f32,
    shape_turn_speed: f32,
}

projectile_shell_add_defaults :: proc(shell: ^Projectile_Shell, team: entity.Team) {
    if shell.shots == 0 do shell.shots = 1
    if shell.scale == 0 do shell.scale = 1
    shell.team = team
}

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

    switch shell.category {
    case .BULLET:
        state.shape = Circle{ radius = shell.shape_radius }
	case .RAY:
        state.shape = Ray{}
	case .AOE:
        state.shape = Circle{ radius = shell.shape_radius }
	case .RADIAL:
        state.shape = Circle{ radius = shell.shape_radius }
	case .LINE:
        state.shape = Line{ length = shell.shape_length }
	case .TRACKING_ARROW:
        state.shape = Tracking_Line{ length = shell.shape_length, turn_speed = shell.shape_turn_speed }
    }

    #partial switch &s in state.shape {
    case Tracking_Line:
        projectile_Shape_tracking_line_init(&state, &s)
    }

    return
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

projectile_state_update :: proc(state: ^Projectile_State, index: uint) {
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