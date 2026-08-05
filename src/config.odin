package main

import json "core:encoding/json"
import log "core:log"
import os "core:os"

// Pickups (programs on the map)
PickupConfig :: struct {
    count: int, // capped at number of existing unique programs
    radius: f32, // pickup collision radius, pixels
    sprite_size: f32, // drawn size, pixels

    // programs spawn in radius around player
    min_spawn_distance: f32,
    max_spawn_distance: f32,
}

// top level config used at startup
GameConfig :: struct {
    pickup: PickupConfig,
}

game_config: GameConfig

PICKUP_CONFIG_PATH :: "assets/pickup.config.json"

// call before game loop
load_configs :: proc() -> bool {
    return load_pickup()
}

@(private)
load_pickup :: proc() -> bool {
    data, err := os.read_entire_file(PICKUP_CONFIG_PATH, context.allocator)
    if err != os.General_Error.None {
        log.errorf("config: failed to read %v: %v", PICKUP_CONFIG_PATH, err)
        return false
    }
    defer delete(data)

    json_err := json.unmarshal(data, &game_config.pickup, spec = .MJSON)
    if json_err != nil {
        log.errorf("config: failed to parse %v: %v", PICKUP_CONFIG_PATH, json_err)
        return false
    }

    return true
}
