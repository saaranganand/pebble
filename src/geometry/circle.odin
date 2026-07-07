package geometry

import sdl "vendor:sdl3"

import primatives "../global_primatives"

Circle :: struct {
    position: sdl.FPoint,
    radius: f32,
}

are_circles_colliding :: proc(a, b: Circle) -> bool {
    return a.radius + b.radius >= get_point_distance(a.position, b.position)
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