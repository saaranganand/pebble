package entity

import sdl "vendor:sdl3"

import animation "src:data_load/animation"
import primatives "src:sdl_primatives"
import camera "src:camera"
import handle "src:handle"
import geo "src:geometry"
import util "src:util"

import log "core:log"

Force :: struct {
    direction: sdl.FPoint,
    force: f32,
    decay_rate: f32,
}

Team :: enum { ALLY, NEUTRAL, ENEMY }
Category :: enum { PLAYER, BULLET, NPC, VIP }

Entity :: struct {
    handle: util.Handle,
    collision: geo.Circle,
    animation_controller: animation.Animation_Controller,
    team: Team,
    category: Category,

    direction: sdl.FPoint,
    base_move_speed, move_speed: f32,
    max_hp, hp: f32,
}

// Is used to allow outside sources to create an entity
entity_make_data :: proc(
    col_position: sdl.FPoint, base_move_speed, max_hp, col_radius: f32, team: Team, category: Category,
    animation_source_tag: string
) -> (entity: Entity) {
    entity.collision = geo.Circle{ position = col_position, radius = col_radius}
    entity.animation_controller = animation.animation_controller_create(animation_source_tag)
    entity.team = team
    entity.category = category

    entity.direction = {0.0,0.0}
    entity.base_move_speed = base_move_speed
    entity.move_speed = base_move_speed
    entity.max_hp = max_hp
    entity.hp = max_hp

    return
}

// Is only used for entity manager adding entity into pool
@(private)
entity_create :: proc(entity: ^Entity) {
    //entity.forces = make([dynamic]Force)
}

@(private)
entity_destroy :: proc(entity: ^Entity) {
    //delete(entity.forces)
}

entity_deal_damage :: proc(entity: ^Entity, damage: f32) {
    // TODO
    entity.hp -= damage
}

entity_set_animation :: proc(entity: ^Entity, new_animation: string) {
    entity.animation_controller.current_animation = new_animation
}

entity_update :: proc(entity: ^Entity) {
    entity.collision.position += entity.direction * entity.move_speed * primatives.dt

    entity.move_speed = entity.base_move_speed

    if entity.hp <= 0 {
        entity_manager_remove_entity(entity.handle, entity.team)
    }
}

entity_draw :: proc(entity: ^Entity) {    
    camera.draw_animation(&entity.animation_controller, entity.collision.position)
}
