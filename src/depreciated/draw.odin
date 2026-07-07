// shared drawing utility

package depreciated

import sdl "vendor:sdl3"
import "core:math"

trig_draw_circle :: proc(renderer: ^sdl.Renderer, cx, cy, radius: f32, color: sdl.Color, thickness: f32 = 1) {
    sdl.SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a)
    steps :: 64 // higher = smoother
    for t in 0..<int(thickness) {
        r := radius - f32(t)
        if r <= 0 {
            break
        }
        for i in 0..<steps {
            angle1 := f32(i) / f32(steps) * math.TAU
            angle2 := f32(i+1) / f32(steps) * math.TAU
            sdl.RenderLine(renderer,
                cx + math.cos(angle1) * r, cy + math.sin(angle1) * r,
                cx + math.cos(angle2) * r, cy + math.sin(angle2) * r,
            )
        }
    }
}