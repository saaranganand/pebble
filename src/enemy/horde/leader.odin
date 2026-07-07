package horde
import sdl "vendor:sdl3"
import math "core:math"
import rand "core:math/rand"
import log "core:log"

import primatives "../../global_primatives"
import geo "../../geometry"

LEADER_SIZE :: 32
LEADER_SPEED :: 20

LEADER_STARTING_HEALTH :: 10
LEADER_FOLLOWER_SIZE :: 1

Horde_Leader :: struct {
    position: sdl.FPoint,
    target: ^sdl.FPoint,
    health: f32,
}

Leader_Registry :: struct {
    tickets: [dynamic]Leader_Ticket,
    free_list: [dynamic]int,
    followers_of: [dynamic][dynamic]Follower_Handle,
}

Leader_Ticket :: struct {
    data: Horde_Leader,
    generation: u32,
    alive: bool,
}

Leader_Handle :: struct {
    ticket: int,
    generation: u32,
}

@(private)
leader_registry_debug_log :: proc(registry: ^Leader_Registry) {
    log.infof("LEADER INFO:")
    log.infof("Num. leaders: %v", len(registry.tickets))
    log.infof("Num. free leader spots: %v", len(registry.free_list))

    i := 0
    for leader in registry.tickets {
        defer i += 1
        log.infof("Leader %v info:", i + 1)
        log.infof("Num. followers: %v", len(registry.followers_of[i]))
        log.infof("Generation: %v", leader.generation)
        log.infof("Alive: %v", leader.alive)
    }
}

@(private)
leader_registry_create :: proc() -> (registry: Leader_Registry) {
    registry.tickets = make([dynamic]Leader_Ticket)
    registry.free_list = make([dynamic]int)
    registry.followers_of = make([dynamic][dynamic]Follower_Handle)
    return
}

@(private)
leader_registry_destroy :: proc(registry: ^Leader_Registry) {
    delete(registry.free_list)
    
    for follower_list in registry.followers_of {
        delete(follower_list)
    }
    delete(registry.followers_of)

    delete(registry.tickets)
}

@(private)
leader_init :: proc(leader_position: sdl.FPoint, leader_target: ^sdl.FPoint) -> (leader: Horde_Leader) {
    leader.position = leader_position
    leader.target = leader_target
    leader.health = LEADER_STARTING_HEALTH

    return
}

@(private)
leader_create :: proc(registry: ^Leader_Registry, leader_position: sdl.FPoint, leader_target: ^sdl.FPoint) -> Leader_Handle {
    new_leader := leader_init(leader_position, leader_target)

    // If the array is full, append the new leader
    if len(registry.free_list) == 0 {
        append(&registry.tickets, Leader_Ticket{
            data = new_leader,
            generation = 0,
            alive = true,
        })

        // Also need to append a spot for the leader's followers
        append(&registry.followers_of, make([dynamic]Follower_Handle))

        return Leader_Handle{ len(registry.tickets) - 1, 0 }
    }

    // Otherwise, find a vacant spot and update the generation
    insert := pop(&registry.free_list)
    new_generation := registry.tickets[insert].generation + 1
    registry.tickets[insert] = Leader_Ticket{
        data = new_leader,
        generation = new_generation,
        alive = true,
    }

    return Leader_Handle{ insert, new_generation }
}

// Spawns a leader and its followers both
leader_spawn :: proc(horde: ^Horde, leader_position: sdl.FPoint) {
    leader_target := horde.target
    new_leader_handle := leader_create(&horde.leader_registry, leader_position, leader_target)

    leader_followers_of := &horde.leader_registry.followers_of[new_leader_handle.ticket]
    for i in 0..<LEADER_FOLLOWER_SIZE {
        new_follower_handle := follower_create(&horde.follower_registry, leader_position, new_leader_handle)
        
        append(leader_followers_of, new_follower_handle)
    }
}

leader_resolve_handle :: proc(horde: ^Horde, h: Leader_Handle) -> (data: ^Horde_Leader, ok: bool) {
    ticket := horde.leader_registry.tickets[h.ticket]
    if h.generation != ticket.generation || !ticket.alive do return nil, false
    
    return &ticket.data, true
}

@(private)
leader_append_horde_damage_area :: proc(leader: ^Horde_Leader, areas: ^[dynamic]geo.Circle) {
    leader_hurt_box := geo.Circle{ leader.position, LEADER_SIZE }
    append(areas, leader_hurt_box)
}

@(private)
leader_take_damage :: proc(leader: ^Horde_Leader, damage: f32) {
    leader.health -= damage
}

// both checks for damage collision, and carries out damage
@(private)
leader_handle_collision :: proc(leader: ^Horde_Leader, ally_damage_areas: ^[dynamic]geo.Circle) -> (died: bool) {
    leader_hurt_box := geo.Circle{ leader.position, LEADER_SIZE }

    for ally_area in ally_damage_areas {
        if geo.are_circles_colliding(leader_hurt_box, ally_area) {
            // TODO: Ensure that incoming data is not just circles,
            // but a data wrapper containing the circle, damage, and hit effects.
            // Apply the hit effect
            leader_take_damage(leader, 1)

            // TODO: while we register the death here,
            // there will likely be other tasks to do,
            // like compiling a datalist of kill drops and returning it to the main package,
            // or playing death sound/animation, etc.
            if leader.health < 0 do return true
        }
    }

    return false
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
leader_pathfind :: proc(leader: ^Horde_Leader, target: sdl.FPoint) -> (move_direction: sdl.FPoint){
    // TODO: give a more complicated pathfinding algorithm, like A*
    return geo.normalize_point(target - leader.position)
}

@(private)
leader_move :: proc(leader: ^Horde_Leader, direction: sdl.FPoint) {
    leader.position += direction * LEADER_SPEED * primatives.dt
}