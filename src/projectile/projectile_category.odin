package projectile

import sdl "vendor:sdl3"

import primatives "../sdl_primatives"

import math "core:math"
import log "core:log"

// Bullets are the classic
// Ray is a position and a direction, and projects endlessly/to the edge of the view. Like a gun in a shooter.
// AOE is a circle that has collision within it.
// Radial is a circle that only has collision on its outline
// Line has a position, a direction, and a length.
Category :: enum { BULLET, RAY, AOE, RADIAL, LINE }

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

}