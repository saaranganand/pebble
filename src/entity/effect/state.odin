package effect

import primatives "src:sdl_primatives"
import handle "src:handle"
import entity "src:entity"
import util "src:util"

// This both stores all the instance-specific data about the effect, as well as the effect's state (aka its progress)
// Basically, the burn effect does the same thing, but different burn effects applied by different sources might do different damage,
// last different amount of times, etc.
Effect_State :: struct {
    instance: ^Effect_Instance,

    source, target: util.Handle,
    target_team: entity.Team,

    active: bool,

    elapsed: f32,
    time_since_last_tick: f32,

    // Inherited from instance.
    // These need to be inherited because they could be extended by stacking behaviour or overrided
    duration: f32,
    interval: f32,
    callback_data: Effect_Callback_Data,
}

effect_state_create :: proc(
    application_data: Effect_Application_Data
) -> (state: Effect_State) {
    state.instance = application_data.instance

    state.source = application_data.source
    state.target = application_data.target
    state.target_team = application_data.target_team

    state.active = true

    state.elapsed = 0
    state.time_since_last_tick = 0
    
    //inherited from instance
    state.duration = state.instance.duration
    state.interval = state.instance.interval
    state.callback_data = application_data.callback_data

    return
}

/*
effect_state_override_data :: proc(callback_data: ^Effect_Callback_Data, override_data: Effect_Fn_Data) -> (success: bool) {
    exisiting_data_type := callback_data.type
    expected_data_type := effect_fn_data_to_type(override_data)

    if exisiting_data_type != expected_data_type do return false

    callback_data.data = override_data
    return true
}
*/

// TODO:
// In both cases of refresh and extend, we currently only deal with timing values of the state.
// Currently, we just keep the existing effect. But, should there be logic in which one is kept?
// If a player reapplies burn to an enemy, should it keep the higher damage amount?
// If an enemy reapplies burn to a player, should it keep the higher, or lower damage amount? 

effect_state_refresh :: proc(state: ^Effect_State) {
    state.duration = state.duration + state.elapsed
}

effect_state_extend :: proc(state: ^Effect_State, new_instance: Effect_Instance) {
    // Extend duration
    state.duration += new_instance.duration
}

effect_state_update :: proc(state: ^Effect_State, target_entity: ^entity.Entity) -> (should_remove: bool) {
    should_remove = false
    should_call := false

    defer state.elapsed += primatives.dt

    is_ending := state.elapsed > state.duration

    switch state.instance.definition.type {
    case .PULSE:
        defer state.time_since_last_tick += primatives.dt

        should_trigger := state.time_since_last_tick >= state.interval - (primatives.dt / 10) // with margin
        if should_trigger {
            // If we just set time since last tick to 0, it won't take into account the excess caused by framerate.
            // Thus, subtract the interval, to retain the excess.
            state.time_since_last_tick -= state.interval

            should_call = true
        }
    case .CONTINUOUS:
        // just call the callback
        should_call = true
        
    case .SINGLE:
        should_call = true
        is_ending = true
    }

    if should_call {
        effect_callback_trigger(state, target_entity)

        effect_manager_queue_event(Effect_Event{
            type = .TRIGGER, target = state.target,
            target_team = state.target_team,
            definition_id = state.instance.definition.unique_id,
            magnitude = effect_fn_data_get_reaction_magnitude(state.callback_data)
        })
    }

    if is_ending {
        should_remove = true
        state.active = false
    }

    return
}
