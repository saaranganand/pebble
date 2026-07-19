package horde
import sdl "vendor:sdl3"
import math "core:math"
import rand "core:math/rand"
import log "core:log"

import geo "../../geometry"
import color "../../color"

// The horde is a group of enemies, each enemy being either a leader or a follower (both entities)
// Leaders are smart and pathfind towards the player,
// while followers are dumb and either follow their leader, if its alive, or move randomly.

// This system uses a handle / ticket system.
// Handles are for outside references. Because we are storing in dynamic arrays, pointers will
// go bad when the array is resized, and moved to a different area in memory.
// The entity data is wrapped in a ticket. The ticket does a few things.
// It checks that the handle generation and entity generation match.
// It also stores whether or not the entity is dead, which is for iteraction skipping.

// Honestly, this has a lot of potential for optimization.
// The first would be to expand the ticket system.
// Instead of leaving dead entities in the data array and skipping them on iteration,
// entities are removed on death, using unordered remove.
// This messes with the handles, but can be solved with two arrays:
// tickets is a dynamic array of tickets. It is what handles point to, and tickets themselves point to assets.
// The next is an array that shadows data, and acts as a reverse lookup table. It answers: whats the index into the ticket array
// for the ticket that points to entity at index i? The array at index i holds an index j, which is the ticket.
// This would be used to find the ticket that needs to be updated when entity a dies, and is replaced with entity b at the end of the array --
// the ticket of b needs to be accessed to change its data index to where a was.
// I actually had this system up and running, but it was needless because, on its own, I dont think it matters much.

// I would consider adding it again if (when) I remodel the horde to use SoA (struct of arrays) instead of AoS.
// This way is much better for cache hits, and would give actual results if we were spawning tens of thousands of entities.
// I dont think we will however, and so I leave this task for me at a later date, if it does end up happening.
Horde :: struct {
    leader_registry: Leader_Registry,
    
    follower_registry: Follower_Registry,

    target: ^sdl.FPoint,
}

debug_log :: proc(horde: ^Horde) {
    log.infof("------------------------ HORDE INFO ------------------------")
    log.infof("target: %v", horde.target^)

    total_num := 0
    total_num += leader_registry_debug_log(&horde.leader_registry)
    total_num += follower_registry_debug_log(&horde.follower_registry)

    log.infof("Total num. enemies: %v", total_num)
}

create :: proc(horde_target: ^sdl.FPoint) -> (horde: Horde) {
    horde.target = horde_target

    horde.leader_registry = leader_registry_create()
    horde.follower_registry = follower_registry_create()

    log.infof("Allocated Horde")

    return
}

destroy :: proc(horde: ^Horde) {
    leader_registry_destroy(&horde.leader_registry)
    follower_registry_destroy(&horde.follower_registry)

    log.infof("Destroyed Horde")
}

resolve_handle :: proc {
    leader_resolve_handle,
    follower_resolve_handle,
}

draw :: proc(horde: ^Horde) {
    // Leader color
    color.sdl_set_color(color.Default_Palette_Color.RED)
    leader_registry_draw(&horde.leader_registry)
    
    // Follower color
    color.sdl_set_color(color.Default_Palette_Color.PINK)
    follower_registry_draw(&horde.follower_registry)
}

update :: proc(horde: ^Horde, ally_damage_areas: ^[dynamic]geo.Circle) {    
    leaders := &horde.leader_registry.tickets
    leader_index := 0
    for &leader in leaders {
        defer leader_index += 1
        if !leader.alive do continue

        leader_collider := &horde.leader_registry.colliders[leader_index]

        leader_died := entity_handle_collision(&leader.data, leader_collider^, ally_damage_areas)
        if leader_died {
            leader_followers := &horde.leader_registry.followers_of[leader_index]
            leader_register_death(horde, &leader, leader_followers, &horde.leader_registry.free_list, leader_index)
        }

        move_direction := leader_pathfind(&leader.data, horde.target^, leader_collider^)
        entity_move(&leader.data, leader_collider, move_direction)
    }

    followers := &horde.follower_registry.tickets
    follower_index := 0
    for &follower in followers {
        defer follower_index += 1
        if !follower.alive do continue

        follower_collider := &horde.follower_registry.colliders[follower_index]

        follower_died := entity_handle_collision(&follower.data, follower_collider^, ally_damage_areas)
        if follower_died do follower_register_death(&follower, &horde.follower_registry.free_list, follower_index)

        move_direction := follower_pathfind(horde, &follower, follower_collider^, &horde.leader_registry.colliders)
        entity_move(&follower.data, follower_collider, move_direction)
    }
}
