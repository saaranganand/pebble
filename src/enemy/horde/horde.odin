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
// tickets is a dynamic array of tickets. It is what handles point to, and tickets themselves point to data.
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

    // This is an array meant to be exported.
    // Every frame it is updated with the latest positions of the horde enemies.
    // TODO: re-evaluate this damage area setup
    // every frame we are clearing and then repopulating the array with every hitbox in the horde
    // this is definitely inefficient
    // Theres a few better ways to do this
    // Instead of recompiling this every frame, why not just have this array own all the actual data.
    // We could use one for leaders and one for followers,
    // and have it be one-one for leaders and their hitboxes.
    // On update, horde members update the actual circle in this array.
    // If we want to add bullets, we just create another array,
    // and then send all back discretely rather than together.
    damage_areas: [dynamic]geo.Circle,
}

debug_log :: proc(horde: ^Horde) {
    log.infof("------------------------ HORDE INFO ------------------------")
    log.infof("Num. damage areas: %v", len(horde.damage_areas))
    log.infof("target: %v", horde.target^)

    leader_registry_debug_log(&horde.leader_registry)
    follower_registry_debug_log(&horde.follower_registry)
}

create :: proc(horde_target: ^sdl.FPoint) -> (horde: Horde) {
    horde.damage_areas = make([dynamic]geo.Circle)
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

    delete(horde.damage_areas)
}

resolve_handle :: proc {
    leader_resolve_handle,
    follower_resolve_handle,
}

draw :: proc(horde: ^Horde) {
    color.sdl_set_color(color.Default_Palette_Colors.RED)
    for circle in horde.damage_areas do geo.fill_circle(circle)
}

update :: proc(horde: ^Horde, ally_damage_areas: ^[dynamic]geo.Circle) {
    clear(&horde.damage_areas)
    
    leaders := &horde.leader_registry.tickets
    leader_index := 0
    for &leader in leaders {
        defer leader_index += 1
        if !leader.alive do continue

        leader_died := leader_handle_collision(&leader.data, ally_damage_areas)
        if leader_died {
            leader_followers := &horde.leader_registry.followers_of[leader_index]
            leader_register_death(horde, &leader, leader_followers, &horde.leader_registry.free_list, leader_index)
        }

        move_direction := leader_pathfind(&leader.data, horde.target^)
        leader_move(&leader.data, move_direction)

        leader_append_horde_damage_area(&leader.data, &horde.damage_areas)
    }

    followers := &horde.follower_registry.tickets
    follower_index := 0
    for &follower in followers {
        defer follower_index += 1
        if !follower.alive do continue

        follower_died := follower_handle_collision(&follower.data, ally_damage_areas)
        if follower_died do follower_register_death(&follower, &horde.follower_registry.free_list, follower_index)

        move_direction := follower_pathfind(horde, &follower.data)
        follower_move(&follower.data, move_direction)

        follower_append_horde_damage_area(&follower.data, &horde.damage_areas)
    }
}
