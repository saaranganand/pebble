package effect

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import data_load "src:data_load"
import entity "src:entity"

import strings "core:strings"
import log "core:log"

Effect_Callback :: enum {
    DAMAGE,
    SPEED,
    POSITION,
    FORCE,
}
/*
Effect_Fn_Data :: union {
    Effect_Damage_Fn_Data,
    Effect_Speed_Fn_Data,
    Effect_Position_Fn_Data,
    Effect_Force_Fn_Data,
}

effect_fn_data_to_type :: proc(fn_data: Effect_Fn_Data) -> (type: Effect_Callback) {
    switch d in fn_data {
    case Effect_Damage_Fn_Data:
        return .DAMAGE
	case Effect_Speed_Fn_Data:
        return .SPEED
	case Effect_Position_Fn_Data:
        return .POSITION
	case Effect_Force_Fn_Data:
        return .FORCE
    }

    return .DAMAGE
}


*/

effect_fn_data_get_reaction_magnitude :: proc(data: Effect_Callback_Data) -> (magnitude: f32) {
    if "damage" in data do return data["damage"].(f32)
    if "mult" in data do return data["mult"].(f32)
    if "speed" in data do return data["speed"].(f32)

    return 0
}

Effect_Callback_Data_Type :: union{
    string, f32, sdl.FPoint,
}

Effect_Callback_Data_Override :: struct{
    tag: string,
    data: Effect_Callback_Data_Type,
}

Effect_Callback_Data :: map[string]Effect_Callback_Data_Type
/*
Effect_Callback_Data_Shell :: struct {
    type: Effect_Callback,

    data_damage: f32,
    data_mult: f32,
    data_add: f32,
    data_direction: sdl.FPoint,
    data_speed: f32,
    data_force: f32,
    data_decay_rate: f32,
}

Effect_Callback_Data :: struct {
    type: Effect_Callback,
    data: Effect_Fn_Data
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

Effect_Force_Fn_Data :: entity.Force
*/

effect_damage_fn   :: proc(data: Effect_Callback_Data, target_entity: entity.Entity) -> (damage: f32) {
    // TODO: add stuff like defense? aka entity impact in damage formula?
    damage = data["damage"].(f32)
    return
}
effect_speed_fn    :: proc(data: Effect_Callback_Data, target_entity: entity.Entity) -> (new_speed: f32) {
    new_speed = (target_entity.move_speed + data["add"].(f32)) * data["mult"].(f32)
    return
}
effect_position_fn :: proc(data: Effect_Callback_Data, target_entity: entity.Entity) -> (new_pos: sdl.FPoint) {
    new_pos = target_entity.position + data["direction"].(sdl.FPoint) * data["speed"].(f32) * primatives.dt
    return
}

effect_callback_trigger :: proc(state: ^Effect_State, target_entity: ^entity.Entity) {

    // We straight up just expect these types to be matching.
    // This should never ever be different, so panic-ing when its not is fine.
    switch state.instance.definition.callback {
    case .DAMAGE:
        damage := effect_damage_fn(state.callback_data, target_entity^)
        entity.entity_deal_damage(target_entity, damage)

    case .SPEED:
        target_entity.move_speed = effect_speed_fn(state.callback_data, target_entity^)

    case .POSITION:
        // TODO: seperate position into a buffer and apply it at end of frame
        target_entity.position += effect_position_fn(state.callback_data, target_entity^)

    case .FORCE:
        //data := state.callback_data.data.(Effect_Force_Fn_Data)
        //append(&target_entity.forces, data)
    }

}