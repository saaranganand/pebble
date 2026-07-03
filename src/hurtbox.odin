package main

import sdl "vendor:sdl3"

Hurt_Box_Path :: proc(box: Hurt_Box)

Hurt_Box :: struct {
    c: Circle,

    // Represents how many hitboxes this hurtbox can pass through before being destroyed
    // 0 means it is destroyed on contact 
    pierce: int,
    speed: f32,
    path_fn: Hurt_Box_Path 
}