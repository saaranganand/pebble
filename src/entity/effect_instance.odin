package entity

import sdl "vendor:sdl3"

import handle "../handle"
import geo "../geometry"

Effect_Instance_Tag :: distinct string

// TODO: store instances in a allocated slice (not dynamic array)
Effect_Instance :: struct {
    definition: ^Effect_Definition,
    unique_tag: Effect_Instance_Tag,
    duration: f32,
    interval: f32,

    callback_data: Effect_Callback_Data,
}