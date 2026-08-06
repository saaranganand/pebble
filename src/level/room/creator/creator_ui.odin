package room_creator

import sdl_ttf "vendor:sdl3/ttf"
import mu "vendor:microui"
import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import font "src:data_load/font"
import color "src:util/color"
import util "src:util"

import filepath "core:path/filepath"
import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import fmt "core:fmt"

CTX_FONT_TAG :: "ubuntu"
CTX_FONT_SIZE :: 16
Creator_UI :: struct {
    mu_ctx: mu.Context,
    atlas_tex: ^sdl.Texture,
    text_cache: util.MU_Text_Cache,

    loaded_text: ^sdl_ttf.Text,
    tool_text: ^sdl_ttf.Text,
    tile_text: ^sdl_ttf.Text,
    tile_width_text: ^sdl_ttf.Text,
    tile_height_text: ^sdl_ttf.Text,
}

ui: Creator_UI

append_toolbar_cache :: proc(
    text: string, font_tag: string = CTX_FONT_TAG, font_size: f32 = CTX_FONT_SIZE, font_color: color.Default_Palette_Color = .WHITE
) {
    cstr_text := strings.clone_to_cstring(text)
    defer delete(cstr_text)

    ui.text_cache[text] = font.font_create_text(font_tag, font_size, cstr_text)
    color.sdl_set_text_color(ui.text_cache[text], font_color)
}

ui_set_button_color :: proc(ctx: ^mu.Context, btn_color: color.Default_Palette_Color) {
    ctx.style.colors[.BUTTON] = color.mu_color_from_color_palette(btn_color)

    if color.default_color_pallette_light_color[btn_color] do ui.mu_ctx.style.colors[.TEXT] = color.mu_color_from_color_palette(.BLACK)
    else do ui.mu_ctx.style.colors[.TEXT] = color.mu_color_from_color_palette(.WHITE)
}

ui_set_button_color_default :: proc(ctx: ^mu.Context) {
    ctx.style.colors[.BUTTON] = color.mu_color_from_color_palette(.DARK_GRAY)
    ui.mu_ctx.style.colors[.TEXT] = color.mu_color_from_color_palette(.WHITE)
}

ui_init :: proc() {
    ctx_font, success := font.font_manager_get_font(CTX_FONT_TAG, CTX_FONT_SIZE)
    if !success do ctx_font = nil
    util.mu_ctx_init(&ui.mu_ctx, primatives.global_renderer, &ui.atlas_tex, ctx_font)

    ui.text_cache = make(util.MU_Text_Cache)
    append_toolbar_cache("[L]")
    append_toolbar_cache("[S]")
    append_toolbar_cache("[N]")
    append_toolbar_cache("Pen")
    append_toolbar_cache("Eraser")
    append_toolbar_cache("+w")
    append_toolbar_cache("-w")
    append_toolbar_cache("+h")
    append_toolbar_cache("-h")
    for tile in Tile {
        append_toolbar_cache(tile_labels[tile])
    }

    ui.mu_ctx.style.spacing = 10

    ui_set_button_color_default(&ui.mu_ctx)
    ui.mu_ctx.style.colors[.BUTTON_HOVER] = color.mu_color_from_color_palette(.GRAY)
    ui.mu_ctx.style.colors[.BUTTON_FOCUS] = color.mu_color_from_color_palette(.LIGHT_GRAY)

    ui.mu_ctx.style.colors[.WINDOW_BG] = color.mu_color_from_color_palette(.BLACK)
    ui.mu_ctx.style.colors[.TITLE_BG] = color.mu_color_from_color_palette(.BLACK)

    ui.mu_ctx.style.colors[.BORDER] = color.mu_color_from_color_palette(.BLACK)

    ui.loaded_text = font.font_create_text(CTX_FONT_TAG, 12, "Currently Loaded: nil")
    color.sdl_set_text_color(ui.loaded_text, color.Default_Palette_Color.BLACK)

    ui.tool_text = font.font_create_text(CTX_FONT_TAG, 12, "Current tool:")
    color.sdl_set_text_color(ui.tool_text, color.Default_Palette_Color.WHITE)

    ui.tile_text = font.font_create_text(CTX_FONT_TAG, 12, "Current tile:")
    color.sdl_set_text_color(ui.tile_text, color.Default_Palette_Color.WHITE)

    ui.tile_width_text = font.font_create_text(CTX_FONT_TAG, 12, "Room width:")
    color.sdl_set_text_color(ui.tile_text, color.Default_Palette_Color.WHITE)

    ui.tile_height_text = font.font_create_text(CTX_FONT_TAG, 12, "Room height:")
    color.sdl_set_text_color(ui.tile_text, color.Default_Palette_Color.WHITE)
}

ui_destroy :: proc() {
    sdl.DestroyTexture(ui.atlas_tex)

    for key, text in ui.text_cache {
        sdl_ttf.DestroyText(text)
    }
    delete(ui.text_cache)

    if creator.loaded_name {
        delete(creator.edit_name)
        creator.loaded_name = false
    }

    sdl_ttf.DestroyText(ui.loaded_text)
    sdl_ttf.DestroyText(ui.tool_text)

    sdl_ttf.DestroyText(ui.tile_width_text)
    sdl_ttf.DestroyText(ui.tile_height_text)
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
    //
    ui_set_currently_loaded_text(creator.edit_name)
}

