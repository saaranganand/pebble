package projectile

import sdl "vendor:sdl3"

import camera "src:camera"
import geo "src:geometry"

import math "core:math"

draw_proc :: proc(state: ^State)

@(rodata)
draw_procs := #partial [Category]draw_proc{
    .BULLET         = default_draw,
    .RAY            = ray_draw,
	.AOE            = default_draw,
	.RADIAL         = default_draw,
	.LINE           = default_line_draw
}

default_draw :: proc(state: ^State) {
    camera.camera_draw_animation(&state.animation_controller, state.position)
}

ray_draw :: proc(state: ^State) {
    start_pos := state.position
    camera_bounds: sdl.FRect = {
        camera.global_camera.position.x - camera.global_camera.width / 2.0,
        camera.global_camera.position.y - camera.global_camera.height / 2.0,
        camera.global_camera.width,
        camera.global_camera.height
    }

    end_pos := geo.line_rect_intersection(start_pos, state.shoot_angle, camera_bounds)

    dir := sdl.FPoint{math.cos(state.shoot_angle), math.sin(state.shoot_angle)}

    step: f32 = 5.0
    total_dist := geo.get_point_distance(end_pos, start_pos)
    steps := int(total_dist / step)

    for i in 0..=steps {
        d := f32(i) * step
        draw_pos := start_pos + dir * d
        camera.camera_draw_animation(&state.animation_controller, draw_pos)
    }
}

default_line_draw :: proc(state: ^State) {
    camera.camera_draw_animation(&state.animation_controller, state.position, f64(state.shoot_angle))
}
