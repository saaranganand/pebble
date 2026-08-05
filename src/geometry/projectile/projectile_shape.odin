package projectile

import entity "src:entity"
import handle "src:handle"

import rand "core:math/rand"

Shape :: union #no_nil { Circle, Ray, Line, Tracking_Line }

Circle :: struct { radius: f32, }
Ray :: struct {}
Line :: struct { length: f32 }
Tracking_Line :: struct {
    length: f32,
    tracking: handle.Entity_Handle,
    tracking_team: entity.Team,
    turn_speed: f32,
}

projectile_Shape_tracking_line_init :: proc(state: ^Projectile_State, tline: ^Tracking_Line) {
    tline.tracking_team = entity.Team.ALLY
    if state.team == .ALLY do tline.tracking_team = .ENEMY
    tline.tracking = entity.entity_manager_get_random_handle(tline.tracking_team)

    RANDOM_SPAWN_RANGE :: 10
    state.position += { rand.float32_range(-RANDOM_SPAWN_RANGE, RANDOM_SPAWN_RANGE), rand.float32_range(-RANDOM_SPAWN_RANGE, RANDOM_SPAWN_RANGE) }
}
