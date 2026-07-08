package geometry

import sdl "vendor:sdl3"

import math "core:math"

get_point_distance_squared :: proc(a, b: sdl.FPoint) -> f32 {
    return math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2)
}

get_point_distance :: proc(a, b: sdl.FPoint) -> f32 {
    return math.sqrt( math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2))
}

normalize_point :: proc(p: sdl.FPoint) -> sdl.FPoint {
    magnitude := math.sqrt( math.pow(p.x, 2) + math.pow(p.y, 2) )
    // avoids diving by zero
    if magnitude == 0 do return p

    return p / magnitude
}