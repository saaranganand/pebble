// bullets, waves, other projectiles - spawn, update, draw

package main
import sdl "vendor:sdl3"
import "core:math"

import primatives "src:sdl_primatives"
import camera "src:camera"
import color "src:util/color"

MAX_BULLETS :: 256

MAX_PING_WAVES :: 3 // simultaneous ping waves and spacing

// bullets (bp, scope, trace)

Bullet :: struct {
    x, y: f32,
    vx, vy: f32,
    speed: f32,
    size: f32,
    damage: f32,
    alive: bool,
    type: BulletType
}

BulletType :: enum {
    BitPistol,
    // Scope,
    Trace
}

BulletPool :: struct {
    bullets : [MAX_BULLETS]Bullet
}

draw_bullets :: proc() {
    trace_tex: ^sdl.Texture
    pool := &game.bullets

    sdl.SetRenderDrawColor(primatives.global_renderer, 255, 165, 0, 255)
    for b in pool.bullets {
        if !b.alive {
            continue
        }
        switch b.type {
            case .BitPistol:
                color.sdl_set_color(color.Default_Palette_Color.YELLOW)
                camera.fill_circle({{b.x, b.y}, b.size})
            // case .Scope:
            //     bulletRect:=sdl.FRect{
            //     x = b.x, 
            //     y = b.y, 
            //     w = b.size*4, h = b.size/2}
            //     sdl.SetRenderDrawColor(primatives.global_renderer, 0, 255, 0, 255)
            //     sdl.RenderFillRect(primatives.global_renderer, &bulletRect)
            case .Trace:
                angle_deg := math.to_degrees(math.atan2(b.vy, b.vx))
                dst:=sdl.FRect{
                    x = b.x,
                    y = b.y,
                    w = b.size*5, h = b.size*5
                }
                //sdl.RenderTextureRotated(primatives.global_renderer, trace_tex, nil, &dst, f64(angle_deg), nil, .NONE)
        }
    }
}

update_bullets :: proc() {
    pool := &game.bullets
    //enemies := &game.enemies
    input := &game.input

    for &b in pool.bullets {
        if !b.alive { continue }

        b.x += b.vx * primatives.dt
        b.y += b.vy * primatives.dt

        if !camera.check_circle_visible({{b.x, b.y}, b.size}) {
            b.alive = false
        }

        if b.type == .Trace {
            // find nearest alive enemy to home towards
            /*nearest_ex, nearest_ey, found := find_nearest_enemy(enemies, b.x, b.y)

            if found {
                target_angle := math.atan2(nearest_ey - b.y, nearest_ex - b.x)
                current_angle := math.atan2(b.vy, b.vx)
                
                // wrap to [-PI,PI] so bullet always turns short way
                angle_diff := math.mod(target_angle - current_angle + math.PI, math.TAU) - math.PI
                
                // clamp turn amoutn per frame (smoother)
                turn_speed := game_config.weapons.trace.turn_speed
                new_angle := current_angle + clamp(angle_diff, -turn_speed * primatives.dt, turn_speed * primatives.dt)
                
                b.vx = math.cos(new_angle) * b.speed
                b.vy = math.sin(new_angle) * b.speed
            }*/
        }
    }
}


spawn_bullet :: proc(pool: ^BulletPool, x: f32, y: f32, aimAngle: f32, type: BulletType, damage: f32, speed: f32, size: f32) {
    for &b in pool.bullets {
        if !b.alive {
            b.alive = true
            b.x = x
            b.y = y
            b.speed = speed
            b.vx = math.cos(aimAngle) * speed
            b.vy = math.sin(aimAngle) * speed
            b.size = size
            b.type = type
            b.damage = damage
            return
        }
    }
}

// ping

PingWave :: struct {
    r: f32,
    x, y: f32,
    alive: bool,
    color: sdl.Color,
    max_r: f32,
    expand_speed: f32
}

PingWavePool :: struct {
    waves : [MAX_PING_WAVES]PingWave
}

draw_ping_waves :: proc() {
    pool := &game.waves

    sdl.SetRenderDrawBlendMode(primatives.global_renderer, sdl.BLENDMODE_BLEND)
    for w in pool.waves {
        if !w.alive {
            continue
        }
        else {
            thickness := f32(12) * (1 - w.r/w.max_r)
            alpha := u8(255 * (1 - w.r / w.max_r))
            color := sdl.Color{w.color.r, w.color.g, w.color.b, alpha}
            //draw_circle(w.x, w.y, w.r, color, thickness)
        }
    }
    sdl.SetRenderDrawBlendMode(primatives.global_renderer, sdl.BLENDMODE_NONE)
}

spawn_wave :: proc(pool: ^PingWavePool, x, y, max_r, expand_speed: f32, color: sdl.Color) {
    for &w in pool.waves {
        if !w.alive {
            w.alive = true
            w.x = x
            w.y = y
            w.r = 0
            w.color = color
            w.max_r = max_r
            w.expand_speed = expand_speed
            return
        }
    }
}

