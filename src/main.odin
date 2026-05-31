package main

import "core:fmt"
import sdl "vendor:sdl3"

main :: proc() {
    if !sdl.Init({.VIDEO}) {
        fmt.println("sdl Init fail")
        return
    }
    defer sdl.Quit()

    // window
    window := sdl.CreateWindow(
        "Pebble",
        800,
        600,
        {}
    )
    if window == nil {
        fmt.println("window creation failde")
        return
    }
    defer sdl.DestroyWindow(window)

    // renderer
    renderer := sdl.CreateRenderer(
        window, 
        nil
    )
    if renderer == nil {
        fmt.println("renderer creation failed")
        return
    }
    defer sdl.DestroyRenderer(renderer)
    sdl.SetRenderVSync(renderer, 1)

    rect_x: f32 = 350
    rect_y: f32 = 250
    
    // game loop
    running := true
    for running {
        event: sdl.Event

        for sdl.PollEvent(&event) {
            if event.type == sdl.EventType.QUIT {
                running = false
            }
        }

        keyboard := sdl.GetKeyboardState(nil)
        speed: f32 = 4

        if keyboard != nil {
            if keyboard[sdl.Scancode.W] {
                rect_y -= speed
            }
            if keyboard[sdl.Scancode.S] {
                rect_y += speed
            }
            if keyboard[sdl.Scancode.A] {
                rect_x -= speed
            }
            if keyboard[sdl.Scancode.D] {
                rect_x += speed
            }
        }   

        //background
        sdl.SetRenderDrawColor(renderer, 20, 20, 20, 255)
        sdl.RenderClear(renderer)

        // rectangel
        rect:=sdl.FRect{
            x = rect_x,
            y = rect_y,
            w = 100,
            h = 100
        }

        sdl.SetRenderDrawColor(renderer, 255, 0, 0, 255)
        sdl.RenderFillRect(renderer, &rect)

        sdl.RenderPresent(renderer)
    }
}