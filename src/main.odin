package main

import "core:fmt"
import "core:math"
import sdl "vendor:sdl3"

WINDOW_W :: 1280
WINDOW_H :: 720
PLAYER_SPEED :: 4.0
PLAYER_SIZE :: 100
AIM_DIST :: 80
AIM_SIZE :: 16

main :: proc() {
    if !sdl.Init({.VIDEO}) {
        fmt.eprintln("sdl Init fail", sdl.GetError())
        return
    }
    defer sdl.Quit()

    // window
    window := sdl.CreateWindow("Pebble",WINDOW_W,WINDOW_H,{})
    if window == nil {
        fmt.eprintln("window creation failed", sdl.GetError())
        return
    }
    defer sdl.DestroyWindow(window)

    // renderer
    renderer := sdl.CreateRenderer(window,nil)
    if renderer == nil {
        fmt.println("renderer creation failed")
        return
    }
    defer sdl.DestroyRenderer(renderer)

    sdl.SetRenderVSync(renderer, 1)

    playerX: f32 = WINDOW_W / 2
    playerY: f32 = WINDOW_H / 2
    aimAngle: f32

    last := sdl.GetTicksNS()
    
    // game loop
    running := true
    for running {
        event: sdl.Event

        for sdl.PollEvent(&event) {
            if event.type == sdl.EventType.QUIT {
                running = false
            }
            if event.type == sdl.EventType.KEY_DOWN { // key pressed
                if event.key.key == sdl.K_ESCAPE { // esc key pressed
                    running = false
                }
            }
        }

        keyboard := sdl.GetKeyboardState(nil)
        speed: f32 = PLAYER_SPEED

        if keyboard != nil {
            if keyboard[sdl.Scancode.W] {
                playerY -= speed
            }
            if keyboard[sdl.Scancode.S] {
                playerY += speed
            }
            if keyboard[sdl.Scancode.A] {
                playerX -= speed
            }
            if keyboard[sdl.Scancode.D] {
                playerX += speed
            }
        }   

        mouseX, mouseY: f32
        _ = sdl.GetMouseState(&mouseX, &mouseY)
        aimAngle = math.atan2(mouseY - playerY, mouseX - playerX)

        //background
        sdl.SetRenderDrawColor(renderer, 20, 20, 20, 255)
        sdl.RenderClear(renderer)

        // rectangel
        playerRect:=sdl.FRect{
            x = playerX - PLAYER_SIZE / 2,
            y = playerY - PLAYER_SIZE / 2,
            w = PLAYER_SIZE,
            h = PLAYER_SIZE
        }
        sdl.SetRenderDrawColor(renderer, 255, 0, 0, 255)
        sdl.RenderFillRect(renderer, &playerRect)

        aimX := playerX + math.cos(aimAngle) * AIM_DIST
        aimY := playerY + math.sin(aimAngle) * AIM_DIST
        aimRect:=sdl.FRect{
            x = aimX - AIM_SIZE / 2,
            y = aimY - AIM_SIZE / 2,
            w = AIM_SIZE,
            h = AIM_SIZE
        }
        sdl.SetRenderDrawColor(renderer, 100, 255, 100, 255)
        sdl.RenderFillRect(renderer, &aimRect)

        sdl.RenderPresent(renderer)
    }
}