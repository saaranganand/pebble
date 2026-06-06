package main

import "core:fmt"
import "core:math"
import sdl "vendor:sdl3"

WINDOW_W :: 1280
WINDOW_H :: 720
// PLAYER_SPEED :: 4.0
PLAYER_SIZE :: 100
AIM_DIST :: 80 // distance of indicator from player
AIM_SIZE :: 16

CAM_SPEED :: 4.0 // how far world moves under player
NUDGE_RADIUS :: 30.0 // how far player leans from center when moving
NUDGE_SPEED :: 0.15 // how fast they lean

TILE_SIZE :: 64

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

    centerX: f32 = WINDOW_W / 2
    centerY: f32 = WINDOW_H / 2
    playerX: f32 = centerX
    playerY: f32 = centerY

    camX: f32 = 0
    camY: f32 = 0

    aimAngle: f32
    
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
        // speed: f32 = PLAYER_SPEED
        inputX, inputY: f32

        if keyboard != nil {
            if keyboard[sdl.Scancode.W] {
                inputY -= 1
            }
            if keyboard[sdl.Scancode.S] {
                inputY += 1
            }
            if keyboard[sdl.Scancode.A] {
                inputX -= 1
            }
            if keyboard[sdl.Scancode.D] {
                inputX += 1
            }
            // normalize diaognal
            if inputX != 0 && inputY != 0 {
                inputX *= 0.7
                inputY *= 0.7
            }
        }
        
        // bg moves opposite to player direction
        camX += inputX * CAM_SPEED
        camY += inputY * CAM_SPEED

        targetX := centerX + inputX * NUDGE_RADIUS
        targetY := centerY + inputY * NUDGE_RADIUS
        playerX += (targetX-playerX) * NUDGE_SPEED
        playerY += (targetY-playerY) * NUDGE_SPEED

        mouseX, mouseY: f32
        _ = sdl.GetMouseState(&mouseX, &mouseY)
        aimAngle = math.atan2(mouseY - playerY, mouseX - playerX)

        //background
        sdl.SetRenderDrawColor(renderer, 255, 255, 255, 255)
        sdl.RenderClear(renderer)

        // bg texture
        sdl.SetRenderDrawColor(renderer, 40, 40, 50, 255)
        startX:= -math.mod(camX, f32(TILE_SIZE))
        for x:=startX; x < WINDOW_W; x += TILE_SIZE {
            sdl.RenderLine(renderer, x, 0, x, WINDOW_H)
        }
        startY:= -math.mod(camY, f32(TILE_SIZE))
        for y:=startY; y < WINDOW_H; y += TILE_SIZE {
            sdl.RenderLine(renderer, 0, y, WINDOW_W, y)
        }

        // rectangel
        playerRect:=sdl.FRect{
            x = playerX - PLAYER_SIZE / 2,
            y = playerY - PLAYER_SIZE / 2,
            w = PLAYER_SIZE,
            h = PLAYER_SIZE
        }
        sdl.SetRenderDrawColor(renderer, 255, 0, 0, 255)
        sdl.RenderFillRect(renderer, &playerRect)
        
        // aim indicator
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