package room_creator

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import color "src:util/color"
import util "src:util"
import geo "src:geometry"

import math "core:math"

edit_tiles_window_pos_to_grid_pos :: proc(p: sdl.FPoint) -> (x, y: f32) {
    x = math.floor( p.x / TILE_SIZE )
    y = math.floor( p.y / TILE_SIZE )

    return
}

edit_tiles_update :: proc() {
    grid_box := sdl.FRect{
        130, 80,
        f32(creator.room_width)  * TILE_SIZE,
        f32(creator.room_height) * TILE_SIZE,
    }

    edit_tiles_tool_update(grid_box)
}

edit_tiles_tool_update :: proc(grid_box: sdl.FRect) {
    mouse_pos := sdl.FPoint{}
    buttons_state := sdl.GetMouseState(&mouse_pos.x, &mouse_pos.y)

    grid_box_pos := sdl.FPoint{ grid_box.x, grid_box.y }
    tile_x, tile_y := edit_tiles_window_pos_to_grid_pos(mouse_pos - grid_box_pos)

    if geo.point_in_rect(mouse_pos, grid_box) {
        if .LEFT in creator_ui.mu_ctx.mouse_down_bits {
            if creator.current_tool == .ERASER do edit_tiles_erase(int(tile_x), int(tile_y))
            else if creator.current_tool == .PEN do edit_tiles_write(int(tile_x), int(tile_y))
        }
    }
}

edit_tiles_erase :: proc(x, y: int) {
    creator.edit_tiles[x][y] = .EMPTY
}

edit_tiles_write :: proc(x, y: int) {
    creator.edit_tiles[x][y] = creator.current_tile
}

edit_tiles_draw :: proc() {
    grid_box := sdl.FRect{
        130, 80,
        f32(creator.room_width)  * TILE_SIZE,
        f32(creator.room_height) * TILE_SIZE,
    }

    edit_tiles_draw_tiles(grid_box)

    edit_tiles_draw_highlight(grid_box)
    
    edit_tiles_draw_grid(grid_box)
}

edit_tiles_draw_tiles :: proc(grid_box: sdl.FRect) {
    for x in 0..<creator.room_width {
        for y in 0..<creator.room_height {
            tile := creator.edit_tiles[x][y]
            tile_rect := sdl.FRect{
                grid_box.x + f32(x) * TILE_SIZE,
                grid_box.y + f32(y) * TILE_SIZE,
                TILE_SIZE,
                TILE_SIZE
            }
            
            color.sdl_set_color(tile_colors[tile])
            sdl.RenderFillRect(primatives.global_renderer, &tile_rect)
        }
    }
}

edit_tiles_draw_highlight :: proc(grid_box: sdl.FRect) {
    mouse_pos := sdl.FPoint{}
    buttons_state := sdl.GetMouseState(&mouse_pos.x, &mouse_pos.y)
    if geo.point_in_rect(mouse_pos, grid_box) {
        highlight_color := color.default_color_palette[.SKY_BLUE]
        highlight_color.a = 100
        color.sdl_set_color(highlight_color)

        grid_box_pos := sdl.FPoint{ grid_box.x, grid_box.y }
        tile_x, tile_y := edit_tiles_window_pos_to_grid_pos(mouse_pos - grid_box_pos)

        tile_rect := sdl.FRect{
            grid_box.x + tile_x * TILE_SIZE,
            grid_box.y + tile_y * TILE_SIZE,
            TILE_SIZE,
            TILE_SIZE
        }

        sdl.RenderFillRect(primatives.global_renderer, &tile_rect)
    }
}

edit_tiles_draw_grid :: proc(grid_box: sdl.FRect) {
    color.sdl_set_color(color.Default_Palette_Color.BLACK)

    for x in 0..=creator.room_width {
        // Vertical lines
        sdl.RenderLine(primatives.global_renderer, grid_box.x + f32(x) * TILE_SIZE, grid_box.y, grid_box.x + f32(x) * TILE_SIZE, grid_box.y + grid_box.h)
    }

    for y in 0..=creator.room_height {
        // Horizontal lines
        sdl.RenderLine(primatives.global_renderer, grid_box.x, grid_box.y + f32(y) * TILE_SIZE, grid_box.x + grid_box.w, grid_box.y + f32(y) * TILE_SIZE)
    }
}