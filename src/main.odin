package main

import sdl "vendor:sdl3"

import util "src:util"

import runtime "base:runtime"
import mem "core:mem"
import log "core:log"

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

main_init :: proc() {
    // INITIALIZATION
    crash := !sdl.Init({.VIDEO})
    if crash do log.errorf("SDL init fail: %v", sdl.GetError())

    crash = !ttf.Init()
    if crash do log.errorf("SDL ttf fail: %v", sdl.GetError())
    
    

    // APP INIT
    app_create()
}

main_fini :: proc() {
    // APP DE-INIT
    app_destroy()

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