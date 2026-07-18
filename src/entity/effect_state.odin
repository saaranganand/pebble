package entity

import primatives "../sdl_primatives"

import log "core:log"

// This both stores all the instance-specific data about the effect, as well as the effect's state (aka its progress)
// Basically, the burn effect does the same thing, but different burn effects applied by different sources might do different damage,
// last different amount of times, etc.
Effect_State :: struct {
    instance: ^Effect_Instance,

    source, target: Entity_Handle,

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

    state.active = true

    state.elapsed = 0
    state.time_since_last_tick = 0
    
    //inherited from instance
    state.duration = state.instance.duration
    state.interval = state.instance.interval
    state.callback_data = application_data.callback_data

    return
}

effect_state_override_data :: proc(callback_data: ^Effect_Callback_Data, override_data: Effect_Fn_Data) -> (success: bool) {
    exisiting_data_type := callback_data.type
    expected_data_type := effect_fn_data_to_type(override_data)

    if exisiting_data_type != expected_data_type do return false

    callback_data.data = override_data
    return true
}

// TODO:
// In both cases of refresh and extend, we currently only deal with timing values of the state.
// Currently, we just keep the existing effect. But, should there be logic in which one is kept?
// If a player reapplies burn to an enemy, should it keep the higher damage amount?
// If an enemy reapplies burn to a player, should it keep the higher, or lower damage amount? 

effect_state_refresh :: proc(entity_manager: ^Entity_Manager, state: ^Effect_State) {
    state.duration = state.duration + state.elapsed
}

effect_state_extend :: proc(state: ^Effect_State, new_instance: Effect_Instance) {
    // Extend duration
    state.duration += new_instance.duration
}

effect_state_update :: proc(state: ^Effect_State, target_entity: ^Entity) -> (should_remove: bool) {
    should_remove = false

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

            effect_callback_trigger(state, target_entity)
        }
    case .CONTINUOUS:
        // just call the callback
        effect_callback_trigger(state, target_entity)
    case .SINGLE:
        effect_callback_trigger(state, target_entity)
        is_ending = true
    }

    if is_ending {
        should_remove = true
        state.active = false
    }

    return
}