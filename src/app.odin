package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import log "core:log"

import primatives "sdl_primatives"

read_window_size :: proc() {
    log.infof("Window pixel size being read, window was resized")

    success := sdl.GetWindowSizeInPixels(primatives.global_window, &app.window_width, &app.window_height)
    if !success do log.fatalf("Unable to get window size")
}

read_screen_size :: proc() {
    log.infof("Screen pixel size being read, display was set or changed")

    app.display_id = sdl.GetDisplayForWindow(primatives.global_window)
    bounds: sdl.Rect
    success := sdl.GetDisplayBounds(app.display_id, &bounds)
    if !success do log.fatalf("Unable to get screen bounds")

    // display size is in screen coordinates, not pixels.
    // need to do this for HiDPI monitors and other nonsense.
    scale := sdl.GetDisplayContentScale(app.display_id)
    app.screen_width  = i32(f32(bounds.w) * scale)
    app.screen_height = i32(f32(bounds.h) * scale)
}

app := struct {
    font: ^ttf.Font,

    display_id: sdl.DisplayID,
    screen_width, screen_height: i32,
    window_width, window_height: i32,
    fullscreen: bool,

    prepare_shutdown: bool,
    shutdown_ready: bool,
}{
    window_width = 800,
    window_height = 800,
}

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

    //update_cursor(player, crosshair_cursor)

    game_loop()

    sdl.RenderPresent(primatives.global_renderer)

    return false
}

app_init :: proc() {
    primatives.create_global_window(app.window_width, app.window_height)
    // We call this immediately because of window display scale
    // for example a HiDPI display could use the same window positioning, but have twice as many pixels.
    // On such a display, when we set our window to a size, it will actually have a pixel size of 2x.
    // Since we will be using our window size for rendering, this is important, and as such,
    // we need to immediately read the window's pixel size using this procedure.
    read_window_size()
    read_screen_size()

    primatives.create_global_renderer()
    
    // font
    app.font = ttf.OpenFont("assets/font1.ttf", 24)

    // configs
    if !load_configs() do log.errorf("Failed to load game config")

    game_init()
}

app_close :: proc() {
    ttf.CloseFont(app.font)

    primatives.destroy_global_renderer()
    primatives.destroy_global_window()

    game_close()
}
