package input

import sdl "vendor:sdl3"

import geo "../geometry"

Input :: struct {
    direction: sdl.FPoint,
    mouseX, mouseY: f32,
    fire: bool,
    select: int,
}

process_input :: proc() -> Input {
    inp : Input
    keyboard := sdl.GetKeyboardState(nil)
    mouse := sdl.GetMouseState(&inp.mouseX, &inp.mouseY)

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
        if keyboard[sdl.Scancode._1] do inp.select = 1
        
        inp.direction = geo.normalize_point(inp.direction)
    }
    return inp
}