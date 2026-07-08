package camera

import sdl "vendor:sdl3"

import math "core:math"
import log "core:log"

import geo "../geometry"

Camera_Mode :: enum { STATIONARY, FOLLOW }

Camera_Follow :: struct {
	target: ^sdl.FPoint,
    // A following camera lerps to target
	lerp_speed: f32,
}

Camera :: struct {
    // camera center
	position: sdl.FPoint,
	width:  f32,
	height: f32,
	mode:   Camera_Mode,
	follow: Camera_Follow,
}

// The way this package's procedures work,
// they all use the global camera and have no option to pass in other cameras.
// If one wants to have multiple cameras for some reason,
// my reccomendation is to use the camera_create procedure, which does not assume
// global camera, and store the extra cameras where they please.
// Then, when deciding which camera is active, set global camera to the data of the stored camera.
// This works for all cases assuming there is only one camera being using for rendering.
// I dont know why there would be more, but in such a case, things would have to be reworked to avoid tedious switching back and forth.
global_camera: Camera

global_camera_create :: proc(width, height: f32) {
    global_camera = camera_create(width, height)
}

camera_create :: proc(width, height: f32) -> (camera: Camera) {
    camera.position = {0,0}
    camera.width = width
    camera.height = height
    camera.mode = .STATIONARY

	return
}

camera_set_follow :: proc(target: ^sdl.FPoint, lerp_speed: f32) {
    global_camera.mode = .FOLLOW
    global_camera.follow = {target, lerp_speed}
}

camera_set_stationary :: proc(target: ^sdl.FPoint, lerp_speed: f32) {
    global_camera.mode = .STATIONARY
}

camera_update :: proc() {
    if global_camera.mode == .STATIONARY do return

    if global_camera.follow.target != nil {
        // lerp camera position toward target
        target := global_camera.follow.target^
        global_camera.position += (target - global_camera.position) * global_camera.follow.lerp_speed
    }
}

// View position is the position relative to the camera
world_position_to_view :: proc(world_position: sdl.FPoint) -> sdl.FPoint {
    return world_position - global_camera.position + sdl.FPoint{global_camera.width, global_camera.height} / 2.0
}

view_position_to_world :: proc(view_position: sdl.FPoint) -> sdl.FPoint {
    return view_position + global_camera.position - sdl.FPoint{global_camera.width, global_camera.height} / 2.0
}

// Used for culling
camera_check_circle_visible :: proc(circle: geo.Circle) -> (visible: bool) {
	// camera bounds in world space
	left   := global_camera.position.x - global_camera.width  / 2
	right  := global_camera.position.x + global_camera.width  / 2
	top    := global_camera.position.y - global_camera.height / 2
	bottom := global_camera.position.y + global_camera.height / 2
	
	// clamp circle center to camera bounds
    closest_position := sdl.FPoint{
        math.clamp(circle.position.x, left, right),
        math.clamp(circle.position.y, top, bottom)
    }

	// distance from circle center to closest point on bounds
    delta_to_bounds := circle.position - closest_position

	distance_squared := delta_to_bounds.x * delta_to_bounds.x + delta_to_bounds.y * delta_to_bounds.y
	
    // Regular distance would involve a square root
    // Instead we square both sides to avoid the costly operation
	visible = distance_squared <= math.pow(circle.radius, 2)

    return
}

camera_draw_circle :: proc(circle: geo.Circle) {
    view_adjusted_circle := geo.Circle{ world_position_to_view(circle.position), circle.radius }
    geo.draw_circle(view_adjusted_circle)
}

camera_fill_circle :: proc(circle: geo.Circle) {
    view_adjusted_circle := geo.Circle{ world_position_to_view(circle.position), circle.radius }

    geo.fill_circle(view_adjusted_circle)
}