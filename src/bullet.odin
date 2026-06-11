package main
import sdl "vendor:sdl3"
import "core:math"

MAX_BULLETS :: 256
BULLET_SPEED :: 600
BULLET_SIZE :: 8.0

Bullet :: struct {
    x, y: f32,
    vx, vy: f32,
    size: f32,
    alive: bool,
    type: BulletType
}

BulletType :: enum {
    BitPistol,
    Scope
}

BulletPool :: struct {
    bullets : [MAX_BULLETS]Bullet
}

draw_bullets :: proc(renderer: ^sdl.Renderer, pool: ^BulletPool) {
    sdl.SetRenderDrawColor(renderer, 255, 165, 0, 255)
    for b in pool.bullets {
        if !b.alive {
            continue
        }
        switch b.type {
            case .BitPistol:
                bulletRect:=sdl.FRect{
                x = b.x, 
                y = b.y, 
                w = b.size, h = b.size}
                sdl.SetRenderDrawColor(renderer, 255, 165, 0, 255)
                sdl.RenderFillRect(renderer, &bulletRect)
            case .Scope:
                bulletRect:=sdl.FRect{
                x = b.x, 
                y = b.y, 
                w = b.size*4, h = b.size/2}
                sdl.SetRenderDrawColor(renderer, 0, 255, 0, 255)
                sdl.RenderFillRect(renderer, &bulletRect)
        }
    }
}

update_bullets :: proc(pool: ^BulletPool, dt: f32, input: Input) {
    for &b in pool.bullets {
        if !b.alive {
            continue
        }
        b.x += b.vx * dt
        b.y += b.vy * dt
        b.x -= input.dx * CAM_SPEED * dt
        b.y -= input.dy * CAM_SPEED * dt
        if b.x < 0 || b.x > WINDOW_W || b.y < 0 || b.y > WINDOW_H {
            b.alive = false
        }

    }
}

spawn_bullet :: proc(pool: ^BulletPool, x: f32, y: f32, aimAngle: f32, type: BulletType) {
    for &b in pool.bullets {
        if !b.alive {
            b.alive = true
            b.x = x
            b.y = y
            b.vx = math.cos(aimAngle) * BULLET_SPEED
            b.vy = math.sin(aimAngle) *BULLET_SPEED
            b.size = BULLET_SIZE
            b.type = type
            return
        }
    }
}

// bus

draw_bus :: proc(renderer: ^sdl.Renderer, bus: Bus, input: Input, x: f32, y: f32, aimAngle: f32) {
    if input.fire && !bus.is_overheated {
        end_x := x + math.cos(aimAngle) * 2000
        end_y := y + math.sin(aimAngle) * 2000
        line := sdl.RenderLine(renderer, x, y, end_x, end_y)
    }
}