package room_creator

import sdl_ttf "vendor:sdl3/ttf"
import mu "vendor:microui"
import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import font "src:data_load/font"
import color "src:util/color"
import util "src:util"
import ui "src:ui"

import filepath "core:path/filepath"
import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import fmt "core:fmt"

Creator_UI :: struct {
    mu_ctx: mu.Context,
    atlas_tex: ^sdl.Texture,
    text_cache: ui.MU_Text_Cache,
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

    ui.append_text_cache(&creator_ui.text_cache, "[L]")
    ui.append_text_cache(&creator_ui.text_cache, "[S]")
    ui.append_text_cache(&creator_ui.text_cache, "[N]")
    ui.append_text_cache(&creator_ui.text_cache, "Pen")
    ui.append_text_cache(&creator_ui.text_cache, "Eraser")
    ui.append_text_cache(&creator_ui.text_cache, "+w")
    ui.append_text_cache(&creator_ui.text_cache, "-w")
    ui.append_text_cache(&creator_ui.text_cache, "+h")
    ui.append_text_cache(&creator_ui.text_cache, "-h")
    for tile in Tile {
        ui.append_text_cache(&creator_ui.text_cache, tile_labels[tile])
    }

    creator_ui.mu_ctx.style.spacing = 10

    ui_set_button_color_default(&creator_ui.mu_ctx)
    creator_ui.mu_ctx.style.colors[.BUTTON_HOVER] = color.mu_color_from_color_palette(.GRAY)
    creator_ui.mu_ctx.style.colors[.BUTTON_FOCUS] = color.mu_color_from_color_palette(.LIGHT_GRAY)

    creator_ui.mu_ctx.style.colors[.WINDOW_BG] = color.mu_color_from_color_palette(.BLACK)
    creator_ui.mu_ctx.style.colors[.TITLE_BG] = color.mu_color_from_color_palette(.BLACK)

    creator_ui.mu_ctx.style.colors[.BORDER] = color.mu_color_from_color_palette(.BLACK)

    ui.append_text_cache(&creator_ui.text_cache, "Currently Loaded:", 12, .BLACK)
    ui.append_text_cache(&creator_ui.text_cache, "Current tool:", 12)
    ui.append_text_cache(&creator_ui.text_cache, "Current tile:", 12)
    ui.append_text_cache(&creator_ui.text_cache, "Room width:", 12)
    ui.append_text_cache(&creator_ui.text_cache, "Room height:", 12)
}

ui_destroy :: proc() {
    sdl.DestroyTexture(creator_ui.atlas_tex)

    ui.destroy_text_cache(&creator_ui.text_cache)

    if creator.loaded_name {
        delete(creator.edit_name)
        creator.loaded_name = false
    }
}

room_tiles_save :: proc(path: cstring) {
    log.infof("Saving file %v", path)
    save_room(string(path))
}

room_tiles_load :: proc(path: cstring) {
    if creator.edit_tiles_loaded do creator_level_tiles_destroy()
    if creator.loaded_name {
        delete(creator.edit_name)
        creator.loaded_name = false
    }
    log.infof("Loading file %v", path)
    load_room(string(path))

    creator.loaded_name = true
    creator.edit_name = strings.clone(filepath.base(string(path)))
    
    ui.set_cache_text(creator_ui.text_cache, "Current Loaded:", fmt.tprint("Current Loaded:", "\n", creator.edit_name, sep = ""))
}

ui_update :: proc() {
    mu.begin(&creator_ui.mu_ctx)

    ui_set_button_color_default(&creator_ui.mu_ctx)
    if mu.window(&creator_ui.mu_ctx, "Tile_select", mu.Rect{0, 51, 100, 750}, {.NO_TITLE, .NO_CLOSE, .NO_RESIZE, .NO_SCROLL}) {
        mu.layout_row(&creator_ui.mu_ctx, {-1}, 5 + 12 + 12 + 5)
        mu.label(&creator_ui.mu_ctx, "")

        mu.layout_row(&creator_ui.mu_ctx, {90}, 40)

        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "Pen") {
            creator_set_tool(.PEN)
        }

        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "Eraser") {
            creator_set_tool(.ERASER)
        }

        mu.layout_row(&creator_ui.mu_ctx, {-1}, 5 + 12 + 12 + 5)
        mu.label(&creator_ui.mu_ctx, "")

        mu.layout_row(&creator_ui.mu_ctx, {40, 40}, 40)

        for tile in Tile {
            ui_set_button_color(&creator_ui.mu_ctx, tile_colors[tile])
            if .SUBMIT in mu.button(&creator_ui.mu_ctx, tile_labels[tile]) {
                creator_set_tile(tile)
            }
        }
    }

    ui_set_button_color_default(&creator_ui.mu_ctx)
    if mu.window(&creator_ui.mu_ctx, "Toolbar", mu.Rect{0, 0, 800, 50}, {.NO_TITLE, .NO_CLOSE, .NO_RESIZE, .NO_SCROLL}) {
        mu.layout_row(&creator_ui.mu_ctx, {40, 40, 40, 80, 40, 40, 80, 40, 40}, 40)

        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "[L]") {
            room_tiles_load_dialog()
        }
        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "[S]") {
            room_tiles_save_dialog()
        }
        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "[N]") {
            creator_new_file()
        }

        mu.label(&creator_ui.mu_ctx, "")

        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "+w") {
            creator_level_tiles_resize(1, 0)
        }
        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "-w") {
            creator_level_tiles_resize(-1, 0)
        }

        mu.label(&creator_ui.mu_ctx, "")

        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "+h") {
            creator_level_tiles_resize(0, 1)
        }
        if .SUBMIT in mu.button(&creator_ui.mu_ctx, "-h") {
            creator_level_tiles_resize(0, -1)
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
    ui.set_cache_text(creator_ui.text_cache, "Room width:", fmt.tprint("Room width:", "\n", creator.room_width, sep = ""))

    ui.set_cache_text(creator_ui.text_cache, "Room height:", fmt.tprint("Room height:", "\n", creator.room_height, sep = ""))
}