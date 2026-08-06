package main

import sdl "vendor:sdl3"
import ma "vendor:miniaudio"
import mu "vendor:microui"

import primatives "src:sdl_primatives"
import data_load "src:data_load"
import room_creator "src:level/room/creator"
import level_creator "src:level/creator"
import audio "src:data_load/audio"

import log "core:log"

App_State :: enum{ GAME, ROOM_CREATOR, LEVEL_CREATOR }

@(rodata)
app_loops := [App_State]proc(){
    .GAME = game_loop,
    .ROOM_CREATOR = room_creator.creator_loop,
    .LEVEL_CREATOR = level_creator.creator_loop,
}

@(rodata)
app_state_shortkeys := [App_State]sdl.Keycode {
    .GAME = sdl.K_F1,
    .ROOM_CREATOR = sdl.K_F2,
    .LEVEL_CREATOR = sdl.K_F3,
}

App :: struct {
    display_id: sdl.DisplayID,
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

    primatives.window_width = 800
    primatives.window_height = 800

    default_state :: App_State.GAME
    app.state = default_state
    app.target_state = .ROOM_CREATOR
    app.active_mu_ctx = nil

    app_switch_state()

    primatives.global_window_create(primatives.window_width, primatives.window_height)
    // We call this immediately because of window display scale
    // for example a HiDPI display could use the same window positioning, but have twice as many pixels.
    // On such a display, when we set our window to a size, it will actually have a pixel size of 2x.
    // Since we will be using our window size for rendering, this is important, and as such,
    // we need to immediately read the window's pixel size using this procedure.
    primatives.global_window_read_size(&primatives.window_width, &primatives.window_height)
    app.display_id = primatives.global_window_read_screen_size(&primatives.screen_width, &primatives.screen_height)

    primatives.global_renderer_create()
    primatives.global_renderer_set_vsync()

    // configs
    if !load_configs() do log.errorf("Failed to load game config")

    data_load.global_init()

    room_creator.creator_init()

    game_create()
}

app_destroy :: proc() {
    game_destroy()

    log.infof("\n\n\n\n==================== APP DE-INITIALIZATION ====================")

    room_creator.creator_destroy()

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

    if app.state == .ROOM_CREATOR {
        app.active_mu_ctx = &room_creator.ui.mu_ctx
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