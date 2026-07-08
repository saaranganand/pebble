package horde

import sdl "vendor:sdl3"

import log "core:log"

import geo "../../geometry"
import camera "../../camera"

Follower_Registry :: struct {
    tickets: [dynamic]Follower_Ticket,
    free_list: [dynamic]int,
    colliders: [dynamic]geo.Circle,
}

@(private)
follower_registry_debug_log :: proc(registry: ^Follower_Registry) -> (num_followers: int) {
    log.infof("FOLLOWER INFO:")

    num_followers = len(registry.tickets)
    log.infof("Num. followers: %v", len(registry.tickets))
    log.infof("Num. free follower spots: %v", len(registry.free_list))

    i := 0
    for follower in registry.tickets {
        defer i += 1
        log.infof("Follower %v info:", i + 1)
        log.infof("Generation: %v", follower.generation)
        log.infof("Alive: %v", follower.alive)
        log.infof("State: %v", follower.state)
        log.infof("Leader: ticket %v generation %v", follower.leader.ticket, follower.leader.generation)
    }

    return
}

@(private)
follower_registry_create :: proc() -> (registry: Follower_Registry) {
    registry.tickets = make([dynamic]Follower_Ticket)
    registry.free_list = make([dynamic]int)
    registry.colliders = make([dynamic]geo.Circle)
    return
}

@(private)
follower_registry_destroy :: proc(registry: ^Follower_Registry) {
    delete(registry.free_list)

    delete(registry.tickets)
    delete(registry.colliders)
}

@(private)
follower_registry_draw :: proc(registry: ^Follower_Registry) {
    for collider in registry.colliders do camera.camera_fill_circle(collider)
}

Follower_Ticket :: struct {
    data: Horde_Entity,
    generation: u32,
    alive: bool,

    leader: Leader_Handle,
    state: enum { Following, Wander },
}

Follower_Handle :: struct {
    ticket: int,
    generation: u32,
}

follower_resolve_handle :: proc(horde: ^Horde, h: Follower_Handle) -> (data: ^Follower_Ticket, ok: bool) {
    ticket := &horde.follower_registry.tickets[h.ticket]
    if h.generation != ticket.generation || !ticket.alive do return nil, false
    
    return ticket, true
}