package room_creator

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import room "src:level/room"
import ui "src:ui"

import filepath "core:path/filepath"
import strings "core:strings"
import runtime "base:runtime"
import fmt "core:fmt"
import log "core:log"

Dialog_User_Data :: struct {
    ctx: runtime.Context,
}
room_tiles_save_user_data: Dialog_User_Data

edit_data_save_callback :: proc "c" (userdata: rawptr, filelist: [^]cstring, filter: i32) {
    data := cast(^Dialog_User_Data)userdata
    context = data.ctx

    ui.mu_ctx_reset_mouse_left_after_dialog(&creator_ui.mu_ctx)

    if filelist == nil do return
    if filelist[0] == "" do return

    file_path := filelist[0]
    log.infof("Saving file %v", file_path)
    room.room_data_save(string(file_path), creator.edit_data)
}

edit_data_save_dialog :: proc() {
    if !creator.edit_data_loaded do return

    filters := [?]sdl.DialogFileFilter{
        {name = "room files", pattern = "room.json"},
    }
    room_tiles_save_user_data.ctx = context

    default_location := fmt.caprint(creator.dialog_directory, "/", creator.edit_data_name, sep = "")
    defer delete(default_location)
    sdl.ShowSaveFileDialog(
        edit_data_save_callback,
        userdata = &room_tiles_save_user_data,
        window = primatives.global_window,
        filters = raw_data(filters[:]),
        nfilters = len(filters),
        default_location = default_location,
    )
}

edit_data_load_callback :: proc "c" (userdata: rawptr, filelist: [^]cstring, filter: i32) {
    data := cast(^Dialog_User_Data)userdata
    context = data.ctx

    ui.mu_ctx_reset_mouse_left_after_dialog(&creator_ui.mu_ctx)

    if filelist == nil do return
    if filelist[0] == "" do return

    file_path := filelist[0]
    room_creator_data_destroy()

    log.infof("Loading file %v", file_path)
    room.room_data_load(string(file_path), &creator.edit_data)

    if creator.edit_data.width == 0 || creator.edit_data.height == 0 {
        room.room_data_init_dimensions(&creator.edit_data, 20, 20)
        room.room_data_create(&creator.edit_data)
    } 
    creator.edit_data_loaded = true

    creator.edit_data_name = strings.clone(filepath.base(string(file_path)))
    creator.edit_data_name_loaded = true
    
    ui.set_cache_text(creator_ui.text_cache, "Currently Loaded:", fmt.tprint("Currently Loaded: ", creator.edit_data_name, sep = ""))
}

edit_data_load_dialog :: proc() {
    filters := [?]sdl.DialogFileFilter{
        {name = "room files", pattern = "room.json"},
    }
    room_tiles_save_user_data.ctx = context

    sdl.ShowOpenFileDialog(
        edit_data_load_callback,
        userdata = &room_tiles_save_user_data,
        window = primatives.global_window,
        filters = raw_data(filters[:]),
        nfilters = len(filters),
        default_location = creator.dialog_directory,
        allow_many = false,
    )
}