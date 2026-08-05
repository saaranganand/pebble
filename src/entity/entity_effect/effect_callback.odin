package effect

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import data_load "src:data_load"
import script "src:script"
import entity "src:entity"

import strings "core:strings"
import log "core:log"

Effect_Callback :: enum {
    DAMAGE,
    SPEED,
    POSITION,
    FORCE,
    HEAL,
    LUA,
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
    if "amount" in data do return data["amount"].(f32)
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
effect_heal_fn     :: proc(data: Effect_Callback_Data, target_entity: entity.Entity) -> (heal: f32) {
    heal = data["amount"].(f32)
    return
}

// Scratch buffer for handing an instance's numeric callback data to Lua.
// Reused across triggers so a scripted effect does not allocate a map every pulse.
@(private)
lua_param_scratch: map[string]f32

@(private)
effect_lua_params_from_callback_data :: proc(data: Effect_Callback_Data) -> map[string]f32 {
    if lua_param_scratch == nil do lua_param_scratch = make(map[string]f32)
    clear(&lua_param_scratch)

    for key, value in data {
        #partial switch v in value {
        case f32:
            lua_param_scratch[key] = v
        }
    }

    return lua_param_scratch
}

effect_callback_lua_params_destroy :: proc() {
    delete(lua_param_scratch)
    lua_param_scratch = nil
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

    case .HEAL:
        entity.entity_heal(target_entity, effect_heal_fn(state.callback_data, target_entity^))

    case .LUA:
        script.script_run_effect_callback(
            state.instance.definition.lua_callback,
            target_entity,
            effect_lua_params_from_callback_data(state.callback_data),
        )
    }

}