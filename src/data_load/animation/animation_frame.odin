package animation

import sdl "vendor:sdl3"

Animation_Frame :: struct {
    source: sdl.FRect,
    hang_frames: uint,
    dest_scale: [2]f32,
}