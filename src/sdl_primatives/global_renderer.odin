package primatives

import sdl "vendor:sdl3"
import log "core:log"

global_renderer: ^sdl.Renderer

create_global_renderer :: proc() {
    global_renderer = sdl.CreateRenderer(global_window, nil)
    if global_renderer == nil do log.errorf("SDL renderer creation fail: %v", sdl.GetError())
    sdl.SetRenderVSync(global_renderer, 1)
}

destroy_global_renderer :: proc() {
    sdl.DestroyRenderer(global_renderer)
}