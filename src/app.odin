package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import log "core:log"

import primatives "sdl_primatives"

App :: struct {
    display_id: sdl.DisplayID,
    screen_width, screen_height: i32,
    window_width, window_height: i32,
    fullscreen: bool,

    prepare_shutdown: bool,
    shutdown_ready: bool,
}

app: ^App

// this proc will just handle things like auto saving progress
handle_app_shutdown :: proc() {
    app.shutdown_ready = true
}

// returns true if shutting down
app_loop :: proc() -> bool {
    if app.prepare_shutdown {
        handle_app_shutdown()
        return app.shutdown_ready
    }

    handle_app_input(poll_app_input())

    update_cursor()

    game_loop()

    sdl.RenderPresent(primatives.global_renderer)

    return false
}

app_create :: proc() {
    app = new(App)

    app.window_width = 800
    app.window_height = 800

    primatives.global_window_create(app.window_width, app.window_height)
    // We call this immediately because of window display scale
    // for example a HiDPI display could use the same window positioning, but have twice as many pixels.
    // On such a display, when we set our window to a size, it will actually have a pixel size of 2x.
    // Since we will be using our window size for rendering, this is important, and as such,
    // we need to immediately read the window's pixel size using this procedure.
    primatives.global_window_read_size(&app.window_width, &app.window_height)
    app.display_id = primatives.global_window_read_screen_size(&app.screen_width, &app.screen_height)

    primatives.global_renderer_create()
    primatives.global_renderer_set_vsync()

    // configs
    if !load_configs() do log.errorf("Failed to load game config")

    game_create()
}

app_destroy :: proc() {
    game_destroy()

    primatives.global_renderer_destroy()
    primatives.global_window_destroy()

    free(app)
}
