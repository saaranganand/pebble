package room_creator

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import room "src:level/room"
import color "src:util/color"
import ui "src:ui"

import log "core:log"
import fmt "core:fmt"
import os "core:os"


Tool :: enum { PEN, ERASER }

TILE_SIZE :: 30

Room_Creator :: struct {
    current_tool: Tool,
    current_tile: room.Tile,
    
    edit_data: room.Room_Data,
    edit_data_loaded: bool,
    edit_data_name: string,
    edit_data_name_loaded: bool,

    dialog_directory: cstring,
}

creator: Room_Creator

room_creator_init :: proc() {
    room_creator_set_tool(.PEN)
    room_creator_set_tile(.EMPTY)

    creator.edit_data_loaded = false
    creator.edit_data_name = "nil"
    creator.edit_data_name_loaded = false

    exec_dir, err := os.get_executable_directory(context.temp_allocator)
    if err != os.General_Error.None do log.errorf("Could not get executable directory")
    creator.dialog_directory = fmt.caprint(exec_dir, "/", "assets/level", sep = "")

    ui_init()
}

room_creator_destroy :: proc() {
    ui_destroy()

    room_creator_data_destroy()

    delete(creator.dialog_directory)
}

room_creator_data_destroy :: proc() {
    if creator.edit_data_loaded {
        room.room_data_destroy(&creator.edit_data)
        creator.edit_data_loaded = false
    }

    if creator.edit_data_name_loaded {
        delete(creator.edit_data_name)
        creator.edit_data_name_loaded = false
    }
}

room_creator_new_edit_data :: proc() {
    room_creator_data_destroy()

    creator.edit_data_name = "untitled.room.json"
    ui.set_cache_text(creator_ui.text_cache, "Currently Loaded:", fmt.tprint("Currently Loaded: ", creator.edit_data_name, sep = ""))

    room.room_data_init_dimensions(&creator.edit_data, 20, 20)
    room.room_data_create(&creator.edit_data)

    creator.edit_data_loaded = true

    ui_set_room_size_text()
}

room_creator_edit_data_resize :: proc(dw, dh: int) {
    if !creator.edit_data_loaded do return

    room.room_data_change_dimensions(&creator.edit_data, dw, dh)

    ui_set_room_size_text()
}

room_creator_set_tool :: proc(tool: Tool) {
    creator.current_tool = tool

    ui.set_cache_text(creator_ui.text_cache, "Current tool:", fmt.tprint("Current tool:", "\n", tool, sep = ""))
}

room_creator_set_tile :: proc(tile: room.Tile) {
    creator.current_tile = tile

    ui.set_cache_text(creator_ui.text_cache, "Current tile:", fmt.tprint("Current tile:", "\n", tile, sep = ""))
}

room_creator_loop :: proc() {
    room_creator_input()
    room_creator_update()
    room_creator_draw()
}

room_creator_input :: proc() {

}

room_creator_update :: proc() {
    ui_update()

    if creator.edit_data_loaded do edit_data_update()
}

room_creator_draw :: proc() {
    color.sdl_set_color(color.Default_Palette_Color.WHITE)
    sdl.RenderClear(primatives.global_renderer)

    ui_draw()

    if creator.edit_data_loaded do edit_data_draw()
}