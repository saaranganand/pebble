package geometry

import sdl "vendor:sdl3"

import linalg "core:math/linalg"
import math "core:math"

get_point_distance_squared :: proc(a, b: sdl.FPoint) -> f32 {
    return math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2)
}

get_point_distance :: proc(a, b: sdl.FPoint) -> f32 {
    return math.sqrt( math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2))
}

normalize_point :: proc(p: sdl.FPoint) -> sdl.FPoint {
    if linalg.length2(p) < 1e-12 do return {0,0}
    return linalg.normalize(p)
}

quake_square_root :: proc(a: f32) -> f32 {
    b := transmute(i32)a
    b = 0x5f3759df - (b >> 1)
    c := transmute(f32)b

    return c * (1.5 - 0.5 * a * c * c)
}

normalize_point_quake :: proc(p: sdl.FPoint) -> sdl.FPoint {
    length_squared := p.x*p.x + p.y*p.y
    if length_squared < 1e-12 do return {0,0}

    inverse_length := quake_square_root(length_squared)
    return p * inverse_length
}

line_rect_intersection :: proc(start: sdl.FPoint, angle: f32, rect: sdl.FRect) -> sdl.FPoint {
     // clockwise, 0 = right
    dir := sdl.FPoint{math.cos(angle), math.sin(angle)}

    t_max: f32 = math.F32_MAX

    if dir.x != 0 {
        t1: f32 = (rect.x - start.x) / dir.x
        t2: f32 = (rect.x + rect.w - start.x) / dir.x
        t_max = min(t_max, max(t1, t2))
    }

    if dir.y != 0 {
        t1 := (rect.y - start.y) / dir.y
        t2 := (rect.y + rect.h - start.y) / dir.y
        t_max = min(t_max, max(t1, t2))
    }

    return start + dir * t_max
}