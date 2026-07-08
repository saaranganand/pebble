package horde
import sdl "vendor:sdl3"
import math "core:math"
import rand "core:math/rand"
import log "core:log"

import primatives "../../sdl_primatives"
import geo "../../geometry"

FOLLOWER_SIZE :: 16
FOLLOWER_SPEED :: 10

FOLLOWER_STARTING_HEALTH :: 3

@(private)
follower_create :: proc(registry: ^Follower_Registry, follower_position: sdl.FPoint, follower_leader: Leader_Handle) -> Follower_Handle {
    new_follower := entity_init(.FOLLOWER)
    new_follower_ticket := Follower_Ticket{
        data = new_follower,
        generation = 0,
        alive = true,

        state = .Following,
        leader = follower_leader,
    }
    new_follower_collider := geo.Circle{ follower_position, FOLLOWER_SIZE }
    
    // If the array is full, append the new follower
    if len(registry.free_list) == 0 {
        entity_give_ticket(&new_follower_ticket.data, len(registry.tickets))
        append(&registry.tickets, new_follower_ticket)

        // create its collider
        append(&registry.colliders, new_follower_collider)

        return Follower_Handle{ new_follower_ticket.data.ticket, 0 }
    }

    // Otherwise, find a vacant spot and update the generation
    insert := pop(&registry.free_list)
    entity_give_ticket(&new_follower_ticket.data, insert)
    
    new_follower_ticket.generation = registry.tickets[insert].generation + 1

    registry.tickets[insert] = new_follower_ticket
    registry.colliders[insert] = new_follower_collider

    return Follower_Handle{ insert, new_follower_ticket.generation }
}

@(private)
follower_register_death :: proc(follower: ^Follower_Ticket, free_list: ^[dynamic]int, follower_index: int) {
    follower.alive = false
    append(free_list, follower_index)
}

@(private)
follower_pathfind :: proc(horde: ^Horde, follower: ^Follower_Ticket, collider: geo.Circle, leader_colliders: ^[dynamic]geo.Circle) -> (move_direction: sdl.FPoint){
    if follower.state == .Wander {
        // TODO: implement random wandering
        return { 1, 0 }
    }

    leader, ok := leader_resolve_handle(horde, follower.leader)
    if !ok {
        log.errorf("Horde follower trying to access invalid horde leader")
        debug_log(horde)
        return {}
    }
    leader_collider := leader_colliders[leader.ticket]

    return geo.normalize_point(leader_collider.position - collider.position)
}