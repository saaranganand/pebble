package projectile

import sdl "vendor:sdl3"

import geo "src:geometry"

projectile_collision_proc :: proc(state: Projectile_State, colliding_circle: geo.Circle) -> bool

@(rodata)
projectile_collision_procs := [Category]projectile_collision_proc{
    .BULLET         = default_circle_collision,
    .RAY            = default_line_collision,
	.AOE            = default_circle_collision,
	.RADIAL         = default_circle_collision,
	.LINE           = default_line_segment_collision,
	.TRACKING_ARROW = tracking_line_collision,
}

default_circle_collision :: proc(state: Projectile_State, circle: geo.Circle) -> bool {
    shape := state.shape.(Circle)
    return geo.are_circles_colliding({state.position, shape.radius}, circle)
}

default_line_collision :: proc(state: Projectile_State, circle: geo.Circle) -> bool {
    return geo.line_circle_colliding(state.position, state.shoot_angle, circle)
}

default_line_segment_collision :: proc(state: Projectile_State, circle: geo.Circle) -> bool {
    shape := state.shape.(Line)
    return geo.line_angle_segment_circle_colliding(state.position, shape.length, state.shoot_angle, circle)
}

tracking_line_collision :: proc(state: Projectile_State, circle: geo.Circle) -> bool {
    shape := state.shape.(Tracking_Line)
    return geo.line_angle_segment_circle_colliding(state.position, shape.length, state.shoot_angle, circle)
}