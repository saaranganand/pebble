package room_creator

import color "src:util/color"

Tile :: enum { EMPTY, WALL, DOOR }

@(rodata)
tile_colors := [Tile]color.Default_Palette_Color{
    .EMPTY = .WHITE,
    .WALL =  .DARK_GRAY,
    .DOOR =  .RED,
}

@(rodata)
tile_labels := [Tile]string{
    .EMPTY = "Em",
    .WALL = "Wl",
    .DOOR = "Do",
}