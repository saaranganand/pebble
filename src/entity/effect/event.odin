package effect

import sdl "vendor:sdl3"

import data_load "src:data_load"
import handle "src:handle"
import entity "src:entity"
import util "src:util"

import log "core:log"
import fmt "core:fmt"

Effect_Event_Type :: enum { APPLY, TRIGGER, REMOVE }

Effect_Event :: struct {
    type: Effect_Event_Type,
    target: util.Handle,
    target_team: entity.Team,
    definition_id: uint,
    // Kind of a catch all value.
    // Can be used to display damage amount as floating text,
    // or in an equation to determine screen shake based on amount of damage taken.
    magnitude: f32,
}