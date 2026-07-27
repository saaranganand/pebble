package geometry

import sdl "vendor:sdl3"

import math "core:math"

import primatives "../sdl_primatives"

Circle :: struct {
    position: sdl.FPoint,
    radius: f32,
}

are_circles_colliding :: proc(a, b: Circle) -> bool {
    return math.pow(a.radius + b.radius, 2) >= get_point_distance_squared(a.position, b.position)
}

line_circle_colliding :: proc(a_pos: sdl.FPoint, a_angle: f32, b: Circle) -> bool {
    dir := sdl.FPoint{math.cos(a_angle), math.sin(a_angle)}
    to_circle := b.position - a_pos

    // project to_circle onto dir to find closest point on ray
    t := to_circle.x * dir.x + to_circle.y * dir.y
    t = max(t, 0) // clamp so we don't check behind the ray's start

    closest := a_pos + dir * t
    diff := b.position - closest
    dist_sq := diff.x * diff.x + diff.y * diff.y

    return dist_sq <= b.radius * b.radius
}

line_angle_segment_circle_colliding :: proc(a_pos: sdl.FPoint, a_length: f32, a_angle: f32, b: Circle) -> bool {
    dir := sdl.FPoint{math.cos(a_angle), math.sin(a_angle)}
    to_circle := b.position - a_pos

    t := to_circle.x * dir.x + to_circle.y * dir.y
    t = clamp(t, 0, a_length) // clamp to segment length

    closest := a_pos + dir * t
    diff := b.position - closest
    dist_sq := diff.x * diff.x + diff.y * diff.y

    return dist_sq <= b.radius * b.radius
}

line_segment_circle_colliding :: proc(a_start_pos: sdl.FPoint, a_end_pos: sdl.FPoint, b: Circle) -> bool {
    seg := a_end_pos - a_start_pos
    to_circle := b.position - a_start_pos

    // project to_circle onto dir to find closest point on ray
    seg_len_sq := seg.x * seg.x + seg.y * seg.y
    t: f32 = 0
    if seg_len_sq > 0 {
        t = (to_circle.x * seg.x + to_circle.y * seg.y) / seg_len_sq
        t = clamp(t, 0, 1) // clamp to segment, not infinite line
    }

    closest := a_start_pos + seg * t
    diff := b.position - closest
    dist_sq := diff.x * diff.x + diff.y * diff.y

    return dist_sq <= b.radius * b.radius
}

// midpoint algorithm
draw_circle :: proc(c: Circle) {
    point_buffer_size := (int(c.radius) + 1) * 8
    draw_points := make([dynamic]sdl.FPoint, 0, point_buffer_size)
    defer delete(draw_points)

    offset_x: f32 = 0
    offset_y := c.radius
    d := 1 - c.radius

    for offset_x <= offset_y {
        append(&draw_points, sdl.FPoint{ (c.position.x + offset_x + 0.5), (c.position.y - offset_y + 0.5) })
        append(&draw_points, sdl.FPoint{ (c.position.x + offset_x + 0.5), (c.position.y + offset_y + 0.5) })
        append(&draw_points, sdl.FPoint{ (c.position.x - offset_x + 0.5), (c.position.y - offset_y + 0.5) })
        append(&draw_points, sdl.FPoint{ (c.position.x - offset_x + 0.5), (c.position.y + offset_y + 0.5) })
        append(&draw_points, sdl.FPoint{ (c.position.x + offset_y + 0.5), (c.position.y - offset_x + 0.5) })
        append(&draw_points, sdl.FPoint{ (c.position.x + offset_y + 0.5), (c.position.y + offset_x + 0.5) })
        append(&draw_points, sdl.FPoint{ (c.position.x - offset_y + 0.5), (c.position.y - offset_x + 0.5) })
        append(&draw_points, sdl.FPoint{ (c.position.x - offset_y + 0.5), (c.position.y + offset_x + 0.5) })

        if d < 0 {
            d += 2 * offset_x + 3
        } else {
            d += 2 * (offset_x - offset_y) + 5
            offset_y -= 1
        }
        offset_x += 1
    }

    sdl.RenderPoints(primatives.global_renderer, raw_data(draw_points), i32(len(draw_points)))
}

// does the previous algorithm, eight points are combined into 4 lines
// lines are split into seperate loops to allow for accurate ordering in drawing the lines
// circle is filled via scanlines
fill_circle :: proc(c: Circle) {
    Row :: struct { y, x1, x2: f32 }

    row_buffer_size := int(c.radius) + 1
    outer_top    := make([dynamic]Row, 0, row_buffer_size)
    inner_top    := make([dynamic]Row, 0, row_buffer_size)
    inner_bottom := make([dynamic]Row, 0, row_buffer_size)
    outer_bottom := make([dynamic]Row, 0, row_buffer_size)
    defer delete(outer_top)
    defer delete(inner_top)
    defer delete(inner_bottom)
    defer delete(outer_bottom)

    offset_x: f32 = 0
    offset_y := c.radius
    d := 1 - c.radius

    for offset_x <= offset_y {
        append(&outer_top,    Row{ c.position.y - offset_y, c.position.x - offset_x, c.position.x + offset_x })
        append(&inner_top,    Row{ c.position.y - offset_x, c.position.x - offset_y, c.position.x + offset_y })
        append(&inner_bottom, Row{ c.position.y + offset_x, c.position.x - offset_y, c.position.x + offset_y })
        append(&outer_bottom, Row{ c.position.y + offset_y, c.position.x - offset_x, c.position.x + offset_x })

        if d < 0 {
            d += 2 * offset_x + 3
        } else {
            d += 2 * (offset_x - offset_y) + 5
            offset_y -= 1
        }
        offset_x += 1
    }

    points := make([dynamic]sdl.FPoint, 0, row_buffer_size * 8)
    defer delete(points)
    add_row :: proc(points: ^[dynamic]sdl.FPoint, row: Row, left_to_right: bool) {
        if left_to_right {
            append(points, sdl.FPoint{ row.x1, row.y }, sdl.FPoint{ row.x2, row.y })
        } else {
            append(points, sdl.FPoint{ row.x2, row.y }, sdl.FPoint{ row.x1, row.y })
        }
    }

    ltr := true
    for row in outer_top {
        add_row(&points, row, ltr); ltr = !ltr
    }
    #reverse for row in inner_top {
        add_row(&points, row, ltr); ltr = !ltr
    }
    for row in inner_bottom {
        add_row(&points, row, ltr); ltr = !ltr
    }
    #reverse for row in outer_bottom {
        add_row(&points, row, ltr); ltr = !ltr
    }

    sdl.RenderLines(primatives.global_renderer, raw_data(points), i32(len(points)))
}