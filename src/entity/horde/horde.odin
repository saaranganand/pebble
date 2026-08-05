package horde

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import camera "src:camera"
import handle "src:handle"
import entity "src:entity"
import geo "src:geometry"
import util "src:util"

import rand "core:math/rand"
import log "core:log"

Horde :: struct {
    leader: util.Handle,
    target: util.Handle,
    num_followers: int,
    populated: bool,
}

horde_create :: proc(horde: ^Horde, target: util.Handle, num_followers: int) {
    horde.populated = false
    horde.target = target
    horde.num_followers = num_followers
}

horde_destroy :: proc(horde: ^Horde) {
}

horde_populate :: proc(horde: ^Horde, horde_position: sdl.FPoint) -> (followers_added: int) {
    if horde.populated {
        log.errorf("Tried to populate already populated horde!")
        return
    }

    //horde_rand_offset := sdl.FPoint{ rand.float32_range(-50, 50), rand.float32_range(-50, 50) }
    horde_rand_offset := sdl.FPoint{ 0,0 }

    horde.populated = true

    leader_handle := entity.entity_manager_add_entity(entity.entity_make_data(
        horde_position + horde_rand_offset, 90, 100, 32, .ENEMY, .PLAYER, "horde_leader.animation"
    ))

    horde.leader = leader_handle
    global_horde_manager.grid_followers[leader_handle] = make([]util.Handle, horde.num_followers)
    
    for i in 0..<horde.num_followers {
        follow_handle := entity.entity_manager_add_entity(entity.entity_make_data(
            horde_position + horde_rand_offset, 80 + rand.float32_range(-20, 20), 20, 16, .ENEMY, .PLAYER, "horde_follower.animation"
        ))

        
        global_horde_manager.grid_followers[leader_handle][i] = follow_handle

        horde_rand_offset = sdl.FPoint{ rand.float32_range(-1, 1), rand.float32_range(-1, 1) }
    }

    

    return horde.num_followers
}

horde_update :: proc(horde: ^Horde) {
    leader_entity, leader_ok := entity.entity_get(horde.leader, HORDE_TEAM)
    if !leader_ok do return

    target_entity, target_ok := entity.entity_get(horde.target, .ALLY)
    if !target_ok do return

    leader_entity.collision.position += leader_entity.move_speed * primatives.dt * geo.normalize_point(
        target_entity.collision.position - leader_entity.collision.position
    )
}