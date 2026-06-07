package main
import sdl "vendor:sdl3"

Input :: struct {
    dx, dy: f32,
    mouseX, mouseY: f32
}

process_input :: proc() -> Input {
    inp : Input
    keyboard := sdl.GetKeyboardState(nil)
    _ = sdl.GetMouseState(&inp.mouseX, &inp.mouseY)

    if keyboard != nil {
        if keyboard[sdl.Scancode.W] {
            inp.dy -= 1
        }
        if keyboard[sdl.Scancode.S] {
            inp.dy += 1
        }
        if keyboard[sdl.Scancode.A] {
            inp.dx -= 1
        }
        if keyboard[sdl.Scancode.D] {
            inp.dx += 1
        }
        // normalize diaognal
        if inp.dx != 0 && inp.dy != 0 {
            inp.dx *= 0.7
            inp.dy *= 0.7
        }
    }
    return inp
}