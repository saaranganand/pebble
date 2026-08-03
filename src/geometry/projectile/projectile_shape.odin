package projectile

import entity "src:entity"
import handle "src:handle"

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