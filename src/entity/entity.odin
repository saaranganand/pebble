package entity

import sdl "vendor:sdl3"

import primatives "../sdl_primatives"
import camera "../camera"
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
Entity_Stat :: enum { MAX_HEALTH, DAMAGE_TAKEN, MOVE_SPEED }
Entity_Stat_Mults :: [Entity_Stat]f32
ENTITY_STAT_MULTS_IDENTITY :: Entity_Stat_Mults {
    .MAX_HEALTH = 1.0,
    .DAMAGE_TAKEN = 1.0,
    .MOVE_SPEED = 1.0
}

Entity :: struct {
    own_handle: handle.Entity_Handle,
    position: sdl.FPoint,
    col_radius: f32,
    move_direction: sdl.FPoint,
    base_move_speed, move_speed: f32,
    health: f32,
    base_max_health, max_health: f32,
    move_speed_mult: f32,
    damage_taken_mult: f32, // 1.0 = takes full dmg. A program like Firewall lowers this
    forces: [dynamic]Force,
    active: bool,
    animation_controller: assets.Animation_Controller,

    team: Team,
    category: Category,
}

// Is used to allow outside sources to create an entity
entity_make_data :: proc(
    position: sdl.FPoint, base_move_speed, max_health: f32, col_radius: f32, team: Team, category: Category,
    animation_source_tag: assets.Data_Tag
) -> (data: Entity) {
    data.position = position
    data.move_direction = {0.0,0.0}
    data.base_move_speed = base_move_speed
    data.move_speed = base_move_speed
    data.col_radius = col_radius
    data.health = max_health
    data.base_max_health = max_health
    data.max_health = max_health
    data.damage_taken_mult = 1.0
    data.move_speed_mult = 1.0
    data.active = true

    data.team = team
    data.category = category

    data.animation_controller.data_tag = animation_source_tag
    data.animation_controller.current_animation = "idle"

    return
}

entity_stat_from_string :: proc(stat_string: string) -> (stat: Entity_Stat) {
    switch stat_string {
        case "MAX_HEALTH":
            stat= .MAX_HEALTH
        case "DAMAGE_TAKEN":
            stat= .DAMAGE_TAKEN
        case "MOVE_SPEED":
            stat = .MOVE_SPEED
        case: 
            log.panicf("no entity stat parsable from string %v", stat_string)
    }
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
    entity.health -= damage * entity.damage_taken_mult
}

entity_heal :: proc(entity: ^Entity, amount: f32) {
    entity.health = min(entity.health + amount, entity.max_health)
}

entity_set_animation :: proc(entity: ^Entity, new_animation: assets.Animation_Tag) {
    entity.animation_controller.current_animation = new_animation
}

entity_update :: proc(entity: ^Entity) {
    if !entity.active do return
    entity.position += entity.move_direction * entity.move_speed * primatives.dt

    entity.move_speed = entity.base_move_speed * entity.move_speed_mult

    if entity.health <= 0 {
        entity_manager_remove_entity(entity.own_handle, entity.team)
        entity.active = false
    }
}

entity_draw :: proc(entity: ^Entity) {
    if !entity.active do return
    camera.camera_draw_animation(&entity.animation_controller, entity.position)
}
