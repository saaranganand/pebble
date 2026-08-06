package main

import sdl "vendor:sdl3"
import mu "vendor:microui"

import primatives "src:sdl_primatives"
import data_load "src:data_load"
import room_creator "src:level/room/creator"
import level_creator "src:level/creator"
import audio "src:data_load/audio"

import log "core:log"

App_State :: enum{ GAME, ROOM_CREATOR, LEVEL_CREATOR }

@(rodata)
app_state_loops := [App_State]proc(){
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

app_state_init_procs := [App_State]proc() {
    .GAME = game_create,
    .ROOM_CREATOR = room_creator.creator_init,
    .LEVEL_CREATOR = level_creator.creator_init,
}

app_states_init :: proc() {
    for state in App_State do app_state_init_procs[state]()
}

app_state_destruct_procs := [App_State]proc() {
    .GAME = game_destroy,
    .ROOM_CREATOR = room_creator.creator_destroy,
    .LEVEL_CREATOR = level_creator.creator_destroy,
}

app_states_destroy :: proc() {
    for state in App_State do app_state_destruct_procs[state]()
}