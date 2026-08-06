package room_creator

import mu "vendor:microui"
import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import color "src:util/color"
import util "src:util"

import strings "core:strings"
import endian "core:encoding/endian"
import log "core:log"
import fmt "core:fmt"
import mem "core:mem"
import os "core:os"

save_room :: proc(filename: string) {
    handle, err := os.open(filename, os.O_CREATE | os.O_WRONLY | os.O_TRUNC)
    if err != os.General_Error.None {
        log.errorf("Error saving level creator room file %v: %v", filename, err)
        return
    }
    defer os.close(handle)

    buffer := make([dynamic]u8)
    defer delete(buffer)
    
    // Write width and height
    resize(&buffer, len(buffer) + 8)
    endian.put_i32(buffer[len(buffer)-8:], .Little, i32(creator.room_width))
    endian.put_i32(buffer[len(buffer)-4:], .Little, i32(creator.room_height))
    
    // Write each tile as i32
    for row in creator.edit_tiles {
        for tile in row {
            offset := len(buffer)
            resize(&buffer, offset + 4)
            endian.put_i32(buffer[offset:], .Little, i32(tile))
        }
    }
    
    os.write(handle, buffer[:])
}

load_room :: proc(filename: string) {
    data, err := os.read_entire_file(filename, context.allocator)
    if err != os.General_Error.None {
        log.errorf("Error loading level creator room file %v: %v", filename, err)
        return
    }
    defer delete(data)

    if len(data) < 12 {
        creator_level_tiles_create(20, 20)
        return
    }

    offset := 0
    read_width, _ := endian.get_i32(data[offset:], .Little)
    width := int(read_width)
    offset += 4
    read_height, _ := endian.get_i32(data[offset:], .Little)
    height := int(read_height)
    offset += 4
    
    creator_level_tiles_create(width, height)
    for x in 0..<width {
        for y in 0..<height {
            read_tile, _ := endian.get_i32(data[offset:], .Little)
            creator.edit_tiles[x][y] = Tile(read_tile)
            offset += 4
        }
    }
}