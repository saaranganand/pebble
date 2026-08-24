package room_creator

import sdl_ttf "vendor:sdl3/ttf"
import mu "vendor:microui"
import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import font "src:data_load/font"
import color "src:util/color"
import ui "src:ui"
import room "src:level/room"

import runtime "base:runtime"

import log "core:log"
import fmt "core:fmt"

@(rodata)
tile_ui_colors := [room.Tile]color.Default_Palette_Color{
    .EMPTY = .WHITE,
    .WALL =  .DARK_GRAY,
    .DOOR =  .RED,
}

@(rodata)
tile_ui_labels := [room.Tile]string{
    .EMPTY = "Em",
    .WALL = "Wl",
    .DOOR = "Do",
}

Creator_UI :: struct {
    mu_ctx: mu.Context,
    atlas_tex: ^sdl.Texture,
    text_cache: ui.Text_Cache,
}

creator_ui: Creator_UI

ui_set_button_color :: proc(ctx: ^mu.Context, btn_color: color.Default_Palette_Color) {
    ctx.style.colors[.BUTTON] = color.mu_color_from_color_palette(btn_color)

    if color.default_color_pallette_light_color[btn_color] do creator_ui.mu_ctx.style.colors[.TEXT] = color.mu_color_from_color_palette(.BLACK)
    else do creator_ui.mu_ctx.style.colors[.TEXT] = color.mu_color_from_color_palette(.WHITE)
}

ui_set_button_color_default :: proc(ctx: ^mu.Context) {
    ctx.style.colors[.BUTTON] = color.mu_color_from_color_palette(.DARK_GRAY)
    creator_ui.mu_ctx.style.colors[.TEXT] = color.mu_color_from_color_palette(.WHITE)
}

ui_init :: proc() {
    ctx_font, success := font.font_manager_get_font("ubuntu", 16)
    if !success do ctx_font = nil
    ui.mu_ctx_init(&creator_ui.mu_ctx, primatives.global_renderer, &creator_ui.atlas_tex, ctx_font)

    creator_ui.text_cache = ui.create_text_cache(16, .WHITE, "ubuntu")

    ui.append_cache_texts(&creator_ui.text_cache, appends = {
        ui.default_text_cache_append("[L]"),
        ui.default_text_cache_append("[L]"),
        ui.default_text_cache_append("[S]"),
        ui.default_text_cache_append("[N]"),
        ui.default_text_cache_append("Pen"),
        ui.default_text_cache_append("Eraser"),
        ui.default_text_cache_append("+w"),
        ui.default_text_cache_append("-w"),
        ui.default_text_cache_append("+h"),
        ui.default_text_cache_append("-h"),

        ui.default_text_cache_append("Currently Loaded:", size = 12, mu_label = false, color = .BLACK),
        ui.default_text_cache_append("Current tool:",     size = 12, mu_label = false),
        ui.default_text_cache_append("Current tile:",     size = 12, mu_label = false),
        ui.default_text_cache_append("Room width:",       size = 12, mu_label = false),
        ui.default_text_cache_append("Room height:",      size = 12, mu_label = false),
    })

    for tile in room.Tile {
        ui.append_cache_texts(&creator_ui.text_cache, ui.default_text_cache_append(tile_ui_labels[tile]))
    }

    creator_ui.mu_ctx.style.spacing = 10

    ui_set_button_color_default(&creator_ui.mu_ctx)
    
    creator_ui.mu_ctx.style.colors[.BUTTON_HOVER] = color.mu_color_from_color_palette(.GRAY)
    creator_ui.mu_ctx.style.colors[.BUTTON_FOCUS] = color.mu_color_from_color_palette(.LIGHT_GRAY)
    creator_ui.mu_ctx.style.colors[.WINDOW_BG] = color.mu_color_from_color_palette(.BLACK)
    creator_ui.mu_ctx.style.colors[.TITLE_BG] = color.mu_color_from_color_palette(.BLACK)
    creator_ui.mu_ctx.style.colors[.BORDER] = color.mu_color_from_color_palette(.BLACK)

}

