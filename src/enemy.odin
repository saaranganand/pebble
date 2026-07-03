package main
import sdl "vendor:sdl3"
import "core:time"
import "core:math"
import rand "core:math/rand"

MAX_ENEMIES :: 64
ENEMY_SPAWN_RATE :: 2
ENEMY_SPAWN_DIST :: 750 // how far away enemies spawn in relation to player

SMALL_HEALTH :: 30
SMALL_SPEED :: 160
SMALL_SIZE :: 10
SMALL_DAMAGE :: 5

REGULAR_HEALTH :: 50
REGULAR_SPEED :: 80
REGULAR_SIZE :: 20
REGULAR_DAMAGE :: 10

LARGE_HEALTH :: 70
LARGE_SPEED :: 30
LARGE_SIZE :: 40
LARGE_DAMAGE :: 20

EnemyType :: enum {
    Small,
    Regular,
    Large
}

Enemy :: struct {
    hp: f32,
    type: EnemyType,
    x,y: f32,
    alive: bool
}

EnemyPool :: struct {
    enemies: [MAX_ENEMIES]Enemy,
    spawn_timer: f32
}


enemy_size :: proc(e: Enemy) -> f32 {
    switch e.type {
        case .Small:
            return SMALL_SIZE
        case .Regular:
            return REGULAR_SIZE
        case .Large:
            return LARGE_SIZE
    }
    return 0
}

enemy_damage :: proc(e: Enemy) -> f32 {
    switch e.type {
        case .Small:
            return SMALL_DAMAGE
        case .Regular:
            return REGULAR_DAMAGE
        case .Large:
            return LARGE_DAMAGE
    }
    return 0
}

find_nearest_enemy :: proc(enemies: ^EnemyPool, x, y: f32) -> (ex, ey: f32, found: bool) {
    nearest_dist := max(f32)

    for e in enemies.enemies {
        if !e.alive { continue }
        dx := e.x - x
        dy := e.y - y
        dist := math.sqrt(dx*dx + dy*dy)
        if dist < nearest_dist {
            nearest_dist = dist
            ex = e.x
            ey = e.y
            found = true
        }
    }
    return
}

draw_enemies :: proc() {
    pool := &game.enemies

    for e in pool.enemies {
        if !e.alive {
            continue
        }
        size : f32
        switch e.type {
            case .Small:
                size = SMALL_SIZE
                sdl.SetRenderDrawColor(global_renderer, 0, 255, 255, 255) // cyan
            case .Regular:
                size = REGULAR_SIZE
                sdl.SetRenderDrawColor(global_renderer, 129, 128, 0, 255) // dark yellow
            case .Large:
                size = LARGE_SIZE
                sdl.SetRenderDrawColor(global_renderer, 139, 0, 0, 255) // dark red
        }

        rect:= sdl.FRect{
            x = e.x-size,
            y = e.y-size,
            w = size*2,
            h = size*2
        }
        sdl.RenderFillRect(global_renderer, &rect)
    }
}

spawn_enemy :: proc(pool: ^EnemyPool, px, py: f32) {
    for &e in pool.enemies {
        if !e.alive {
            angle := rand.float32() * math.TAU
            e.alive = true
            e.x = px + math.cos(angle) * ENEMY_SPAWN_DIST
            e.y = py + math.sin(angle) * ENEMY_SPAWN_DIST
            r := rand.float32()
            if r < 0.6 {
                e.type = .Regular
                e.hp = REGULAR_HEALTH
            }
            else if r < 0.85 {
                e.type = .Small
                e.hp = SMALL_HEALTH
            }
            else {
                e.type = .Large
                e.hp = LARGE_HEALTH
            }
            return
        }
    }
}

update_enemies :: proc(px, py: f32) {
    pool := &game.enemies
    input := &game.input


    pool.spawn_timer -= game.dt
    if pool.spawn_timer <= 0 {
        spawn_enemy(pool, px, py)
        pool.spawn_timer = ENEMY_SPAWN_RATE
    }
    for &e in pool.enemies {
        if !e.alive {
            continue
        }
        dx := px - e.x
        dy := py - e.y
        dist := math.sqrt(dx*dx + dy*dy)

        speed: f32
        switch e.type {
            case .Small:
                speed = SMALL_SPEED
            case .Regular:
                speed = REGULAR_SPEED
            case .Large:
                speed = LARGE_SPEED
        }
        e.x += (dx/dist) * speed * game.dt
        e.y += (dy/dist) * speed * game.dt

        e.x -= input.dx * CAM_SPEED * game.dt
        e.y -= input.dy * CAM_SPEED * game.dt
    }
}