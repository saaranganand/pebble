package entity

import sdl "vendor:sdl3"

import handle "../handle"
import geo "../geometry"

Effect_Instance_Tag :: distinct string

Effect_Instance_ID :: distinct u32

// TODO: store instances in a allocated slice (not dynamic array)
Effect_Instance :: struct {
    definition: ^Effect_Definition,
    unique_tag: Effect_Instance_Tag,
    unique_id: Effect_Instance_ID,

    duration: f32,
    interval: f32,

    callback_data: Effect_Callback_Data,
}