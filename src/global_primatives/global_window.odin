package primatives

import sdl "vendor:sdl3"
import log "core:log"

global_window: ^sdl.Window

create_global_window :: proc(width, height: i32) {
    global_window = sdl.CreateWindow("Pebble", width, height, {})
    if global_window == nil do log.errorf("SDL window creation fail: %v", sdl.GetError())
}

destroy_global_window :: proc() {
    sdl.DestroyWindow(global_window)
}