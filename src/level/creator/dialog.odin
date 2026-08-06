package level_creator

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"

import runtime "base:runtime"
import fmt "core:fmt"

Dialog_User_Data :: struct {
    ctx: runtime.Context,
}
room_tiles_save_user_data: Dialog_User_Data

room_tiles_save_callback :: proc "c" (userdata: rawptr, filelist: [^]cstring, filter: i32) {
    data := cast(^Dialog_User_Data)userdata
    context = data.ctx

    if filelist == nil do return
    fmt.printfln("%v", filelist[0])
    if filelist[0] == "" do return

    file_path := filelist[0]
    room_tiles_save(file_path)
}

room_tiles_save_dialog :: proc() {
    if !creator.edit_tiles_loaded do return

    filters := [?]sdl.DialogFileFilter{
        {name = "room tiles files", pattern = "room.tiles"},
    }
    room_tiles_save_user_data.ctx = context

    //sdl.ShowSaveFileDialog(test_callback, nil, primatives.global_window, filters, 0, "assets/")
    sdl.ShowSaveFileDialog(
        room_tiles_save_callback,
        userdata = &room_tiles_save_user_data,
        window = primatives.global_window,
        filters = raw_data(filters[:]),
        nfilters = len(filters),
        default_location = dialog_directory,
    )
}