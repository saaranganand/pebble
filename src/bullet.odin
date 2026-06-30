// projectile logic, drawing

package main
import sdl "vendor:sdl3"
import "core:math"
import "core:math/rand"

MAX_BULLETS :: 256
BULLET_SPEED :: 600
BULLET_SIZE :: 8.0
MAX_PING_WAVES :: 3 // simultaneous ping waves and spacing

// bullets (bp, scope, trace)

Bullet :: struct {
    x, y: f32,
    vx, vy: f32,
    size: f32,
    damage: f32,
    alive: bool,
    type: BulletType
}

BulletType :: enum {
    BitPistol,
    Scope,
    Trace
}

BulletPool :: struct {
    bullets : [MAX_BULLETS]Bullet
}

draw_bullets :: proc(renderer: ^sdl.Renderer, pool: ^BulletPool, trace_tex: ^sdl.Texture) {
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
            case .Trace:
                angle_deg := math.to_degrees(math.atan2(b.vy, b.vx))
                dst:=sdl.FRect{
                    x = b.x,
                    y = b.y,
                    w = b.size*5, h = b.size*5
                }
                sdl.RenderTextureRotated(renderer, trace_tex, nil, &dst, f64(angle_deg), nil, .NONE)
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

spawn_bullet :: proc(pool: ^BulletPool, x: f32, y: f32, aimAngle: f32, type: BulletType, damage: f32) {
    for &b in pool.bullets {
        if !b.alive {
            b.alive = true
            b.x = x
            b.y = y
            b.vx = math.cos(aimAngle) * BULLET_SPEED
            b.vy = math.sin(aimAngle) *BULLET_SPEED
            b.size = BULLET_SIZE
            b.type = type
            b.damage = damage
            return
        }
    }
}

detect_bullet_collision :: proc(pool: ^EnemyPool, bullets: ^BulletPool, dt: f32) {
    
    for &b in bullets.bullets {
        if !b.alive {
            continue
        }
        bullet_left := b.x
        bullet_right := b.x + b.size
        bullet_top := b.y
        bullet_bottom := b.y + b.size

        for &e in pool.enemies {
            if !e.alive {
                continue
            }
            size: f32
            switch e.type {
                case .Small:
                    size = SMALL_SIZE
                case .Regular:
                    size = REGULAR_SIZE
                case .Large:
                    size = LARGE_SIZE
            }

            enemy_left   := e.x - size
            enemy_right  := e.x + size
            enemy_top    := e.y - size
            enemy_bottom := e.y + size

            overlap := bullet_right > enemy_left &&
                    bullet_left  < enemy_right &&
                    bullet_bottom > enemy_top &&
                    bullet_top   < enemy_bottom

            if overlap {
                dmg := b.damage
                if b.type == .BitPistol && rand.float32() < 0.5 {
                    dmg = 0
                }
                e.hp -= dmg
                b.alive = false
                if e.hp <= 0 {
                    e.alive = false
                }
            }
        }
    }
}

// bus

draw_bus :: proc(renderer: ^sdl.Renderer, bus: Bus, input: Input, x: f32, y: f32, aimAngle: f32) {
    if input.fire && !bus.is_overheated {
        end_x := x + math.cos(aimAngle) * 2000
        end_y := y + math.sin(aimAngle) * 2000
        
        perp_x := -math.sin(aimAngle)
        perp_y :=  math.cos(aimAngle)

        for i in -2..=2 {
            ox := perp_x * f32(i)
            oy := perp_y * f32(i)
            sdl.RenderLine(renderer, x + ox, y + oy, end_x + ox, end_y + oy)
        }
    }
}

// ping

PingWave :: struct {
    r: f32,
    x, y: f32,
    alive: bool
}

PingWavePool :: struct {
    waves : [MAX_PING_WAVES]PingWave
}

draw_ping_waves :: proc(renderer: ^sdl.Renderer, pool: ^PingWavePool) {
    sdl.SetRenderDrawBlendMode(renderer, sdl.BLENDMODE_BLEND)
    for w in pool.waves {
        if !w.alive {
            continue
        }
        else {
            alpha := u8(255*(1- w.r/PING_MAX_RADIUS))
            color := sdl.Color{0, 255, 0, alpha}
            thickness := f32(12) * (1 - w.r/PING_MAX_RADIUS)
            
            draw_circle(renderer, w.x, w.y, w.r, color, thickness) 
        }
    }
    sdl.SetRenderDrawBlendMode(renderer, sdl.BLENDMODE_NONE)
}

spawn_wave :: proc(pool: ^PingWavePool, x, y: f32) {
    for &w in pool.waves {
        if !w.alive {
            w.alive = true
            w.x = x
            w.y = y
            w.r = 0
            return
        }
    }
}

// daemon

draw_daemon :: proc(renderer: ^sdl.Renderer, d: Daemon, px, py: f32) {
    if !d.is_active {
        return 
    }
    dx := px + math.cos(d.orbit_angle) * DAEMON_ORBIT_RADIUS
    dy := py + math.sin(d.orbit_angle) * DAEMON_ORBIT_RADIUS
    rect := sdl.FRect{
        x = dx-8,
        y = dy-8,
        w= 16,
        h = 16
    }
    sdl.SetRenderDrawColor(renderer, 180, 0, 255, 255)
    sdl.RenderFillRect(renderer, &rect)
}