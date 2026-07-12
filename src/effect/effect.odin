package effect

import sdl "vendor:sdl3"

import handle "../handle"
import geo "../geometry"

// TODO
Lua_Effect_Fn :: struct {
    name: string,
}

Health_Fn :: proc(health: f32) -> f32
Speed_Fn :: proc(speed: f32) -> f32
Position_Fn :: proc(position: sdl.FPoint) -> sdl.FPoint
Force_Fn :: proc()

Odin_Effect_Fn :: enum {
    HEALTH,
    SPEED,
    POSITION,
    FORCE,
}

Effect_Fn :: union {
    Odin_Effect_Fn,
    Lua_Effect_Fn,
}

// Defines what happens when an effect is attempted to be applied to an entity that already has said effect.
// NONE:    the effect is not applied
// REFRESH: the effect is applied, and the exisiting effect is removed. If the effect is pulse, then an extra pulse occurs.
// STACK:   the effect is applied
// EXTEND:  the effect is applied with its duration absorbing the remaining time left of the existing effect. The exisiting effect is removed.
//          if the effect is pulse, then the new effect's max applications absorbs the remaining applications of the exisiting effect.
Stack_Behaviour :: enum { NONE, REFRESH, STACK, EXTEND }

Effect_Def_Tag :: distinct string

Effect_Type :: enum { PULSE, CONTINUOUS }

Effect_Definition :: struct {
    fn: Effect_Fn,
    unique_tag: Effect_Def_Tag,
    stack_behaviour: Stack_Behaviour,
    type: Effect_Type,
}

// This both stores all the instance-specific data about the effect, as well as the effect's state (aka its progress)
// Basically, the burn effect does the same thing, but different burn effects applied by different sources might do different damage,
// last different amount of times, etc.
Effect_State :: struct {
    // Definitions
    def: ^Effect_Definition,
    damage: f32,
    duration: f32,

    // State
    elapsed: f32,
    source, target: handle.Entity_Handle,
    type_state: union {
        Pulse_State,
        Continuous_State,
    }
}

// Pulse effects call the callback X times per second
Pulse_State :: struct {
    applications: int,
    max_applications: int,
    interval: f32,
    time_since_last_tick: f32,
}

// Continuous effects call the callback every frame
Continuous_State :: struct {}

// This bad boy fits all the improper data accesses you could ever need.
// Basically, there are some complex effects, like ex. a pulse effect that spreads its effect to other entities nearby,
// that require data from outside the package. Since any package that deals with effects needs to import this one,
// this package cannot import it in return, thus leaving the package stranded.
// The solution is to give the effect manager some abilities it prooobably shouldnt have, via ambiguous callbacks.
// IMO, this is a safe-enough solution that provides a compromise between data safety, and usablity/convienience.
query_entities_in_radius :: proc(geo.Circle) -> []handle.Entity_Handle
apply_effect_to_entity :: proc(target: handle.Entity_Handle, def: ^Effect_Definition, source: handle.Entity_Handle)

Effect_Context :: struct {
    query_in_radius: query_entities_in_radius,
    apply_effect: apply_effect_to_entity,
}