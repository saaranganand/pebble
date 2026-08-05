package main

import sdl "vendor:sdl3"
import mu "vendor:microui"
import log "core:log"

import primatives "src:sdl_primatives"
import util "src:util"

APP_SHUTDOWN_KEY :: sdl.K_ESCAPE

// Generated every frame, and handled that frame
App_Input :: struct {
    exit: bool,

    maximize, minimize: bool,
    // When you maximize a window, and then click the maximize button again,
    // it gets restored to the size it was before it was maximized.
    min_max_restored: bool,
    gain_focus, lose_focus: bool,
    enter_fullscreen, leave_fullscreen: bool,
    new_display: bool,
    resized: bool,
}

handle_app_input :: proc(input: App_Input) {
    // we set prepare shutdown to an exit event,
    // but we dont want to remove the prepare shutdown flag if shutdown is taking multple frames,
    // and an exit event could last for only one frame
    if !app.prepare_shutdown do app.prepare_shutdown = input.exit

    if input.minimize {
        log.infof("Window was minimized")
        // pause the game
        // probably should use a special type of pause that only minimizing can cause
    }

    if input.enter_fullscreen {
        log.infof("Window entered fullscreen")
        app.fullscreen = true
    }
    if input.leave_fullscreen {
        log.infof("Window exited fullscreen")
        app.fullscreen = false
    }

    if input.new_display {
        app.display_id = primatives.global_window_read_screen_size(&app.screen_width, &app.screen_height)
    }

    should_read_window_size := false

    should_read_window_size |= 
        input.maximize         ||
        input.min_max_restored ||
        input.enter_fullscreen ||
        input.leave_fullscreen ||
        input.resized          ||
        // If a window moves to a higher scale resolution monitor,
        // its pixel size changes with it
        input.new_display
        
    if should_read_window_size do primatives.global_window_read_size(&app.window_width, &app.window_height)
}

poll_app_input :: proc() -> (input: App_Input) {
    event: sdl.Event
    for sdl.PollEvent(&event) {
        mu_ctx, mu_ctx_ok := app.active_mu_ctx.(^mu.Context)
        if mu_ctx_ok do util.mu_ctx_read_input(event, mu_ctx)

        input.exit |= event.type == .WINDOW_CLOSE_REQUESTED || event.type == .QUIT

        input.minimize |= event.type == .WINDOW_MINIMIZED
        input.maximize |= event.type == .WINDOW_MAXIMIZED
        input.min_max_restored |= event.type == .WINDOW_RESTORED

        input.new_display |= event.type == .WINDOW_DISPLAY_CHANGED

        input.resized |= event.type == .WINDOW_RESIZED || event.type == .WINDOW_PIXEL_SIZE_CHANGED

        input.gain_focus |= event.type == .WINDOW_FOCUS_GAINED
        input.lose_focus |= event.type == .WINDOW_FOCUS_LOST

        input.enter_fullscreen |= event.type == .WINDOW_ENTER_FULLSCREEN
        input.leave_fullscreen |= event.type == .WINDOW_LEAVE_FULLSCREEN

        #partial switch event.type {
        case .KEY_DOWN:
            input.exit |= event.key.key == APP_SHUTDOWN_KEY

            if event.key.key == sdl.K_F1 {
                app_queue_state(.GAME)
            }

            if event.key.key == sdl.K_F2 {
                app_queue_state(.LEVEL_CREATOR)
            }
        }
    }

    return
}