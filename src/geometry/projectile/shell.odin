package projectile

import entity "src:entity"

// Used for a go-between for loading weapons from json and spawning projectiles from weapons
// Contains the needed information to spawn projectile states, at which point th
Shell :: struct {
    category: Category,
    team: entity.Team,
    damage: f32,
    piercing: uint,
    speed: f32,
    lifetime: f32,
    shots: uint,
    scale: f32,

    animation_source: string,
    apply_effect: Maybe(string),

    shape_radius: f32,
    shape_length: f32,
    shape_turn_speed: f32,
}

shell_add_defaults :: proc(shell: ^Shell, team: entity.Team) {
    if shell.shots == 0 do shell.shots = 1
    if shell.scale == 0 do shell.scale = 1
    shell.team = team
}