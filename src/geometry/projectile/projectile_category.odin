package projectile

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import camera "src:camera"
import entity "src:entity"
import geo "../../geometry"

import math "core:math"
import log "core:log"

// Bullets are the classic
// Ray is a position and a direction, and projects endlessly/to the edge of the view. Like a gun in a shooter.
// AOE is a circle that has collision within it.
// Radial is a circle that only has collision on its outline
// Line has a position, a direction, and a length.
Category :: enum { BULLET, RAY, AOE, RADIAL, LINE, TRACKING_ARROW }

projectile_category_from_string :: proc(cat_str: string) -> Category {
    switch cat_str {
    case "BULLET":
        return .BULLET
    case "RAY":
        return .RAY
    case "AOE":
        return .AOE
    case "RADIAL":
        return .RADIAL
    case "LINE":
        return .LINE
    case "TRACKING_ARROW":
        return .TRACKING_ARROW
    }

    log.errorf("Passed projectile category from string did not match any expected result for enum")
    log.panic("Check data/weapon/ or data/projectile/ *.yaml for 'category' values")
}

projectile_category_bullet_update :: proc(state: ^Projectile_State, shape: Circle) {
    direction := sdl.FPoint{
        math.cos(state.shoot_angle),
        math.sin(state.shoot_angle),
    }
    state.position += direction * state.speed * primatives.dt
}

projectile_category_ray_update :: proc(state: ^Projectile_State, shape: Ray) {

}
projectile_category_aoe_update :: proc(state: ^Projectile_State, shape: Circle) {

}
projectile_category_radial_update :: proc(state: ^Projectile_State, shape: Circle) {

}
projectile_category_line_update :: proc(state: ^Projectile_State, shape: Line) {
    direction := sdl.FPoint{
        math.cos(state.shoot_angle),
        math.sin(state.shoot_angle),
    }
    state.position += direction * state.speed * primatives.dt
}

projectile_category_tracking_arrow_update :: proc(state: ^Projectile_State, shape: Tracking_Line) {
    direction: sdl.FPoint

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

    //diff := state.shoot_angle - target_angle
    //diff = math.mod(diff + math.PI, 2 * math.PI) - math.PI

    max_step := shape.turn_speed * primatives.dt

    if abs(diff) > max_step {
        state.shoot_angle += max_step * math.sign(diff)
    }
}


projectile_category_bullet_draw :: proc(state: ^Projectile_State, shape: Circle) {
    camera.camera_draw_animation(&state.animation_controller, state.position)
}
projectile_category_ray_draw :: proc(state: ^Projectile_State, shape: Ray) {
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
projectile_category_aoe_draw :: proc(state: ^Projectile_State, shape: Circle) {

}
projectile_category_radial_draw :: proc(state: ^Projectile_State, shape: Circle) {

}
projectile_category_line_draw :: proc(state: ^Projectile_State, shape: Line) {
    camera.camera_draw_animation(&state.animation_controller, state.position, f64(state.shoot_angle))
}

projectile_category_tracking_arrow_draw :: proc(state: ^Projectile_State, shape: Tracking_Line) {
    camera.camera_draw_animation(&state.animation_controller, state.position, f64(state.shoot_angle))
}