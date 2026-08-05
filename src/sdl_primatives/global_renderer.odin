package primatives

import sdl "vendor:sdl3"
import log "core:log"

global_renderer: ^sdl.Renderer

global_renderer_create :: proc() {
    global_renderer = sdl.CreateRenderer(global_window, nil)
    if global_renderer == nil do log.errorf("SDL renderer creation fail: %v", sdl.GetError())

    log.infof("Created global renderer")

    sdl.SetRenderDrawBlendMode(global_renderer, sdl.BLENDMODE_BLEND)
}

global_renderer_destroy :: proc() {
    log.infof("Destroyed global renderer")

    sdl.DestroyRenderer(global_renderer)
}

global_renderer_set_vsync :: proc(on: bool = true) {
    set: i32 = 1
    if !on do set = 0

    log.infof("Set renderer vsync mode to %v", on)

    sdl.SetRenderVSync(global_renderer, set)
}