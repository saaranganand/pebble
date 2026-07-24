// programs scattered on the map; walk over one to equip it

package main

import sdl "vendor:sdl3"

import rand "core:math/rand"
import fmt "core:fmt"
import log "core:log"
import math "core:math"

import camera "camera"
import entity "entity"
import program "program"
import geo "geometry"

// tuning is in data/pickup.yaml (game_config.pickup)
// 1 sprite (for now)
PROGRAM_PICKUP_IMG :: "img/program.png"

Program_Pickup :: struct {
    world_position: sdl.FPoint,
    program_id: program.Program_Definition_ID,
    active: bool,
}

Program_Pickup_System :: struct {
    pickups: [dynamic]Program_Pickup,
}

// Must run after the program manager is loaded (pickups reference program IDs)
program_pickup_system_create :: proc() -> (system: Program_Pickup_System) {
    system.pickups = make([dynamic]Program_Pickup)

    num_programs := program.program_manager_num_definitions()
    if num_programs == 0 {
        log.warnf("No programs loaded, scattering no pickups")
        return
    }

    // No repeats
    program_ids := make([]program.Program_Definition_ID, num_programs)
    defer delete(program_ids)
    for i in 0..<num_programs {
        program_ids[i] = i
    }
    rand.shuffle(program_ids)

    // spawn distances are measured from where the player is right now
    player_position := sdl.FPoint{ 0, 0 }
    if player_entity, ok := entity.entity_get(game.player.entity, .ALLY); ok {
        player_position = player_entity.position
    }

    min_distance := game_config.pickup.min_spawn_distance
    max_distance := game_config.pickup.max_spawn_distance

    pickup_count := min(int(num_programs), game_config.pickup.count)
    for i in 0..<pickup_count {
        // uniform point in the radius [min_distance, max_distance] around the player
        angle := rand.float32() * 2 * math.PI
        distance := math.sqrt(rand.float32() * (max_distance * max_distance - min_distance * min_distance) + min_distance * min_distance)
        position := player_position + sdl.FPoint{ math.cos(angle), math.sin(angle) } * distance

        append(&system.pickups, Program_Pickup{
            world_position = position,
            program_id = program_ids[i],
            active = true,
        })

        // log.infof("pickup %v spawned %v px from player", program_ids[i], geo.get_point_distance(position, player_position))
    }

    log.infof("Scattered %v program pickups", len(system.pickups))
    return
}

program_pickup_system_destroy :: proc(system: ^Program_Pickup_System) {
    delete(system.pickups)
}

program_pickup_system_update :: proc(system: ^Program_Pickup_System) {
    player_entity, ok := entity.entity_get(game.player.entity, .ALLY)
    if !ok do return

    player_circle := geo.Circle{ player_entity.position, player_entity.col_radius }

    for &pickup in system.pickups {
        if !pickup.active do continue

        pickup_circle := geo.Circle{ pickup.world_position, game_config.pickup.radius }
        if !geo.are_circles_colliding(player_circle, pickup_circle) do continue

        program_pickup_collect(&pickup, player_entity.position)
    }
}

@(private="file")
program_pickup_collect :: proc(pickup: ^Program_Pickup, player_position: sdl.FPoint) {
    pickup.active = false

    definition := program.program_manager_get_definition_by_id(pickup.program_id)
    if definition == nil do return

    log.infof("Player collected program pickup %v at %v", definition.unique_tag, pickup.world_position)

    // Applies buffs, self-effects, and hit-effects
    program.program_loadout_equip(&game.player.program_loadout, definition.unique_tag)

    label := fmt.caprintf("+ %v", definition.unique_tag)
    defer delete(label)
    floating_text_spawn(&game.floating_texts, label, player_position + {0, -30})
}

program_pickup_system_draw :: proc(system: ^Program_Pickup_System) {
    for &pickup in system.pickups {
        if !pickup.active do continue

        size := game_config.pickup.sprite_size
        dest := sdl.FRect{
            x = pickup.world_position.x - size / 2,
            y = pickup.world_position.y - size / 2,
            w = size,
            h = size,
        }
        camera.camera_draw_img(PROGRAM_PICKUP_IMG, dest)
    }
}
