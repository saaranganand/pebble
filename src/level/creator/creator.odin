package level_creator

import mu "vendor:microui"
import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import color "src:util/color"
import util "src:util"

import strings "core:strings"
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
}

creator: Creator

dialog_directory: cstring

creator_init :: proc() {
    ui_init()

    creator_set_tool(.PEN)
    creator_set_tile(.EMPTY)

    creator.edit_tiles_loaded = false
    creator.edit_name = "nil"

    exec_dir, err := os.get_executable_directory(context.allocator)
    defer delete(exec_dir)

    dialog_directory = strings.clone_to_cstring(exec_dir)
}

creator_destroy :: proc() {
    ui_destroy()

    if creator.edit_tiles_loaded {
        for arr in creator.edit_tiles do delete(arr)
        delete(creator.edit_tiles)
    }

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
    creator.edit_name = "untitled.room.tiles"
    ui_set_currently_loaded_text(creator.edit_name)
    
    creator_level_tiles_create(20, 20)
}

creator_set_tool :: proc(tool: Tool) {
    creator.current_tool = tool

    tool_text := fmt.caprint(tool)
    defer delete(tool_text)
    ui_set_current_tool_text(tool_text)
}

creator_set_tile :: proc(tile: Tile) {
    creator.current_tile = tile

    tile_text := fmt.caprint(tile)
    defer delete(tile_text)
    ui_set_current_tile_text(tile_text)
}