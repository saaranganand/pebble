package main

import sdl "vendor:sdl3"
import "core:math"

draw_circle :: proc(renderer: ^sdl.Renderer, cx, cy, radius: f32, color: sdl.Color) {
    sdl.SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a)
    steps :: 64 // higher = smoother
    for i in 0..<steps {
        angle1 := f32(i) / f32(steps) * math.TAU
        angle2 := f32(i+1) / f32(steps) * math.TAU
        sdl.RenderLine(renderer,
            cx + math.cos(angle1) * radius, cy + math.sin(angle1) * radius,
            cx + math.cos(angle2) * radius, cy + math.sin(angle2) * radius,
        )
    }
}