ui_destroy :: proc() {
    sdl.DestroyTexture(creator_ui.atlas_tex)
    ui.destroy_text_cache(&creator_ui.text_cache)
}

ui_update :: proc() {
    mu.begin(&creator_ui.mu_ctx)

    ui_set_button_color_default(&creator_ui.mu_ctx)
    if mu.window(&creator_ui.mu_ctx, "Tile_select", mu.Rect{0, 51, 100, 750}, {.NO_TITLE, .NO_CLOSE, .NO_RESIZE, .NO_SCROLL}) {
        mu.layout_row(&creator_ui.mu_ctx, {-1}, 5 + 12 + 12 + 5)
        mu.label(&creator_ui.mu_ctx, "")

        mu.layout_row(&creator_ui.mu_ctx, {90}, 40)

        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "Pen") {
            room_creator_set_tool(.PEN)
        }

        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "Eraser") {
            room_creator_set_tool(.ERASER)
        }

        mu.layout_row(&creator_ui.mu_ctx, {-1}, 5 + 12 + 12 + 5)
        mu.label(&creator_ui.mu_ctx, "")

        mu.layout_row(&creator_ui.mu_ctx, {40, 40}, 40)

        for tile in room.Tile {
            ui_set_button_color(&creator_ui.mu_ctx, tile_ui_colors[tile])
            if .SUBMIT in mu.button(&creator_ui.mu_ctx, tile_ui_labels[tile]) {
                room_creator_set_tile(tile)
            }
        }
    }

    ui_set_button_color_default(&creator_ui.mu_ctx)
    if mu.window(&creator_ui.mu_ctx, "Toolbar", mu.Rect{0, 0, 800, 50}, {.NO_TITLE, .NO_CLOSE, .NO_RESIZE, .NO_SCROLL}) {
        mu.layout_row(&creator_ui.mu_ctx, {40, 40, 40, 80, 40, 40, 80, 40, 40}, 40)

        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "[L]") {
            edit_data_load_dialog()
        }
        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "[S]") {
            edit_data_save_dialog()
        }
        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "[N]") {
            room_creator_new_edit_data()
        }

        mu.label(&creator_ui.mu_ctx, "")

        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "+w") {
            room_creator_edit_data_resize(1, 0)
        }
        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "-w") {
            room_creator_edit_data_resize(-1, 0)
        }

        mu.label(&creator_ui.mu_ctx, "")

        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "+h") {
            room_creator_edit_data_resize(0, 1)
        }
        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "-h") {
            room_creator_edit_data_resize(0, -1)
        }
    }

    mu.end(&creator_ui.mu_ctx)
}

ui_draw :: proc() {
    ui.mu_ctx_draw(&creator_ui.mu_ctx, primatives.global_renderer, creator_ui.atlas_tex, creator_ui.text_cache)
    
    ui.draw_cache_text(creator_ui.text_cache, "Currently Loaded:", 110, 51 + 5)

    ui.draw_cache_text(creator_ui.text_cache, "Current tool:", 5, 51 + 5)
    ui.draw_cache_text(creator_ui.text_cache, "Current tile:", 5, 51 + 5 + 12 * 2 + 5 + 10 + 40 * 2 + 10 * 2 + 5)

    ui.draw_cache_text(creator_ui.text_cache, "Room width:", 10 * 3 + 40 * 3, 5)
    ui.draw_cache_text(creator_ui.text_cache, "Room height:", 10 * 3 + 40 * 3 + 80 + 40 * 2 + 10 * 3, 5)

}

ui_set_room_size_text :: proc() {
    ui.set_cache_text(creator_ui.text_cache, "Room width:", fmt.tprint("Room width:", "\n", creator.edit_data.width, sep = ""))

    ui.set_cache_text(creator_ui.text_cache, "Room height:", fmt.tprint("Room height:", "\n", creator.edit_data.height, sep = ""))
}