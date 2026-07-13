package entity

import sdl "vendor:sdl3"

// TODO
Lua_Effect_Callback :: struct {
    name: string,
}

Health_Fn :: proc(health: f32) -> f32
Speed_Fn :: proc(speed: f32) -> f32
Position_Fn :: proc(position: sdl.FPoint) -> sdl.FPoint
Force_Fn :: proc()

Odin_Effect_Callback_Data :: union {
    
}

Odin_Effect_Callback :: enum {
    HEALTH,
    SPEED,
    POSITION,
    FORCE,
}

Effect_Callback :: union {
    Odin_Effect_Callback,
    Lua_Effect_Callback,
}