package horde
import sdl "vendor:sdl3"
import math "core:math"
import rand "core:math/rand"
import log "core:log"

import primatives "../../global_primatives"
import geo "../../geometry"

FOLLOWER_SIZE :: 16
FOLLOWER_SPEED :: 25

FOLLOWER_STARTING_HEALTH :: 3

Horde_Follower :: struct {
    position: sdl.FPoint,
    health: f32,
    leader: Leader_Handle,
    state: enum { Following, Wander },
}

Follower_Registry :: struct {
    tickets: [dynamic]Follower_Ticket,
    free_list: [dynamic]int,
}

Follower_Ticket :: struct {
    data: Horde_Follower,
    generation: u32,
    alive: bool,
}

Follower_Handle :: struct {
    ticket: int,
    generation: u32,
}

@(private)
follower_registry_debug_log :: proc(registry: ^Follower_Registry) {
    log.infof("FOLLOWER INFO:")
    log.infof("Num. followers: %v", len(registry.tickets))
    log.infof("Num. free follower spots: %v", len(registry.free_list))

    i := 0
    for follower in registry.tickets {
        defer i += 1
        log.infof("Follower %v info:", i + 1)
        log.infof("Generation: %v", follower.generation)
        log.infof("Alive: %v", follower.alive)
        log.infof("State: %v", follower.data.state)
        log.infof("Leader: ticket %v generation %v", follower.data.leader.ticket, follower.data.leader.generation)
    }
}

@(private)
follower_registry_create :: proc() -> (registry: Follower_Registry) {
    registry.tickets = make([dynamic]Follower_Ticket)
    registry.free_list = make([dynamic]int)
    return
}

@(private)
follower_registry_destroy :: proc(registry: ^Follower_Registry) {
    delete(registry.free_list)

    delete(registry.tickets)
}

@(private)
follower_init :: proc(follower_position: sdl.FPoint, follower_leader: Leader_Handle) -> (follower: Horde_Follower) {
    follower.position = follower_position
    follower.leader = follower_leader
    follower.health = FOLLOWER_STARTING_HEALTH
    follower.state = .Following

    return
}

@(private)
follower_create :: proc(registry: ^Follower_Registry, follower_position: sdl.FPoint, follower_leader: Leader_Handle) -> Follower_Handle {
    new_follower := follower_init(follower_position, follower_leader)
    
    // If the array is full, append the new follower
    if len(registry.free_list) == 0 {
        append(&registry.tickets, Follower_Ticket{
            data = new_follower,
            generation = 0,
            alive = true,
        })

        return Follower_Handle{ len(registry.tickets) - 1, 0 }
    }

    // Otherwise, find a vacant spot and update the generation
    insert := pop(&registry.free_list)
    new_generation := registry.tickets[insert].generation + 1
    registry.tickets[insert] = Follower_Ticket{
        data = new_follower,
        generation = new_generation,
        alive = true,
    }

    return Follower_Handle{ insert, new_generation }
}

follower_resolve_handle :: proc(horde: ^Horde, h: Follower_Handle) -> (data: ^Horde_Follower, ok: bool) {
    ticket := horde.follower_registry.tickets[h.ticket]
    if h.generation != ticket.generation || !ticket.alive do return nil, false
    
    return &ticket.data, true
}

@(private)
follower_append_horde_damage_area :: proc(follower: ^Horde_Follower, areas: ^[dynamic]geo.Circle) {
    follower_hurt_box := geo.Circle{ follower.position, FOLLOWER_SIZE }
    append(areas, follower_hurt_box)
}

@(private)
follower_take_damage :: proc(follower: ^Horde_Follower, damage: f32) {
    follower.health -= damage
}

// both checks for damage collision, and carries out damage
@(private)
follower_handle_collision :: proc(follower: ^Horde_Follower, ally_damage_areas: ^[dynamic]geo.Circle) -> (died: bool) {
    follower_hurt_box := geo.Circle{ follower.position, FOLLOWER_SIZE }

    for ally_area in ally_damage_areas {
        if geo.are_circles_colliding(follower_hurt_box, ally_area) {
            // TODO: Ensure that incoming data is not just circles,
            // but a data wrapper containing the circle, damage, and hit effects.
            // Apply the hit effect
            follower_take_damage(follower, 1)

            // TODO: while we register the death here,
            // there will likely be other tasks to do,
            // like compiling a datalist of kill drops and returning it to the main package,
            // or playing death sound/animation, etc.
            if follower.health < 0 do return true
        }
    }

    return false
}

@(private)
follower_register_death :: proc(follower: ^Follower_Ticket, free_list: ^[dynamic]int, follower_index: int) {
    follower.alive = false
    append(free_list, follower_index)
}

@(private)
follower_pathfind :: proc(horde: ^Horde, follower: ^Horde_Follower) -> (move_direction: sdl.FPoint){
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
    return geo.normalize_point(leader.position - follower.position)
}

@(private)
follower_move :: proc(follower: ^Horde_Follower, direction: sdl.FPoint) {
    follower.position += direction * FOLLOWER_SPEED * primatives.dt
}