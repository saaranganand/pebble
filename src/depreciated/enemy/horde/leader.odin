package dep_horde

import sdl "vendor:sdl3"
import math "core:math"
import rand "core:math/rand"
import log "core:log"

import primatives "../../sdl_primatives"
import geo "../../geometry"

@(private)
leader_create :: proc(registry: ^Leader_Registry, leader_position: sdl.FPoint, leader_target: ^sdl.FPoint) -> Leader_Handle {
    new_leader := entity_init(.LEADER)
    new_leader_ticket := Leader_Ticket{
        data = new_leader,
        generation = 0,
        alive = true,

        target = leader_target
    }
    new_leader_collider := geo.Circle{leader_position, config.leader.size}


    // If the array is full, append the new leader
    if len(registry.free_list) == 0 {
        entity_give_ticket(&new_leader_ticket.data, len(registry.tickets))
        append(&registry.tickets, new_leader_ticket)

        // Also need to append a spot for the leader's followers
        append(&registry.followers_of, make([dynamic]Follower_Handle))

        // create its collider
        append(&registry.colliders, new_leader_collider)

        return Leader_Handle{ new_leader_ticket.data.ticket, 0 }
    }

    // Otherwise, find a vacant spot and update the generation
    insert := pop(&registry.free_list)
    entity_give_ticket(&new_leader_ticket.data, insert)
    new_leader_ticket.generation = registry.tickets[insert].generation + 1

    registry.tickets[insert] = new_leader_ticket
    registry.colliders[insert] = new_leader_collider

    return Leader_Handle{ insert, new_leader_ticket.generation }
}

// Spawns a leader and its followers both
leader_spawn :: proc(horde: ^Horde, leader_position: sdl.FPoint) {
    leader_target := horde.target
    new_leader_handle := leader_create(&horde.leader_registry, leader_position, leader_target)

    leader_followers_of := &horde.leader_registry.followers_of[new_leader_handle.ticket]
    for i in 0..<config.followers_per_leader {
        new_follower_handle := follower_create(&horde.follower_registry, leader_position, new_leader_handle)
        
        append(leader_followers_of, new_follower_handle)
    }
}

@(private)
leader_register_death :: proc(horde: ^Horde, leader: ^Leader_Ticket, leader_followers: ^[dynamic]Follower_Handle, free_list: ^[dynamic]int, leader_index: int) {
    leader.alive = false
    append(free_list, leader_index)

    // Handle the leader's followers on death
    for follower_handle in leader_followers {
        // Change their state to stop them
        follower, ok := follower_resolve_handle(horde, follower_handle)
        if ok do follower.state = .Wander
    }
    clear(leader_followers)
}

@(private)
leader_pathfind :: proc(leader: ^Horde_Entity, target: sdl.FPoint, collider: geo.Circle, ) -> (move_direction: sdl.FPoint){
    // TODO: give a more complicated pathfinding algorithm, like A*
    return geo.normalize_point(target - collider.position)
}