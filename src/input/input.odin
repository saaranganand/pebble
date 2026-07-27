package input

import sdl "vendor:sdl3"

import weapon "../weapon"
import geo "../geometry"

import log "core:log"

Input :: struct {
    direction: sdl.FPoint,
    mouse_pos: sdl.FPoint,
    fire: bool,
    select: int,
}

process_input :: proc(player_weapon_controller: ^weapon.Weapon_Controller) -> Input {
    inp : Input
    keyboard := sdl.GetKeyboardState(nil)
    mouse := sdl.GetMouseState(&inp.mouse_pos.x, &inp.mouse_pos.y)

    inp.fire = .LEFT in mouse // left click to fire
    inp.select = 0

    if keyboard != nil {
        if keyboard[sdl.Scancode.W] {
            inp.direction.y -= 1
        }
        if keyboard[sdl.Scancode.S] {
            inp.direction.y += 1
        }
        if keyboard[sdl.Scancode.A] {
            inp.direction.x -= 1
        }
        if keyboard[sdl.Scancode.D] {
            inp.direction.x += 1
        }

        inp.select = player_weapon_controller.active_weapon

        start_check_weapon_select_scancode := cast(int) sdl.Scancode._1
        i := 0
        for weapon in player_weapon_controller.weapons {
            defer i += 1
            if keyboard[start_check_weapon_select_scancode + i] do inp.select = i
        }
        
        inp.direction = geo.normalize_point(inp.direction)
    }
    return inp
}