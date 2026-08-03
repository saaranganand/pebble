package projectile

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import camera "src:camera"
import entity "src:entity"
import geo "src:geometry"

import math "core:math"

projectile_update_proc :: proc(state: ^Projectile_State)

@(rodata)
projectile_update_procs := [Category]projectile_update_proc{
    .BULLET         = default_update,
    .RAY            = default_update,
	.AOE            = default_update,
	.RADIAL         = default_update,
	.LINE           = default_update,
	.TRACKING_ARROW = tracking_arrow_update,
}

default_update :: proc(state: ^Projectile_State) {
    direction := sdl.FPoint{
        math.cos(state.shoot_angle),
        math.sin(state.shoot_angle),
    }
    state.position += direction * state.speed * primatives.dt
}

tracking_arrow_update :: proc(state: ^Projectile_State) {
    direction: sdl.FPoint

    shape := state.shape.(Tracking_Line)

    defer state.position += direction * state.speed * primatives.dt

    defer direction = sdl.FPoint{
        math.cos(state.shoot_angle),
        math.sin(state.shoot_angle),
    }

    target_entity, target_ok := entity.entity_get(shape.tracking, shape.tracking_team)
    if !target_ok do return

    to_target := target_entity.position - state.position
    target_angle := math.atan2(to_target.y, to_target.x)

    diff := math.atan2(math.sin(target_angle - state.shoot_angle), math.cos(target_angle - state.shoot_angle))

    max_step := shape.turn_speed * primatives.dt

    if abs(diff) > max_step {
        state.shoot_angle += max_step * math.sign(diff)
    }
}