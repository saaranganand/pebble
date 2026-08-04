package camera

import sdl "vendor:sdl3"
import sdl_ttf "vendor:sdl3/ttf"

import math "core:math"
import log "core:log"
import fmt "core:fmt"

import animation "src:data_load/animation"
import primatives "src:sdl_primatives"
import img "src:data_load/img"
import font "src:data_load/font"
import color "src:util/color"
import geo "src:geometry"

Camera_Mode :: enum { STATIONARY, FOLLOW }

// NOTE: if the target is set to a position belonging to something in a dynamic array,
// the memory could get moved around. This probably isnt a problem thanks to solo player + xar, but still
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

    coordinate_text: ^sdl_ttf.Text,
}

// The way this package's procedures work,
// they all use the global camera and have no option to pass in other cameras.
// If one wants to have multiple cameras for some reason,
// my reccomendation is to use the camera_create procedure, which does not assume
// global camera, and store the extra cameras where they please.
// Then, when deciding which camera is active, set global camera to the data of the stored camera.
// This works for all cases assuming there is only one camera being using for rendering.
// I dont know why there would be more, but in such a case, things would have to be reworked to avoid tedious switching back and forth.
global_camera: ^Camera

global_camera_create :: proc(width, height: f32) {
    global_camera = create(width, height)
}

global_camera_destroy :: proc() {
    destroy(global_camera)
}

create :: proc(width, height: f32) -> (camera: ^Camera) {
    log.infof("Allocating new camera")
    camera = new(Camera)

    camera.position = {0,0}
    camera.width = width
    camera.height = height
    camera.mode = .STATIONARY

    camera.coordinate_text = font.font_create_text("ubuntu", 24, "0,0")
    color.sdl_set_text_color(camera.coordinate_text, color.Default_Palette_Color.BLACK)

	return
}

destroy :: proc(camera: ^Camera) {
    log.infof("Destroying camera")

    sdl_ttf.DestroyText(camera.coordinate_text)
    free(camera)
}

set_follow :: proc(target: ^sdl.FPoint, lerp_speed: f32) {
    global_camera.mode = .FOLLOW
    global_camera.follow = {target, lerp_speed}
}

set_stationary :: proc(target: ^sdl.FPoint, lerp_speed: f32) {
    global_camera.mode = .STATIONARY
}

update :: proc() {
    if global_camera.mode == .STATIONARY do return

    if global_camera.follow.target != nil {
        // lerp camera position toward target
        target := global_camera.follow.target^
        global_camera.position += (target - global_camera.position) * global_camera.follow.lerp_speed

        // if we are within a pixel of the target, set position to the target
        if math.trunc(global_camera.position.x - target.x) == 0 do global_camera.position.x = target.x
        if math.trunc(global_camera.position.y - target.y) == 0 do global_camera.position.y = target.y
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
check_circle_visible :: proc(circle: geo.Circle) -> (visible: bool) {
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

draw_circle :: proc(circle: geo.Circle) {
    view_adjusted_circle := geo.Circle{ world_position_to_view(circle.position), circle.radius }
    geo.draw_circle(view_adjusted_circle)
}

fill_circle :: proc(circle: geo.Circle) {
    view_adjusted_circle := geo.Circle{ world_position_to_view(circle.position), circle.radius }

    geo.fill_circle(view_adjusted_circle)
}

draw_center_lines :: proc() {
    color.sdl_set_color(color.Default_Palette_Color.GRASS_GREEN)

    sdl.RenderLine(primatives.global_renderer, 0, global_camera.height / 2, global_camera.width, global_camera.height / 2)
    sdl.RenderLine(primatives.global_renderer, global_camera.width / 2, 0, global_camera.width / 2, global_camera.height)
}

draw_img :: proc(
    img_tag: string, dest: sdl.FRect, src: ^sdl.FRect = nil,
    angle: f64 = 0, flip_mode: sdl.FlipMode = .NONE, center: ^sdl.FPoint = nil
) {
    view_adjusted_pos := world_position_to_view({ dest.x, dest.y })
    view_adjusted_dest := dest

    view_adjusted_dest.x = view_adjusted_pos.x
    view_adjusted_dest.y = view_adjusted_pos.y

    img.img_draw(img_tag, &view_adjusted_dest, src, angle, flip_mode, center)
}

draw_animation :: proc(
    animation_controller: ^animation.Animation_Controller,
    dest_center: sdl.FPoint,
    angle: f64 = 0, flip_mode: sdl.FlipMode = .NONE, center: ^sdl.FPoint = nil
) {
    view_adjusted_pos := world_position_to_view(dest_center)
    animation.animation_draw(animation_controller, view_adjusted_pos, angle, flip_mode, center)
}

draw_grid :: proc() {
    color.sdl_set_color(color.Default_Palette_Color.BLACK)

    // Calculate camera world bounds
    half_width := global_camera.width / 2.0
    half_height := global_camera.height / 2.0
    
    min_world_position := global_camera.position - sdl.FPoint{ half_width, half_height }
    max_world_position := global_camera.position + sdl.FPoint{ half_width, half_height }
    GRID_SIZE :: 500.0
    
    // Draw vertical lines
    start_grid_x := math.floor(min_world_position.x / GRID_SIZE) * GRID_SIZE
    for grid_x := start_grid_x; grid_x <= max_world_position.x; grid_x += GRID_SIZE {
        view_x := world_position_to_view(sdl.FPoint{grid_x, 0}).x
        
        p1 := sdl.FPoint{view_x, 0}
        p2 := sdl.FPoint{view_x, global_camera.height}
        sdl.RenderLine(primatives.global_renderer, p1.x, p1.y, p2.x, p2.y)
    }
    
    // Draw horizontal lines
    start_grid_y := math.floor(min_world_position.y / GRID_SIZE) * GRID_SIZE

    for grid_y := start_grid_y; grid_y <= max_world_position.y; grid_y += GRID_SIZE {
        view_y := world_position_to_view(sdl.FPoint{0, grid_y}).y
        
        p1 := sdl.FPoint{0, view_y}
        p2 := sdl.FPoint{global_camera.width, view_y}
        sdl.RenderLine(primatives.global_renderer, p1.x, p1.y, p2.x, p2.y)
    }

    LABEL_MARGIN :: 100.0
    
    // Draw grid labels at intersections
    grid_x := start_grid_x
    for grid_x <= max_world_position.x {
        grid_y := start_grid_y
        for grid_y <= max_world_position.y {
            world_pos := sdl.FPoint{grid_x, grid_y}
            view_pos := world_position_to_view(world_pos)
            
            // Draw if visible with margin
            if view_pos.x >= -LABEL_MARGIN && view_pos.x < global_camera.width + LABEL_MARGIN &&
               view_pos.y >= -LABEL_MARGIN && view_pos.y < global_camera.height + LABEL_MARGIN {
                draw_grid_label(int(grid_x), int(grid_y), view_pos)
            }
            
            grid_y += GRID_SIZE
        }
        grid_x += GRID_SIZE
    }
}

draw_grid_label :: proc(world_x, world_y: int, view_pos: sdl.FPoint) {
    label := fmt.caprint(world_x, ",", world_y, sep = "")
    defer delete(label)

    sdl_ttf.SetTextString(global_camera.coordinate_text, label, 0)
    sdl_ttf.DrawRendererText(global_camera.coordinate_text, view_pos.x + 5, view_pos.y + 5)
}