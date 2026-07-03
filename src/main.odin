package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import img "vendor:sdl3/image"
import mem "core:mem"
import log "core:log"
import util "util"
import runtime "base:runtime"

ORIGINAL_ALLOCATOR: runtime.Allocator

main :: proc() {
    util.allocate_file_logger(true)
    context.logger = util.GLOBAL_LOGGER

    // tracking allocator for debugging
    when ODIN_DEBUG {
        ORIGINAL_ALLOCATOR = context.allocator
        util.allocate_tracking_alloc()
        context.allocator = mem.tracking_allocator(&util.GLOBAL_TRACKING_ALLOC)
    }

    main_init()
    defer main_fini()

    for !main_loop() {}
}

main_loop :: proc() -> (close: bool) {
    close = app_loop()
    when ODIN_DEBUG { util.check_tracking_alloc() }
    return 
}

global_renderer: ^sdl.Renderer
global_window: ^sdl.Window

main_init :: proc() {
    // INITIALIZATION
    crash := !sdl.Init({.VIDEO})
    if crash do log.errorf("SDL init fail: %v", sdl.GetError())

    crash = !ttf.Init()
    if crash do log.errorf("SDL ttf fail: %v", sdl.GetError())
    
    if !load_configs() {
        fmt.eprintln("failed to load config files")
        return
    }

    // APP INIT
    app_init()
}

main_fini :: proc() {
    // APP DE-INIT
    app_close()

    // DE-INITIALIZATION
    ttf.Quit()
    sdl.Quit()

    when ODIN_DEBUG {
        util.report_tracking_alloc()
        context.allocator = ORIGINAL_ALLOCATOR
    }

    util.destroy_file_logger()

    when ODIN_DEBUG do util.destroy_tracking_alloc()
}

reset_auto_weapons :: proc(player: ^Player, pool: ^PingWavePool) {
    player.ping.is_active = false
    for &w in pool.waves {
        w.alive = false
    }
    player.daemon.is_active = false
}
