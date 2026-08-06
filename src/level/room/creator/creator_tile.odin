package room_creator

import color "src:util/color"
import room "src:level/room"

@(rodata)
tile_ui_colors := [room.Tile]color.Default_Palette_Color{
    .EMPTY = .WHITE,
    .WALL =  .DARK_GRAY,
    .DOOR =  .RED,
}

@(rodata)
tile_ui_labels := [room.Tile]string{
    .EMPTY = "Em",
    .WALL = "Wl",
    .DOOR = "Do",
}