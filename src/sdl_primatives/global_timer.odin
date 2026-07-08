package primatives

import sdl "vendor:sdl3"

dt: f32
last_time: u64

global_timer_init :: proc() {
    last_time = sdl.GetTicks()
}

global_timer_update :: proc() {
    current_time := sdl.GetTicks()
    dt = f32(current_time - last_time) / 1000.0
    last_time = current_time
}