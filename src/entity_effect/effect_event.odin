package effect

import sdl "vendor:sdl3"

import data_load "../data_load"
import handle "../handle"
import entity "../entity"

import log "core:log"
import fmt "core:fmt"

Effect_Event_Type :: enum { APPLY, TRIGGER, REMOVE }

Effect_Event :: struct {
    type: Effect_Event_Type,
    target: handle.Entity_Handle,
    target_team: entity.Team,
    definition_id: Effect_Definition_ID,
    // Kind of a catch all value.
    // Can be used to display damage amount as floating text,
    // or in an equation to determine screen shake based on amount of damage taken.
    magnitude: f32,
}