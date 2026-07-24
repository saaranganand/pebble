package dep_horde

import sdl "vendor:sdl3"

import primatives "../../sdl_primatives"
import geo "../../geometry"

Horde_Entity_Type :: enum { LEADER, FOLLOWER }

Horde_Entity :: struct {
    health: f32,
    ticket: int,
    type: Horde_Entity_Type,
}

@(private)
entity_init :: proc(type: Horde_Entity_Type = .FOLLOWER) -> (entity: Horde_Entity) {
    entity.type = type

    if type == .LEADER {
        entity.health = config.leader.health
    }
    else {
        entity.health = config.follower.health
    }
    
    return
}

@(private)
entity_give_ticket :: proc(entity: ^Horde_Entity, ticket: int) {
    entity.ticket = ticket
}

@(private)
entity_take_damage :: proc(entity: ^Horde_Entity, damage: f32) {
    entity.health -= damage
}

@(private)
entity_move :: proc(entity: ^Horde_Entity, collider: ^geo.Circle, direction: sdl.FPoint) {
    speed := config.leader.speed
    if entity.type == .FOLLOWER {
        speed = config.follower.speed
    }
    
    collider.position += direction * speed * primatives.dt
}

// both checks for damage collision, and carries out damage
@(private)
entity_handle_collision :: proc(entity: ^Horde_Entity, collider: geo.Circle, ally_damage_areas: ^[dynamic]geo.Circle) -> (died: bool) {
    for ally_area in ally_damage_areas {
        if geo.are_circles_colliding(collider, ally_area) {
            // TODO: Ensure that incoming data is not just circles,
            // but a data wrapper containing the circle, damage, and hit effects.
            // Apply the hit effect
            entity_take_damage(entity, 1)

            // TODO: while we register the death here,
            // there will likely be other tasks to do,
            // like compiling a datalist of kill drops and returning it to the main package,
            // or playing death sound/animation, etc.
            if entity.health < 0 do return true
        }
    }

    return false
}