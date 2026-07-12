package main

import sdl "vendor:sdl3"

Entity :: struct {
    position: sdl.FPoint,
    move_velocity: sdl.FPoint,
    base_move_speed, move_speed: f32,
    forces: []sdl.FPoint,
    health: f32,
}