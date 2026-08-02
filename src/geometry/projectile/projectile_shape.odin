package projectile

import yaml "../../../libs/odin-yaml"

import yaml_parse "src:data_load/yaml_parse"
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
    tline.tracking = entity.entity_manager_get_random_handle(tline.tracking_team)

    RANDOM_SPAWN_RANGE :: 10
    state.position += { rand.float32_range(-RANDOM_SPAWN_RANGE, RANDOM_SPAWN_RANGE), rand.float32_range(-RANDOM_SPAWN_RANGE, RANDOM_SPAWN_RANGE) }
}

projectile_shape_from_category :: proc(category: Category, team: entity.Team, shape_data: yaml.Mapping) -> (shape: Shape) {
    switch category {
    case .BULLET:
        fallthrough
    case .RADIAL:
        fallthrough
    case .AOE:
        radius := yaml_parse.read_value_from_map(shape_data, "shape_radius", f64, default = 0.0)
        return Circle{ radius = f32(radius) }
	case .RAY:
        return Ray{}
	case .LINE:
        length := yaml_parse.read_value_from_map(shape_data, "shape_length", f64, default = 0.0)
        return Line{ length = f32(length) }
    case .TRACKING_ARROW:
        ret := Tracking_Line{}

        ret.length = cast(f32) yaml_parse.read_value_from_map(shape_data, "shape_length", f64, default = 0.0)
        ret.turn_speed = cast(f32) yaml_parse.read_value_from_map(shape_data, "turn_speed", f64, default = 0.0)

        ret.tracking_team = entity.Team.ENEMY
        if team == .ENEMY do ret.tracking_team = .ALLY

        return ret
    }

    return Circle{}
}