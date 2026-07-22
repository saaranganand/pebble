package projectile

import yaml "../../libs/odin-yaml"

import yaml_parse "../assets/yaml_parse"

Shape :: union #no_nil { Circle, Ray, Line, }

Circle :: struct { radius: f32, }
Ray :: struct {}
Line :: struct { length: f32 }

projectile_shape_from_category :: proc(category: Category, shape_data: yaml.Mapping) -> (shape: Shape) {
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
    }

    return Circle{}
}