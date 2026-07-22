package projectile

import sdl "vendor:sdl3"

import primatives "../sdl_primatives"
import effect "../entity_effect"
import camera "../camera"
import entity "../entity"
import assets "../assets"

import log "core:log"

Projectile_State :: struct {
    position: sdl.FPoint,
    shape: Shape,
    category: Category,
    speed: f32,
    piercing: int, // Determines how many times a fired projectile can register a hit before it is destroyed, 0 means ad infinitum
    damage: f32,
    lifetime: f32,
    shoot_angle: f32,
    team: entity.Team,
    apply_effect: Maybe(effect.Effect_Instance_Tag),
    animation_controller: assets.Animation_Controller,
    active: bool,
}

projectile_state_init :: proc(state: ^Projectile_State, position: sdl.FPoint, shoot_angle: f32, damage: f32) {
    state.active = true
    state.position = position
    state.damage = damage
    state.shoot_angle = shoot_angle
    state.animation_controller.current_animation = "idle"
} 

projectile_state_update :: proc(state: ^Projectile_State, index: u32) {
    if !state.active do return
    defer state.lifetime -= primatives.dt

    if state.lifetime <= 0 do projectile_manager_remove(index, state.team, state.category)

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
    }
}

projectile_state_draw :: proc(state: ^Projectile_State) {
    if !state.active do return
    camera.camera_draw_animation(&state.animation_controller, state.position)
}