ui_update :: proc() {
    mu.begin(&ui.mu_ctx)

    ui_set_button_color_default(&ui.mu_ctx)
    if mu.window(&ui.mu_ctx, "Tile_select", mu.Rect{0, 51, 100, 750}, {.NO_TITLE, .NO_CLOSE, .NO_RESIZE, .NO_SCROLL}) {
        mu.layout_row(&ui.mu_ctx, {-1}, 5 + 12 + 12 + 5)
        mu.label(&ui.mu_ctx, "")

        mu.layout_row(&ui.mu_ctx, {90}, 40)

        if .SUBMIT in mu.button(&ui.mu_ctx, "Pen") {
            creator_set_tool(.PEN)
        }

        if .SUBMIT in mu.button(&ui.mu_ctx, "Eraser") {
            creator_set_tool(.ERASER)
        }

        mu.layout_row(&ui.mu_ctx, {-1}, 5 + 12 + 12 + 5)
        mu.label(&ui.mu_ctx, "")

        mu.layout_row(&ui.mu_ctx, {40, 40}, 40)

        for tile in Tile {
            ui_set_button_color(&ui.mu_ctx, tile_colors[tile])
            if .SUBMIT in mu.button(&ui.mu_ctx, tile_labels[tile]) {
                creator_set_tile(tile)
            }
        }
    }

    ui_set_button_color_default(&ui.mu_ctx)
    if mu.window(&ui.mu_ctx, "Toolbar", mu.Rect{0, 0, 800, 50}, {.NO_TITLE, .NO_CLOSE, .NO_RESIZE, .NO_SCROLL}) {
        mu.layout_row(&ui.mu_ctx, {40, 40, 40, 80, 40, 40, 80, 40, 40}, 40)

        if .SUBMIT in mu.button(&ui.mu_ctx, "[L]") {
            room_tiles_load_dialog()
        }
        if .SUBMIT in mu.button(&ui.mu_ctx, "[S]") {
            room_tiles_save_dialog()
        }
        if .SUBMIT in mu.button(&ui.mu_ctx, "[N]") {
            creator_new_file()
        }

        mu.label(&ui.mu_ctx, "")

        if .SUBMIT in mu.button(&ui.mu_ctx, "+w") {
            creator_level_tiles_resize(1, 0)
        }
        if .SUBMIT in mu.button(&ui.mu_ctx, "-w") {
            creator_level_tiles_resize(-1, 0)
        }

        mu.label(&ui.mu_ctx, "")

        if .SUBMIT in mu.button(&ui.mu_ctx, "+h") {
            creator_level_tiles_resize(0, 1)
        }
        if .SUBMIT in mu.button(&ui.mu_ctx, "-h") {
            creator_level_tiles_resize(0, -1)
        }
    }

    mu.end(&ui.mu_ctx)
}

ui_draw :: proc() {
    util.mu_ctx_draw(&ui.mu_ctx, primatives.global_renderer, ui.atlas_tex, ui.text_cache)

    sdl_ttf.DrawRendererText(ui.loaded_text, 110, 51 + 5)
    sdl_ttf.DrawRendererText(ui.tool_text, 5, 51 + 5)

    sdl_ttf.DrawRendererText(ui.tile_text, 5, 51 + 5 + 12 * 2 + 5 + 10 + 40 * 2 + 10 * 2 + 5)

    sdl_ttf.DrawRendererText(ui.tile_width_text, 10 * 3 + 40 * 3, 5)
    sdl_ttf.DrawRendererText(ui.tile_height_text, 10 * 3 + 40 * 3 + 80 + 40 * 2 + 10 * 3, 5)
}

ui_set_currently_loaded_text :: proc(txt: string) {
    new_text := fmt.caprint("Currently Loaded: ", txt, sep = "")
    defer delete(new_text)

    sdl_ttf.SetTextString(ui.loaded_text, new_text, 0)
}

ui_set_current_tool_text :: proc(txt: cstring) {
    new_text := fmt.caprint("Current tool:\n", txt, sep = "")
    defer delete(new_text)

    sdl_ttf.SetTextString(ui.tool_text, new_text, 0)
}

ui_set_current_tile_text :: proc(txt: cstring) {
    new_text := fmt.caprint("Current tile:\n", txt, sep = "")
    defer delete(new_text)

    sdl_ttf.SetTextString(ui.tile_text, new_text, 0)
}

ui_set_room_size_text :: proc() {
    new_text := fmt.caprint("Room width:\n", creator.room_width, sep = "")
    sdl_ttf.SetTextString(ui.tile_width_text, new_text, 0)
    delete(new_text)

    new_text = fmt.caprint("Room width:\n", creator.room_height, sep = "")
    defer delete(new_text)

    sdl_ttf.SetTextString(ui.tile_height_text, new_text, 0)
}