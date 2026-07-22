package horde

import sdl "vendor:sdl3"

import primatives "../sdl_primatives"
import entity "../entity"
import handle "../handle"
import geo "../geometry"


import rand "core:math/rand"
import math "core:math"

FOLLOWER_SEPARATION_WEIGHT  :: 3
FOLLOWER_ALIGNMENT_WEIGHT   :: 1.0
FOLLOWER_COHESION_WEIGHT    :: 1.0
FOLLOWER_LEADER_SEEK_WEIGHT :: 1.4
FOLLOWER_MAX_STEER_FORCE    :: 400.0
FOLLOWER_LEADER_MIN_DISTANCE :: 40

HORDE_TEAM :: entity.Team.ENEMY

horde_boid_update :: proc(horde: ^Horde) {
    grid := &horde.grid
    followers := horde.followers
    leader := horde.leader

    spatial_grid_build(grid, followers)

    leader_entity, leader_ok := entity.entity_get(leader, HORDE_TEAM)
    if !leader_ok do return

    for follower_handle in followers {
        follower_entity, follower_ok := entity.entity_get(follower_handle, HORDE_TEAM)
        if !follower_ok do continue
        if !follower_entity.active do continue

        spatial_grid_get_nearby_followers(grid, follower_handle, follower_entity.position)

        separation, alignment, cohesion: sdl.FPoint
        neighbour_count := 0
        move_direction := sdl.FPoint{}

        for neighbour_handle in grid.grid_neighbours {
            neighbour, n_ok := entity.entity_get(neighbour_handle, HORDE_TEAM)
            if !n_ok do continue

            delta_pos := follower_entity.position - neighbour.position
            dist_squared := math.pow(delta_pos.x, 2) + math.pow(delta_pos.y, 2)
            if dist_squared > 0.01 {
                inv_dist := 1.0 / math.sqrt(dist_squared)
                separation += delta_pos * inv_dist
            }

            

            alignment += move_direction
            cohesion += neighbour.position
            neighbour_count += 1
        }

        if neighbour_count > 0 {
            n := f32(neighbour_count)
            alignment = (alignment / n) - move_direction
            cohesion  = (cohesion  / n) - follower_entity.position
        }

        leader_diff := follower_entity.position - leader_entity.position
        leader_dist_sq := leader_diff.x*leader_diff.x + leader_diff.y*leader_diff.y

        leader_seek: sdl.FPoint
        if leader_dist_sq > FOLLOWER_LEADER_MIN_DISTANCE * FOLLOWER_LEADER_MIN_DISTANCE {
            // far enough away — pull toward leader as before
            leader_seek = -leader_diff
        } else if leader_dist_sq > 0.0001 {
            // too close — push away, same falloff style as follower separation
            inv_dist := 1.0 / math.sqrt(leader_dist_sq)
            leader_seek = leader_diff * inv_dist * FOLLOWER_LEADER_MIN_DISTANCE * 50 // scale so it's comparable in magnitude to seek
        }

        //leader_seek := leader_entity.position - follower_entity.position

        steer := separation  * FOLLOWER_SEPARATION_WEIGHT * 4 +
                 alignment   * FOLLOWER_ALIGNMENT_WEIGHT  +
                 cohesion    * FOLLOWER_COHESION_WEIGHT   +
                 leader_seek * FOLLOWER_LEADER_SEEK_WEIGHT * 0.05

        steer = clamp_magnitude(steer, FOLLOWER_MAX_STEER_FORCE)

        rand_steer := geo.normalize_point(sdl.FPoint{ rand.float32_range(-1, 1), rand.float32_range(-1, 1) }) * rand.float32_range(0.1, 2)

        move_direction += steer + rand_steer
        follower_entity.move_direction = geo.normalize_point(move_direction)
        //follower_entity.move_velocity = clamp_magnitude(follower_entity.move_velocity, follower_entity.move_speed)
        //follower_entity.position += follower_entity.move_velocity * primatives.dt
    }
    
}

clamp_magnitude :: proc(v: sdl.FPoint, max_len: f32) -> sdl.FPoint {
    len_squared := v.x*v.x + v.y*v.y
    if len_squared > max_len*max_len {
        len := math.sqrt(len_squared)
        scale := max_len / len
        return { v.x * scale, v.y * scale }
    }
    return v
}