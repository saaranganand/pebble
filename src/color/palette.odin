package color

import sdl "vendor:sdl3"

import primatives "../sdl_primatives"

generate_color :: proc(hex: int, alpha: u8 = 0xff) -> sdl.Color{
    return {
        u8((hex >> 16) & 0xff),
        u8((hex >> 8) & 0xff),
        u8(hex & 0xff),
        alpha,
    }
}

Default_Palette_Colors :: enum {
    WHITE = 0, LIGHT_GRAY, GRAY, DARK_GRAY, BLACK,
    BLUE, SKY_BLUE, BABY_BLUE,
    DARK_GREEN, GREEN, GRASS_GREEN,
    RED, PINK, BROWN, YELLOW, PALE,
}

//https://lospec.com/palette-list/arne-soft-16
@(rodata)
default_color_palette := [Default_Palette_Colors]sdl.Color {
    .WHITE       = {0xff, 0xff, 0xff, 0xff},
    .LIGHT_GRAY  = {0xdd, 0xdd, 0xdd, 0xff},
    .GRAY        = {0xaa, 0xaa, 0xaa, 0xff},
    .DARK_GRAY   = {0x45, 0x45, 0x41, 0xff},
    .BLACK       = {0x00, 0x00, 0x00, 0x00},

    .BLUE        = {0x56, 0x68, 0xac, 0xff},
    .SKY_BLUE    = {0x79, 0x99, 0xda, 0xff},
    .BABY_BLUE   = {0xa0, 0xcd, 0xf0, 0xff},

    .DARK_GREEN  = {0x21, 0x4e, 0x3f, 0xff},
    .GREEN       = {0x60, 0x99, 0x7b, 0xff},
    .GRASS_GREEN = {0xc0, 0xe4, 0x8c, 0xff},

    .RED         = {0x95, 0x49, 0x61, 0xff},
    .PINK        = {0xf3, 0xa3, 0xc0, 0xff},
    .BROWN       = {0xb9, 0x8f, 0x7b, 0xff},
    .YELLOW      = {0xeb, 0xcb, 0x71, 0xff},
    .PALE        = {0xf5, 0xf0, 0xd0, 0xff},
}

sdl_set_default_color_palette :: proc(pcolor: Default_Palette_Colors) {
    color := default_color_palette[pcolor]
    sdl.SetRenderDrawColor(primatives.global_renderer, color.r, color.g, color.b, color.a)
}

sdl_set_non_color_palette :: proc(color: sdl.Color) {
    sdl.SetRenderDrawColor(primatives.global_renderer, color.r, color.g, color.b, color.a)
}
sdl_set_rgba_color :: proc(r,g,b,a : u8) {
    sdl.SetRenderDrawColor(primatives.global_renderer, r, g, b, a)
}

sdl_set_color :: proc{
    sdl_set_default_color_palette,
    sdl_set_non_color_palette,
    sdl_set_rgba_color,
}