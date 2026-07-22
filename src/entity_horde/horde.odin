package horde

import sdl "vendor:sdl3"

import primatives "../sdl_primatives"
import camera "../camera"
import handle "../handle"
import entity "../entity"
import geo "../geometry"

import rand "core:math/rand"
import log "core:log"

Horde :: struct {
    leader: handle.Entity_Handle,
    target: handle.Entity_Handle,
    followers: []handle.Entity_Handle,
    num_followers: int,
    grid: Spatial_Grid,
    populated: bool,
}

horde_create :: proc(horde: ^Horde, target: handle.Entity_Handle, num_followers: int) {
    horde.followers = make([]handle.Entity_Handle, num_followers)
    horde.populated = false
    horde.target = target
    horde.num_followers = num_followers
    spatial_grid_create(&horde.grid)
}

horde_destroy :: proc(horde: ^Horde) {
    delete(horde.followers)
    spatial_grid_destroy(&horde.grid)
}

horde_populate :: proc(horde: ^Horde, horde_position: sdl.FPoint) {
    if horde.populated {
        log.errorf("Tried to populate already populated horde!")
        return
    }

    horde_rand_offset := sdl.FPoint{ rand.float32_range(-50, 50), rand.float32_range(-50, 50) }

    horde.populated =  true
    
    for i in 0..<horde.num_followers {
        follow_handle := entity.entity_manager_add_entity(entity.entity_make_data(
            horde_position + horde_rand_offset, 80, 20, .ENEMY, .PLAYER, "animations/entity/horde_follower.yaml"
        ))

        horde.followers[i] = follow_handle
        horde_rand_offset = sdl.FPoint{ rand.float32_range(-50, 50), rand.float32_range(-50, 50) }
    }

    leader_handle := entity.entity_manager_add_entity(entity.entity_make_data(
        horde_position + horde_rand_offset, 90, 100, .ENEMY, .PLAYER, "animations/entity/horde_leader.yaml"
    ))

    horde.leader = leader_handle
}

horde_update :: proc(horde: ^Horde) {
    leader_entity, leader_ok := entity.entity_get(horde.leader)
    if !leader_ok do return

    target_entity, target_ok := entity.entity_get(horde.target)
    if !target_ok do return

    if leader_entity.active do leader_entity.position += leader_entity.move_speed * primatives.dt * geo.normalize_point(
        target_entity.position - leader_entity.position
    )

    horde_boid_update(horde)
}

horde_draw :: proc(horde: Horde) {
    for follower_handle in horde.followers {
        follower_entity, follower_ok := entity.entity_get(follower_handle)
        if !follower_ok do continue
        if !follower_entity.active do continue

        camera.camera_draw_animation(&follower_entity.animation_controller, follower_entity.position)
    }

    leader_entity, leader_ok := entity.entity_get(horde.leader)
    if !leader_ok do return
    if !leader_entity.active do return

    camera.camera_draw_animation(&leader_entity.animation_controller, leader_entity.position)
}