package entity

import sdl "vendor:sdl3"

import animation "src:data_load/animation"
import primatives "src:sdl_primatives"
import camera "src:camera"
import color "src:util/color"
import handle "src:handle"
import geo "src:geometry"
import util "src:util"

import math "core:math"
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
Entity_Stat_Adds :: [Entity_Stat]f32
ENTITY_STAT_ADDS_ZERO :: Entity_Stat_Adds{}
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

    // how long this entity has been alive (for programs to refer)
    age: f32,

    // program: shell
    max_shield, shield: f32,
    shield_regen_delay: f32,
    time_since_shield_hit: f32,

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

// how much hp was actually removed
entity_deal_damage :: proc(entity: ^Entity, damage: f32) -> (dealt: f32) {
    // TODO
    taken := damage * entity.damage_taken_mult

    // shield absorbs first, and any it cant cover affects hp
    if entity.shield > 0 {
        entity.time_since_shield_hit = 0
        soaked := min(entity.shield, taken)
        entity.shield -= soaked
        taken -= soaked
    }

    entity.hp -= taken
    return taken
}

entity_heal :: proc(entity: ^Entity, amount: f32) {
    entity.hp = min(entity.hp + amount, entity.max_hp)
}

entity_set_animation :: proc(entity: ^Entity, new_animation: string) {
    entity.animation_controller.current_animation = new_animation
}

entity_update :: proc(entity: ^Entity) {
    if !entity.active do return

    entity.age += primatives.dt
    entity_update_shield(entity)

    entity.collision.position += entity.direction * entity.move_speed * primatives.dt

    // recomputed every frame, so a weapon or effect scaling move_speed only lasts the frame it set it
    entity.move_speed = entity.base_move_speed * entity.move_speed_mult

    if entity.hp <= 0 {
        entity_manager_remove_entity(entity.handle, entity.team)
        entity.active = false
    }
}

// shield regrows at once, but only after its gone untouched for long enough
@(private)
entity_update_shield :: proc(entity: ^Entity) {
    if entity.max_shield <= 0 do return
    if entity.shield >= entity.max_shield do return

    entity.time_since_shield_hit += primatives.dt

    // a shield with no delay set regenerates as soon as it stops being hit
    if entity.time_since_shield_hit >= entity.shield_regen_delay do entity.shield = entity.max_shield
}

entity_draw :: proc(entity: ^Entity) {
    if !entity.active do return
    
    camera.draw_animation(&entity.animation_controller, entity.collision.position)

    entity_draw_shield(entity)
}

// shield is a ring sitting just outside the entity. thickens as it absorbs dmg
@(private)
entity_draw_shield :: proc(entity: ^Entity) {
    if entity.shield <= 0 || entity.max_shield <= 0 do return

    SHIELD_RING_MARGIN :: 6.0
    SHIELD_RING_MAX_LAYERS :: 3

    // ring around the sprite
    base_radius := entity.collision.radius
    if width, height, ok := animation.animation_drawn_size(&entity.animation_controller); ok {
        base_radius = max(width, height) * 0.5
    }

    fraction := clamp(entity.shield / entity.max_shield, 0, 1)

    layers := int(math.ceil(fraction * SHIELD_RING_MAX_LAYERS))
    if layers < 1 do layers = 1

    color.sdl_set_color(color.Default_Palette_Color.SKY_BLUE)
    for i in 0..<layers {
        radius := base_radius + SHIELD_RING_MARGIN + f32(i)
        camera.draw_circle(geo.Circle{ entity.collision.position, radius })
    }
}
