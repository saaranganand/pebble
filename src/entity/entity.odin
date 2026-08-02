package entity

import sdl "vendor:sdl3"

import animation "../data_load/animation"
import primatives "src:sdl_primatives"
import camera "src:camera"
import handle "../handle"
import data_load "src:data_load"

import log "core:log"

Entity_Handle :: handle.Entity_Handle

Force :: struct {
    direction: sdl.FPoint,
    force: f32,
    decay_rate: f32,
}

Team :: enum { ALLY, NEUTRAL, ENEMY }
Category :: enum { PLAYER, BULLET, NPC, VIP }

Entity :: struct {
    own_handle: handle.Entity_Handle,
    position: sdl.FPoint,
    col_radius: f32,
    move_direction: sdl.FPoint,
    base_move_speed, move_speed: f32,
    health: f32,
    max_health: f32,
    forces: [dynamic]Force,
    active: bool,
    animation_controller: animation.Animation_Controller,

    team: Team,
    category: Category,
}

// Is used to allow outside sources to create an entity
entity_make_data :: proc(
    position: sdl.FPoint, base_move_speed, max_health: f32, col_radius: f32, team: Team, category: Category,
    animation_source_tag: string
) -> (data: Entity) {
    data.position = position
    data.move_direction = {0.0,0.0}
    data.base_move_speed = base_move_speed
    data.move_speed = base_move_speed
    data.col_radius = col_radius
    data.health = max_health
    data.max_health = max_health
    data.active = true

    data.team = team
    data.category = category

    data.animation_controller = animation.animation_controller_create(animation_source_tag)

    return
}

// Is only used for entity manager adding entity into pool
@(private)
entity_create :: proc(entity: ^Entity) {
    entity.forces = make([dynamic]Force)
}

@(private)
entity_destroy :: proc(entity: ^Entity) {
    delete(entity.forces)
    entity.active = false
}

entity_deal_damage :: proc(entity: ^Entity, damage: f32) {
    // TODO
    entity.health -= damage
}

entity_set_animation :: proc(entity: ^Entity, new_animation: string) {
    entity.animation_controller.current_animation = new_animation
}

entity_update :: proc(entity: ^Entity) {
    if !entity.active do return
    entity.position += entity.move_direction * entity.move_speed * primatives.dt

    entity.move_speed = entity.base_move_speed

    if entity.health <= 0 {
        entity_manager_remove_entity(entity.own_handle, entity.team)
        entity.active = false
    }
}

entity_draw :: proc(entity: ^Entity) {
    if !entity.active do return
    camera.camera_draw_animation(&entity.animation_controller, entity.position)
}
