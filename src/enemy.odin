// enemy spawn, update, draw

package main
import sdl "vendor:sdl3"
import "core:time"
import "core:math"
import rand "core:math/rand"

MAX_ENEMIES :: 64

EnemyType :: enum {
    Small,
    Regular,
    Large,
    // add more enemy types here
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

// returns config for EnemyType for when we dont have an Enemy instance
enemy_cfg_for_type :: proc(t: EnemyType) -> EnemyTypeConfig {
    switch t {
    case .Small:
        return game_config.enemies.small
    case .Regular:
        return game_config.enemies.regular
    case .Large:
        return game_config.enemies.large
    // add more here
    }
    return {}
}
// wrapper for above
enemy_cfg :: proc(e: Enemy) -> EnemyTypeConfig {
    return enemy_cfg_for_type(e.type)
}

enemy_size :: proc(e: Enemy) -> f32 {
    return enemy_cfg(e).size
}

enemy_damage :: proc(e: Enemy) -> f32 {
    return enemy_cfg(e).damage
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

draw_enemies :: proc(renderer: ^sdl.Renderer, pool: ^EnemyPool) {
    for e in pool.enemies {
        if !e.alive {
            continue
        }
        size := enemy_cfg(e).size
        switch e.type {
            // TODO: replace with sprites eventually
            case .Small:
                sdl.SetRenderDrawColor(renderer, 0, 255, 255, 255) // cyan
            case .Regular:
                sdl.SetRenderDrawColor(renderer, 129, 128, 0, 255) // dark yellow
            case .Large:
                sdl.SetRenderDrawColor(renderer, 139, 0, 0, 255) // dark red
            // add more here
        }

        rect:= sdl.FRect{
            x = e.x-size,
            y = e.y-size,
            w = size*2,
            h = size*2
        }
        sdl.RenderFillRect(renderer, &rect)
    }
}

spawn_enemy :: proc(pool: ^EnemyPool, px, py: f32) {
    for &e in pool.enemies {
        if !e.alive {
            angle := rand.float32() * math.TAU
            e.alive = true
            e.x = px + math.cos(angle) * game_config.enemies.spawn_dist
            e.y = py + math.sin(angle) * game_config.enemies.spawn_dist
            
            // weighted random type selection from config
            total: f32
            for t in EnemyType { total += enemy_cfg_for_type(t).spawn_weight }
            r := rand.float32() * total

            cumulative: f32
            for t in EnemyType {
                cumulative += enemy_cfg_for_type(t).spawn_weight
                if r < cumulative {
                    e.type = t
                    e.hp = enemy_cfg_for_type(t).health
                    break
                }
            }
            return
        }
    }
}

update_enemies :: proc(pool: ^EnemyPool, px, py: f32, input: Input, dt: f32) {
    pool.spawn_timer -= dt
    if pool.spawn_timer <= 0 {
        spawn_enemy(pool, px, py)
        pool.spawn_timer = game_config.enemies.spawn_rate
    }
    for &e in pool.enemies {
        if !e.alive {
            continue
        }
        
        dx := px - e.x
        dy := py - e.y
        dist := math.sqrt(dx*dx + dy*dy)

        speed := enemy_cfg(e).speed
        e.x += (dx/dist) * speed * dt
        e.y += (dy/dist) * speed * dt

        e.x -= input.dx * CAM_SPEED * dt
        e.y -= input.dy * CAM_SPEED * dt
    }
}
