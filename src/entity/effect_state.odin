package entity

// This both stores all the instance-specific data about the effect, as well as the effect's state (aka its progress)
// Basically, the burn effect does the same thing, but different burn effects applied by different sources might do different damage,
// last different amount of times, etc.
Effect_State :: struct {
    instance: ^Effect_Instance,

    source, target: Entity_Handle,

    active: bool,

    elapsed: f32,
    time_since_last_tick: f32,
    applications: int,

    // Inherited from instance.
    // These need to be inherited because they could be extended by stacking behaviour
    duration: f32,
    max_applications: int,
}

effect_state_create :: proc(instance: ^Effect_Instance, source, target: Entity_Handle) -> (state: Effect_State) {
    state.instance = instance

    state.source = source
    state.target = target

    state.active = true

    state.elapsed = 0
    state.time_since_last_tick = 0
    state.applications = 0
    
    //inherited from instance
    state.duration = instance.duration
    state.max_applications = instance.max_applications

    return
}

// TODO:
// In both cases of refresh and extend, we currently only deal with timing values of the state.
// Currently, we just keep the existing effect. But, should there be logic in which one is kept?
// If a player reapplies burn to an enemy, should it keep the higher damage amount?
// If an enemy reapplies burn to a player, should it keep the higher, or lower damage amount? 

effect_state_refresh :: proc(state: ^Effect_State) {
    // TODO: trigger the effect on refresh if its a pulse
    state.elapsed = 0
    state.time_since_last_tick = 0
    state.applications = 0
}

effect_state_extend :: proc(state: ^Effect_State) {
    // Extend duration by remaining time
    state.duration += state.instance.duration - state.elapsed

    // Extend max applications by remaining applications
    state.max_applications += state.instance.max_applications - state.applications
}

effect_state_update :: proc(state: ^Effect_State) -> (should_remove: bool) {
    // TODO
    return
}