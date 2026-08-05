package main

import sdl "vendor:sdl3"
import ma "vendor:miniaudio"
import mu "vendor:microui"

import primatives "src:sdl_primatives"
import data_load "src:data_load"
import level_creator "src:level/creator"
import audio "src:data_load/audio"

import log "core:log"

App_State :: enum{ GAME, LEVEL_CREATOR }

@(rodata)
app_loops := [App_State]proc(){
    .GAME = game_loop,
    .LEVEL_CREATOR = level_creator.creator_loop,
}

App :: struct {
    display_id: sdl.DisplayID,
    screen_width, screen_height: i32,
    window_width, window_height: i32,
    fullscreen: bool,
    state: App_State,
    target_state: App_State,
    active_mu_ctx: Maybe(^mu.Context),

    prepare_shutdown: bool,
    shutdown_ready: bool,
}

app: App

app_create :: proc() {
    log.infof("\n\n\n\n==================== APP INITIALIZATION ====================")

    app.window_width = 800
    app.window_height = 800

    app.state = .GAME
    app.target_state = .GAME
    app.active_mu_ctx = nil

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

    level_creator.creator_init()

    // configs
    if !load_configs() do log.errorf("Failed to load game config")

    data_load.global_init()

    game_create()
}

app_destroy :: proc() {
    game_destroy()

    log.infof("\n\n\n\n==================== APP DE-INITIALIZATION ====================")

    level_creator.creator_destroy()

    primatives.global_renderer_destroy()
    primatives.global_window_destroy()
}

app_queue_state :: proc(new_state: App_State) {
    if new_state == app.state do log.warnf("Queuing new state %v that is already the state", new_state)

    app.target_state = new_state
}

app_switch_state :: proc() {
    if app.state == app.target_state do return
    app.state = app.target_state
    
    if app.state != .GAME do audio.pause_audio(.GAME)
    else do audio.resume_audio(.GAME)

    if app.state == .LEVEL_CREATOR {
        app.active_mu_ctx = &level_creator.mu_ctx
    }
}

// this proc will just handle things like auto saving progress
app_handle_shutdown :: proc() {
    app.shutdown_ready = true
}

// returns true if shutting down
app_loop :: proc() -> bool {
    if app.prepare_shutdown {
        app_handle_shutdown()
        return app.shutdown_ready
    }

    // deltatime
    primatives.global_timer_update()

    handle_app_input(poll_app_input())

    app_loops[app.state]()

    sdl.RenderPresent(primatives.global_renderer)

    app_switch_state()

    return false
}