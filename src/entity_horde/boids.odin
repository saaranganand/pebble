package horde

import sdl "vendor:sdl3"

import primatives "../sdl_primatives"
import entity "../entity"
import handle "../handle"
import geo "../geometry"


import rand "core:math/rand"
import math "core:math"
import log "core:log"

SEPARATION_WEIGHT  :: 2.0
SEPERATION_SPEED   :: 1000.0

ALIGNMENT_WEIGHT   :: 0.5

COHESION_WEIGHT    :: 0.5

FOLLOW_LEADER_WEIGHT :: 0.8
FOLLOW_LEADER_SPEED :: 200.0
FOLLOW_LEADER_MINIMUM_DIST :: 60.0

RAND_STEER_WEIGHT :: 0.5
RAND_MIN_VELOCITY :: 0.0
RAND_MAX_VELOCITY :: 50.0

LEADER_PUSH_RATE :: 5.0

MAX_STEER_SPEED :: 600.0


HORDE_TEAM :: entity.Team.ENEMY

horde_boid_update :: proc() {
    grid := &global_horde_manager.grid
    grid_followers := global_horde_manager.grid_followers

    for leader, horde_followers in grid_followers {
        leader_entity, leader_ok := entity.entity_get(leader, HORDE_TEAM)
        if !leader_ok do return

        for follower_handle in horde_followers {
            follower_entity, follower_ok := entity.entity_get(follower_handle, HORDE_TEAM)
            if !follower_ok do continue
            if !follower_entity.active do continue

            spatial_grid_get_nearby_followers(grid, follower_handle, follower_entity.position)

            separation_velocity, alignment_velocity, cohesion_velocity: sdl.FPoint
            neighbour_count := 0

            for neighbour_handle in grid.grid_neighbours {
                neighbour, n_ok := entity.entity_get(neighbour_handle, HORDE_TEAM)
                if !n_ok do continue
                defer neighbour_count += 1

                alignment_velocity += neighbour.move_direction * neighbour.base_move_speed

                cohesion_velocity += neighbour.position
                
                delta_pos := follower_entity.position - neighbour.position
                dist := math.sqrt(math.pow(delta_pos.x, 2) + math.pow(delta_pos.y, 2))
                if dist < 0.1 do continue
                separation_velocity += geo.normalize_point(delta_pos) * SEPERATION_SPEED / math.pow(dist, 1)
            }

            if neighbour_count > 0 {
                n := f32(neighbour_count)
                // average the by-neighbour velocities
                alignment_velocity = (alignment_velocity / n) - (follower_entity.move_direction * follower_entity.base_move_speed)
                cohesion_velocity  = (cohesion_velocity  / n) - follower_entity.position
            }

            leader_difference := follower_entity.position - leader_entity.position
            leader_dist_squared := math.pow(leader_difference.x, 2) + math.pow(leader_difference.y, 2)
            leader_direction := geo.normalize_point(leader_difference)

            /*dist := math.sqrt(leader_dist_squared)
            offset := dist - cast(f32) FOLLOW_LEADER_MINIMUM_DIST
            t := clamp(offset / FOLLOW_LEADER_MINIMUM_DIST, -1.0, 1.0)  // normalized: -1 too close, +1 far away, 0 at target dist

            follow_leader_velocity = -leader_direction * t * FOLLOW_LEADER_SPEED

            //follow_leader_velocity = leader_direction * offset * FOLLOW_LEADER_SPEED*/

            

            dist := math.sqrt(leader_dist_squared)
            lower_bound: f32 = FOLLOW_LEADER_MINIMUM_DIST * 0.5
            upper_bound: f32 = FOLLOW_LEADER_MINIMUM_DIST * 2.0

            stick_to_leader_velocity: sdl.FPoint
            push_leader_velocity: sdl.FPoint

            stick_share := clamp((dist - lower_bound) / (upper_bound - lower_bound), 0.0, 1.0)
            push_share := 1.0 - stick_share

            stick_to_leader_velocity = -leader_direction * FOLLOW_LEADER_SPEED
            if leader_dist_squared > 0.01 {
                push_leader_velocity = leader_direction * SEPERATION_SPEED * LEADER_PUSH_RATE / math.pow(dist, 1)
            }
            
            //log.warnf("%v %v", stick_share, push_share)

            follow_leader_velocity := stick_to_leader_velocity * stick_share + push_leader_velocity * push_share

            /*if leader_dist_squared > math.pow(cast(f32) FOLLOW_LEADER_MINIMUM_DIST, 2) {
                follow_leader_velocity = -leader_direction * FOLLOW_LEADER_SPEED
            } else if leader_dist_squared > 0.01 {
                dist := math.sqrt(leader_dist_squared)
                follow_leader_velocity += leader_direction * SEPERATION_SPEED * LEADER_PUSH_RATE / math.pow(dist, 1)
            }*/

            rand_velocity := geo.normalize_point(
                sdl.FPoint{ rand.float32_range(-1, 1), rand.float32_range(-1, 1) }
            ) * rand.float32_range(RAND_MIN_VELOCITY, RAND_MAX_VELOCITY)

            steer_velocity := separation_velocity * SEPARATION_WEIGHT    +
                     alignment_velocity           * ALIGNMENT_WEIGHT     +
                     cohesion_velocity            * COHESION_WEIGHT      +
                     follow_leader_velocity       * FOLLOW_LEADER_WEIGHT +
                     rand_velocity                * RAND_STEER_WEIGHT

            steer_velocity = clamp_magnitude(steer_velocity, MAX_STEER_SPEED)


            follower_entity.base_move_speed = math.sqrt(math.pow(steer_velocity.x, 2) + math.pow(steer_velocity.y, 2))
            follower_entity.move_direction = geo.normalize_point(steer_velocity)

            //log.warnf("move_speed %v\nmove_direction %v\n", follower_entity.move_speed, follower_entity.move_direction)
        }
    }
    log.warnf("\n\n")
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