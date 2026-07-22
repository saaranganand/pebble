package entity

import sdl "vendor:sdl3"

import handle "../handle"
import assets "../assets"

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
    position: sdl.FPoint,
    move_velocity: sdl.FPoint,
    base_move_speed, move_speed: f32,
    health: f32,
    max_health: f32,
    forces: [dynamic]Force,
    active: bool,
    animation_controller: assets.Animation_Controller,

    team: Team,
    category: Category,
}

// Is used to allow outside sources to create an entity
entity_make_data :: proc(
    position: sdl.FPoint, base_move_speed, max_health: f32, team: Team, category: Category,
    animation_source_tag: assets.Data_Tag
) -> (data: Entity) {
    data.position = position
    data.move_velocity = {0.0,0.0}
    data.base_move_speed = base_move_speed
    data.move_speed = base_move_speed
    data.health = max_health
    data.max_health = max_health
    data.active = true

    data.team = team
    data.category = category

    data.animation_controller.data_tag = animation_source_tag
    data.animation_controller.current_animation = "idle"

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
