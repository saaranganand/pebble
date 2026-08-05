package primatives

import sdl "vendor:sdl3"
import log "core:log"

global_window: ^sdl.Window

screen_width, screen_height: i32
window_width, window_height: i32

global_window_create :: proc(width, height: i32) {
    global_window = sdl.CreateWindow("Pebble", width, height, {})
    if global_window == nil do log.errorf("SDL window creation fail: %v", sdl.GetError())

    log.infof("Created global window")
}

global_window_destroy :: proc() {
    sdl.DestroyWindow(global_window)

    log.infof("Destroyed global window")
}

global_window_read_size :: proc(width, height: ^i32) {
    log.infof("Window pixel size being read, window was resized")

    success := sdl.GetWindowSizeInPixels(global_window, width, height)
    if !success do log.fatalf("Unable to get window size")
}

global_window_read_screen_size :: proc(width, height: ^i32) -> (display_id: sdl.DisplayID){
    log.infof("Screen pixel size being read, display was set or changed")

    display_id = sdl.GetDisplayForWindow(global_window)
    bounds: sdl.Rect
    success := sdl.GetDisplayBounds(display_id, &bounds)
    if !success do log.fatalf("Unable to get screen bounds")

    // display size is in screen coordinates, not pixels.
    // need to do this for HiDPI monitors and other nonsense.
    scale := sdl.GetDisplayContentScale(display_id)
    width^  = i32(f32(bounds.w) * scale)
    height^ = i32(f32(bounds.h) * scale)

    return
}