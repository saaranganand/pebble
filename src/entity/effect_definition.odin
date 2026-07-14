package entity

import sdl "vendor:sdl3"

import handle "../handle"
import geo "../geometry"

Effect_Handle :: handle.Handle(handle.Effect_Tag)

// Defines what happens when an effect is attempted to be applied to an entity that already has said effect.
// NONE:    the effect is not applied
// REFRESH: the effect is applied, and the exisiting effect is removed. If the effect is pulse, then an extra pulse occurs.
// STACK:   the effect is applied
// EXTEND:  the effect is applied with its duration absorbing the remaining time left of the existing effect. The exisiting effect is removed.
//          if the effect is pulse, then the new effect's max applications absorbs the remaining applications of the exisiting effect.
Stack_Behaviour :: enum { NONE, REFRESH, STACK, EXTEND }

Effect_Type :: enum { PULSE, CONTINUOUS }

Effect_Definition_Tag :: distinct string

Effect_Definition_ID :: distinct u32

// TODO: store definitions in a allocated slice (not dynamic array)
Effect_Definition :: struct {
    callback: Effect_Callback,
    unique_id: Effect_Definition_ID,
    unique_tag: Effect_Definition_Tag,
    stack_behaviour: Stack_Behaviour,
    type: Effect_Type,
}