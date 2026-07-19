package entity

import sdl "vendor:sdl3"

import handle "../handle"

import log "core:log"

Entity_Handle :: handle.Entity_Handle

Entity_Force :: struct {
    direction: sdl.FPoint,
    force: f32,
    decay_rate: f32,
}

Entity_Team :: enum { ALLY, NEUTRAL, ENEMY }
Entity_Category :: enum { PLAYER, BULLET, NPC, VIP }

Entity :: struct {
    position: sdl.FPoint,
    move_velocity: sdl.FPoint,
    base_move_speed, move_speed: f32,
    health: f32,
    max_health: f32,
    forces: [dynamic]Entity_Force,

    team: Entity_Team,
    category: Entity_Category,
}

// Is used to allow outside sources to create and entity
entity_make_data :: proc(
    position: sdl.FPoint, base_move_speed, max_health: f32, team: Entity_Team, category: Entity_Category
) -> (data: Entity) {
    data.position = position
    data.move_velocity = {0.0,0.0}
    data.base_move_speed = base_move_speed
    data.move_speed = base_move_speed
    data.health = max_health
    data.max_health = max_health

    data.team = team
    data.category = category

    return
}

// Is only used for entity manager adding entity into pool
@(private)
entity_create :: proc(entity: ^Entity) {
    entity.forces = make([dynamic]Entity_Force)
}

@(private)
entity_destroy :: proc(entity: ^Entity) {
    delete(entity.forces)
}

entity_deal_damage :: proc(entity: ^Entity, damage: f32) {
    // TODO
    entity.health -= damage
}
