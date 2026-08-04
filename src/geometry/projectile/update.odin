package projectile

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"

import math "core:math"

update_proc :: proc(state: ^State)

@(rodata)
update_procs := #partial [Category]update_proc{
    .BULLET         = default_update,
    .RAY            = default_update,
	.AOE            = default_update,
	.RADIAL         = default_update,
	.LINE           = default_update
}

default_update :: proc(state: ^State) {
    direction := sdl.FPoint{
        math.cos(state.shoot_angle),
        math.sin(state.shoot_angle),
    }
    state.position += direction * state.speed * primatives.dt
}