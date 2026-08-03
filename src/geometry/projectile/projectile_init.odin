package projectile

import sdl "vendor:sdl3"

import entity "src:entity"

import rand "core:math/rand"

projectile_init_proc :: proc(state: ^Projectile_State, shell: Projectile_Shell)

@(rodata)
projectile_init_procs := [Category]projectile_init_proc{
    .BULLET         = circle_init,
    .RAY            = ray_init,
	.AOE            = circle_init,
	.RADIAL         = circle_init,
	.LINE           = line_init,
	.TRACKING_ARROW = tracking_arrow_init,
}

circle_init :: proc(state: ^Projectile_State, shell: Projectile_Shell) {
    state.shape = Circle{ radius = shell.shape_radius }
}

ray_init :: proc(state: ^Projectile_State, shell: Projectile_Shell) {
    state.shape = Ray{}
}

line_init :: proc(state: ^Projectile_State, shell: Projectile_Shell) {
    state.shape = Line{ length = shell.shape_length }
}

tracking_arrow_init :: proc(state: ^Projectile_State, shell: Projectile_Shell) {
    state.shape = Tracking_Line{ length = shell.shape_length, turn_speed = shell.shape_turn_speed }

    tline := &state.shape.(Tracking_Line)

    tline.tracking_team = entity.Team.ALLY
    if state.team == .ALLY do tline.tracking_team = .ENEMY
    tline.tracking = entity.entity_manager_get_random_handle(tline.tracking_team)

    RANDOM_SPAWN_RANGE :: 10
    state.position += { rand.float32_range(-RANDOM_SPAWN_RANGE, RANDOM_SPAWN_RANGE), rand.float32_range(-RANDOM_SPAWN_RANGE, RANDOM_SPAWN_RANGE) }
}
