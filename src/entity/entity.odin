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

// entity-wide stats a program is allowed to buff, mirroring weapon.Weapon_Stat
Entity_Stat :: enum { MAX_HEALTH, DAMAGE_TAKEN, MOVE_SPEED }
Entity_Stat_Mults :: [Entity_Stat]f32
ENTITY_STAT_MULTS_IDENTITY :: Entity_Stat_Mults {
    .MAX_HEALTH = 1.0,
    .DAMAGE_TAKEN = 1.0,
    .MOVE_SPEED = 1.0,
}

entity_stat_from_string :: proc(stat_string: string) -> (stat: Entity_Stat) {
    switch stat_string {
    case "MAX_HEALTH":
        stat = .MAX_HEALTH
    case "DAMAGE_TAKEN":
        stat = .DAMAGE_TAKEN
    case "MOVE_SPEED":
        stat = .MOVE_SPEED
    case:
        log.panicf("No entity stat parsable from string %v", stat_string)
    }
    return
}

Entity :: struct {
    active: bool,
    handle: util.Handle,
    collision: geo.Circle,
    animation_controller: animation.Animation_Controller,
    team: Team,
    category: Category,

    direction: sdl.FPoint,
    base_move_speed, move_speed: f32,
    base_max_hp, max_hp, hp: f32,

    // program buffs. 1.0 = unbuffed
    move_speed_mult: f32,
    damage_taken_mult: f32, // a program like Firewall lowers this
}

// Is used to allow outside sources to create an entity
entity_make_data :: proc(
    col_position: sdl.FPoint, base_move_speed, max_hp, col_radius: f32, team: Team, category: Category,
    animation_source_tag: string
) -> (entity: Entity) {
    entity.active = true
    entity.collision = geo.Circle{ position = col_position, radius = col_radius}
    entity.animation_controller = animation.animation_controller_create(animation_source_tag)
    entity.team = team
    entity.category = category

    entity.direction = {0.0,0.0}
    entity.base_move_speed = base_move_speed
    entity.move_speed = base_move_speed
    entity.base_max_hp = max_hp
    entity.max_hp = max_hp
    entity.hp = max_hp

    entity.move_speed_mult = 1.0
    entity.damage_taken_mult = 1.0

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
    entity.active = false
}

entity_deal_damage :: proc(entity: ^Entity, damage: f32) {
    // TODO
    entity.hp -= damage * entity.damage_taken_mult
}

entity_heal :: proc(entity: ^Entity, amount: f32) {
    entity.hp = min(entity.hp + amount, entity.max_hp)
}

entity_set_animation :: proc(entity: ^Entity, new_animation: string) {
    entity.animation_controller.current_animation = new_animation
}

entity_update :: proc(entity: ^Entity) {
    if !entity.active do return
    entity.collision.position += entity.direction * entity.move_speed * primatives.dt

    // recomputed every frame, so a weapon or effect scaling move_speed only lasts the frame it set it
    entity.move_speed = entity.base_move_speed * entity.move_speed_mult

    if entity.hp <= 0 {
        entity_manager_remove_entity(entity.handle, entity.team)
        entity.active = false
    }
}

entity_draw :: proc(entity: ^Entity) {
    if !entity.active do return
    
    camera.draw_animation(&entity.animation_controller, entity.collision.position)
}
