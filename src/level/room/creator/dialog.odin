package room_creator

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import util "src:util"
import ui "src:ui"

import runtime "base:runtime"
import fmt "core:fmt"

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
    room_tiles_save(file_path)
}

edit_data_save_dialog :: proc() {
    if !creator.edit_data_loaded do return

    filters := [?]sdl.DialogFileFilter{
        {name = "room tiles files", pattern = "room.tiles"},
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
    room_tiles_load(file_path)
}

edit_data_load_dialog :: proc() {
    filters := [?]sdl.DialogFileFilter{
        {name = "room tiles files", pattern = "room.tiles"},
    }
    room_tiles_save_user_data.ctx = context

    default_location := fmt.caprint(creator.dialog_directory, "/", creator.edit_data_name, sep = "")
    defer delete(default_location)
    sdl.ShowOpenFileDialog(
        edit_data_load_callback,
        userdata = &room_tiles_save_user_data,
        window = primatives.global_window,
        filters = raw_data(filters[:]),
        nfilters = len(filters),
        default_location = default_location,
        allow_many = false,
    )
}