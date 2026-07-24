package dep_horde

import sdl "vendor:sdl3"

import log "core:log"

import geo "../../geometry"
import camera "../../camera"

Leader_Registry :: struct {
    tickets: [dynamic]Leader_Ticket,
    free_list: [dynamic]int,
    followers_of: [dynamic][dynamic]Follower_Handle,
    colliders: [dynamic]geo.Circle,
}

@(private)
leader_registry_debug_log :: proc(registry: ^Leader_Registry) -> (num_leaders: int) {
    log.infof("LEADER INFO:")
    
    num_leaders = len(registry.tickets)
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

    return
}

@(private)
leader_registry_create :: proc() -> (registry: Leader_Registry) {
    registry.tickets = make([dynamic]Leader_Ticket)
    registry.free_list = make([dynamic]int)
    registry.followers_of = make([dynamic][dynamic]Follower_Handle)
    registry.colliders = make([dynamic]geo.Circle)
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
    delete(registry.colliders)
}

@(private)
leader_registry_draw :: proc(registry: ^Leader_Registry) {
    for collider in registry.colliders do camera.camera_fill_circle(collider)
}

Leader_Ticket :: struct {
    data: Horde_Entity,
    generation: u32,
    alive: bool,

    target: ^sdl.FPoint,
}

Leader_Handle :: struct {
    ticket: int,
    generation: u32,
}

leader_resolve_handle :: proc(horde: ^Horde, h: Leader_Handle) -> (data: ^Horde_Entity, ok: bool) {
    ticket := horde.leader_registry.tickets[h.ticket]
    if h.generation != ticket.generation || !ticket.alive do return nil, false
    
    return &ticket.data, true
}