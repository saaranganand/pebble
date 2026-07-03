package main

import sdl "vendor:sdl3"
import "core:fmt"

Circle :: struct {
    radius, x, y: f32,
}

// midpoint algorithm
draw_circle :: proc(x, y, radius: f32) {
    point_buffer_size := (int(radius) + 1) * 8
    draw_points := make([dynamic]sdl.FPoint, 0, point_buffer_size)
    defer delete(draw_points)

    offset_x: f32 = 0
    offset_y := radius
    d := 1 - radius

    for offset_x <= offset_y {
        append(&draw_points, sdl.FPoint{ (x + offset_x + 0.5), (y - offset_y + 0.5) })
        append(&draw_points, sdl.FPoint{ (x + offset_x + 0.5), (y + offset_y + 0.5) })
        append(&draw_points, sdl.FPoint{ (x - offset_x + 0.5), (y - offset_y + 0.5) })
        append(&draw_points, sdl.FPoint{ (x - offset_x + 0.5), (y + offset_y + 0.5) })
        append(&draw_points, sdl.FPoint{ (x + offset_y + 0.5), (y - offset_x + 0.5) })
        append(&draw_points, sdl.FPoint{ (x + offset_y + 0.5), (y + offset_x + 0.5) })
        append(&draw_points, sdl.FPoint{ (x - offset_y + 0.5), (y - offset_x + 0.5) })
        append(&draw_points, sdl.FPoint{ (x - offset_y + 0.5), (y + offset_x + 0.5) })

        if d < 0 {
            d += 2 * offset_x + 3
        } else {
            d += 2 * (offset_x - offset_y) + 5
            offset_y -= 1
        }
        offset_x += 1
    }

    sdl.RenderPoints(global_renderer, raw_data(draw_points), i32(len(draw_points)))
}

// does the previous algorithm, eight points are combined into 4 lines
// lines are split into seperate loops to allow for accurate ordering in drawing the lines
// circle is filled via scanlines
fill_circle :: proc(x, y, radius: f32) {
    Row :: struct { y, x1, x2: f32 }

    row_buffer_size := int(radius) + 1
    outer_top    := make([dynamic]Row, 0, row_buffer_size)
    inner_top    := make([dynamic]Row, 0, row_buffer_size)
    inner_bottom := make([dynamic]Row, 0, row_buffer_size)
    outer_bottom := make([dynamic]Row, 0, row_buffer_size)
    defer delete(outer_top)
    defer delete(inner_top)
    defer delete(inner_bottom)
    defer delete(outer_bottom)

    offset_x: f32 = 0
    offset_y := radius
    d := 1 - radius

    for offset_x <= offset_y {
        append(&outer_top,    Row{ y - offset_y, x - offset_x, x + offset_x })
        append(&inner_top,    Row{ y - offset_x, x - offset_y, x + offset_y })
        append(&inner_bottom, Row{ y + offset_x, x - offset_y, x + offset_y })
        append(&outer_bottom, Row{ y + offset_y, x - offset_x, x + offset_x })

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

    sdl.RenderLines(global_renderer, raw_data(points), i32(len(points)))
}
/*

fill_circle :: proc(x, y, radius: f32) {
    Row :: struct { y, x1, x2: f32 }
    row_buffer_size := (int(radius) + 1) * 4
    draw_rows := make([dynamic]Row, 0, row_buffer_size)

    offset_x: f32 = 0
    offset_y := radius
    d := 1 - radius

    for offset_x <= offset_y {
        append(&draw_rows, Row{ y - offset_y, x - offset_x, x + offset_x })
        append(&draw_rows, Row{ y + offset_y, x - offset_x, x + offset_x })
        append(&draw_rows, Row{ y - offset_x, x - offset_y, x + offset_y })
        append(&draw_rows, Row{ y + offset_x, x - offset_y, x + offset_y })

        if d < 0 {
            d += 2 * offset_x + 3
        } else {
            d += 2 * (offset_x - offset_y) + 5
            offset_y -= 1
        }
        offset_x += 1
    }

    slice.sort_by(draw_rows[:], proc(a, b: Row) -> bool { return a.y < b.y })

    sdl.RenderPoints(global_renderer, raw_data(draw_points), count)
    sdl.renderlines
    delete(draw_points)
}


int
SDL_RenderFillCircle(SDL_global_renderer * global_renderer, int x, int y, int radius)
{
    int offsetx, offsety, d;
    int status;

    CHECK_global_renderer_MAGIC(global_renderer, -1);

    offsetx = 0;
    offsety = radius;
    d = radius -1;
    status = 0;

    while (offsety >= offsetx) {

        status += SDL_RenderDrawLine(global_renderer, x - offsety, y + offsetx,
                                     x + offsety, y + offsetx);
        status += SDL_RenderDrawLine(global_renderer, x - offsetx, y + offsety,
                                     x + offsetx, y + offsety);
        status += SDL_RenderDrawLine(global_renderer, x - offsetx, y - offsety,
                                     x + offsetx, y - offsety);
        status += SDL_RenderDrawLine(global_renderer, x - offsety, y - offsetx,
                                     x + offsety, y - offsetx);

        if (status < 0) {
            status = -1;
            break;
        }

        if (d >= 2*offsetx) {
            d -= 2*offsetx + 1;
            offsetx +=1;
        }
        else if (d < 2 * (radius - offsety)) {
            d += 2 * offsety - 1;
            offsety -= 1;
        }
        else {
            d += 2 * (offsety - offsetx - 1);
            offsety -= 1;
            offsetx += 1;
        }
    }

    return status;
}
*/