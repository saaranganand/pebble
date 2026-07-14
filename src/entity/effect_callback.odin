package entity

import sdl "vendor:sdl3"

import primatives "../sdl_primatives"

import strings "core:strings"
import log "core:log"

Effect_Callback_String :: distinct string

// TODO
Lua_Effect_Callback :: struct {
    name: string,
}

Effect_Callback :: union {
    Odin_Effect_Callback,
    Lua_Effect_Callback,
}

Odin_Effect_Callback :: enum {
    DAMAGE,
    SPEED,
    POSITION,
    FORCE,
}

effect_callback_from_string :: proc(call_string: Effect_Callback_String) -> (callback: Effect_Callback) {
    pre_comma, _, post_comma := strings.partition(cast(string) call_string, ",")

    if pre_comma == "lua" {
        callback = Lua_Effect_Callback{ name = post_comma }
        return
    }

    callback = Odin_Effect_Callback{}

    switch post_comma {
    case "damage":
        callback = .DAMAGE
    case "speed":
        callback = .SPEED
    case "position":
        callback = .POSITION
    case "force":
        callback = .FORCE
    case:
        log.errorf("Error in creating effect callback from call string %v", call_string)
        callback = nil
    }

    return
}

Effect_Callback_Data :: struct {
    type: Odin_Effect_Callback,
    data: union {
        Effect_Damage_Fn_Data,
        Effect_Speed_Fn_Data,
        Effect_Position_Fn_Data,
        Effect_Force_Fn_Data,
    }
}

Effect_Damage_Fn_Data :: struct {
    damage: f32,
}

Effect_Speed_Fn_Data :: struct {
    mult: f32,
    add: f32,
}

Effect_Position_Fn_Data :: struct {
    direction: sdl.FPoint,
    speed: f32,
}

Effect_Force_Fn_Data :: Entity_Force

Effect_Damage_Fn   :: proc(data: Effect_Damage_Fn_Data,   target_entity: Entity) -> (damage: f32) {
    // TODO: add stuff like defense? aka entity impact in damage formula?
    damage = data.damage
    return
}
Effect_Speed_Fn    :: proc(data: Effect_Speed_Fn_Data,    target_entity: Entity) -> (new_speed: f32) {
    new_speed = (target_entity.move_speed + data.add) * data.mult
    return
}
Effect_Position_Fn :: proc(data: Effect_Position_Fn_Data, target_entity: Entity) -> (new_pos: sdl.FPoint) {
    new_pos = target_entity.position + data.direction * data.speed * primatives.dt
    return
}

effect_callback_trigger :: proc(state: ^Effect_State, target_entity: ^Entity) {
    if _, ok := state.instance.definition.callback.(Lua_Effect_Callback); ok {
        // TODO
        return
    }

    // We straight up just expect these types to be matching.
    // This should never ever be different, so panic-ing when its not is fine.
    switch state.instance.callback_data.type {
    case .DAMAGE:
        data := state.instance.callback_data.data.(Effect_Damage_Fn_Data)

        damage := Effect_Damage_Fn(data, target_entity^)
        entity_deal_damage(target_entity, damage)

    case .SPEED:
        data := state.instance.callback_data.data.(Effect_Speed_Fn_Data)

        target_entity.move_speed = Effect_Speed_Fn(data, target_entity^)

    case .POSITION:
        data := state.instance.callback_data.data.(Effect_Position_Fn_Data)

        // TODO: seperate position into a buffer and apply it at end of frame
        target_entity.position += Effect_Position_Fn(data, target_entity^)

    case .FORCE:
        data := state.instance.callback_data.data.(Effect_Force_Fn_Data)
        append(&target_entity.forces, data)
    }

}