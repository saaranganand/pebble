package room

import json "core:encoding/json"
import log "core:log"
import os "core:os"

Room_Data :: struct {
    width, height: int,
    tiles: [dynamic][dynamic]Tile,
}

room_data_init_dimensions :: proc(data: ^Room_Data, w, h: int) {
    data.width = w
    data.height = h
}

room_data_create :: proc(data: ^Room_Data) {
    data.tiles = make([dynamic][dynamic]Tile, data.width)
    for x in 0..<data.width {
        data.tiles[x] = make([dynamic]Tile, data.height)
    }
}

room_data_destroy :: proc(data: ^Room_Data) {
    for arr in data.tiles do delete(arr)
    delete(data.tiles)
}

room_data_change_dimensions :: proc(data: ^Room_Data, dw, dh: int) {
    if data.width + dw <= 0 || data.height + dh <= 0 {
        log.errorf("Attempted to change room data dimensions to a size below 0")
        return
    }

    if dw < 0 {
        for i in dw..<0 do delete(data.tiles[data.width + dw])
    }

    data.width += dw
    data.height += dh

    resize(&data.tiles, data.width)
    for x in 0..<data.width do resize(&data.tiles[x], data.height)
}

room_data_save :: proc(path: string, data: Room_Data) {
    handle, err := os.open(path, os.O_CREATE | os.O_WRONLY | os.O_TRUNC)
    if err != os.General_Error.None {
        log.errorf("Error saving level creator room file %v: %v", path, err)
        return
    }
    defer os.close(handle)

    buffer, json_err := json.marshal(data, {spec = .MJSON})
    if json_err != json.Marshal_Data_Error.None do return
    defer delete(buffer)

    os.write(handle, buffer[:])
}

room_data_load :: proc(path: string, data: ^Room_Data) {
    file_data, err := os.read_entire_file(path, context.allocator)
	if err != os.General_Error.None {
        log.errorf("Failed to read file %v: %v", path, err)
        return
    }
	defer delete(file_data)

	json_err := json.unmarshal(file_data, data, spec = .MJSON)
	if json_err != nil {
		log.errorf("Failed to parse json room data file %v: %v", path, json_err)
		return
	}
}