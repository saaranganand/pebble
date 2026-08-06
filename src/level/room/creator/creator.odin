package room_creator

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import color "src:util/color"
import ui "src:ui"

import log "core:log"
import fmt "core:fmt"
import os "core:os"


Tool :: enum { PEN, ERASER }

TILE_SIZE :: 30

Creator :: struct {
    current_tool: Tool,
    current_tile: Tile,

    room_width, room_height: int,
    edit_tiles: [dynamic][dynamic]Tile,
    edit_tiles_loaded: bool,
    edit_name: string,

    loaded_name: bool,
}

creator: Creator

dialog_directory: cstring

creator_init :: proc() {
    ui_init()

    creator_set_tool(.PEN)
    creator_set_tile(.EMPTY)

    creator.edit_tiles_loaded = false
    creator.edit_name = "nil"

    creator.loaded_name = false

    exec_dir, err := os.get_executable_directory(context.allocator)
    defer delete(exec_dir)

    dialog_directory = fmt.caprint(exec_dir, "/", "assets/level", sep = "")
}

creator_destroy :: proc() {
    ui_destroy()

    creator_level_tiles_destroy()

    delete(dialog_directory)
}

creator_level_tiles_create :: proc(width, height: int) {
    if creator.edit_tiles_loaded do return

    creator.room_width = width
    creator.room_height = height

    creator.edit_tiles = make([dynamic][dynamic]Tile, creator.room_width)
    for x in 0..<creator.room_width {
        creator.edit_tiles[x] = make([dynamic]Tile, creator.room_height)
    }

    creator.edit_tiles_loaded = true

    ui_set_room_size_text()
}

creator_level_tiles_destroy :: proc() {
    if creator.edit_tiles_loaded {
        for arr in creator.edit_tiles do delete(arr)
        delete(creator.edit_tiles)
    }

    creator.edit_tiles_loaded = false
}

creator_level_tiles_resize :: proc(d_width, d_height: int) {
    if !creator.edit_tiles_loaded do return

    if d_width == -1 {
        delete(creator.edit_tiles[creator.room_width - 1])
    }

    creator.room_width += d_width
    creator.room_height += d_height

    resize(&creator.edit_tiles, creator.room_width)
    for x in 0..<creator.room_width {
        resize(&creator.edit_tiles[x], creator.room_height)
    }

    ui_set_room_size_text()
}

creator_loop :: proc() {
    creator_input()
    creator_update()
    creator_draw()
}

creator_input :: proc() {

}

creator_update :: proc() {
    ui_update()

    if creator.edit_tiles_loaded do edit_tiles_update()
}

creator_draw :: proc() {
    color.sdl_set_color(color.Default_Palette_Color.WHITE)
    sdl.RenderClear(primatives.global_renderer)

    ui_draw()

    if creator.edit_tiles_loaded do edit_tiles_draw()
}

creator_new_file :: proc() {
    if creator.edit_tiles_loaded {
        creator_level_tiles_destroy()
    }

    if creator.loaded_name {
        delete(creator.edit_name)
        creator.loaded_name = false
    }

    creator.edit_name = "untitled.room.tiles"
    ui.set_cache_text(creator_ui.text_cache, "Current Loaded:", fmt.tprint("Current Loaded:", "\n", creator.edit_name, sep = ""))
    
    creator_level_tiles_create(20, 20)
}

creator_set_tool :: proc(tool: Tool) {
    creator.current_tool = tool

    ui.set_cache_text(creator_ui.text_cache, "Current tool:", fmt.tprint("Current tool:", "\n", tool, sep = ""))
}

creator_set_tile :: proc(tile: Tile) {
    creator.current_tile = tile

    ui.set_cache_text(creator_ui.text_cache, "Current tile:", fmt.tprint("Current tile:", "\n", tile, sep = ""))
}