package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import log "core:log"

app := struct {
    font: ^ttf.Font,
    screen_choice: int,
    screen_width, screen_height: i32,
    window_width, window_height: i32,
    should_close: bool,
}{
    window_width = 800,
    window_height = 800,
}

app_input :: proc() {
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
        case .QUIT:
            app.should_close = true
        case .KEY_DOWN:
            switch event.key.key {
            case sdl.K_ESCAPE:
                app.should_close = true
            }
        }
    }
}

app_loop :: proc() -> bool {
    app_input()
    //update_cursor(player, crosshair_cursor)

    game_loop()

    sdl.RenderPresent(global_renderer)

    return app.should_close
}

app_init :: proc() {
    global_window = sdl.CreateWindow("Pebble", app.window_width, app.window_height, {})
    if global_window == nil do log.errorf("SDL window creation fail: %v", sdl.GetError())

    global_renderer = sdl.CreateRenderer(global_window, nil)
    if global_renderer == nil do log.errorf("SDL renderer creation fail: %v", sdl.GetError())
    sdl.SetRenderVSync(global_renderer, 1)
    
    // font
    app.font = ttf.OpenFont("assets/font1.ttf", 24)

    game_init()
}

app_close :: proc() {
    ttf.CloseFont(app.font)

    sdl.DestroyRenderer(global_renderer)
    sdl.DestroyWindow(global_window)

    game_close()
}
