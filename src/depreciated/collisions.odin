// collision detection

package depreciated
import sdl "vendor:sdl3"
import "core:math"
import "core:math/rand"
/*
// player and enemy
detect_collision :: proc() {
    pool := &game.enemies
    player := &game.player

    player_left   := player.x - PLAYER_SIZE/2
    player_right  := player.x + PLAYER_SIZE/2
    player_top    := player.y - PLAYER_SIZE/2
    player_bottom := player.y + PLAYER_SIZE/2

    for &e in pool.enemies {
        if !e.alive {
            continue
        }
        size:=enemy_size(e)
        damage := enemy_damage(e)

        enemy_left   := e.x - size
        enemy_right  := e.x + size
        enemy_top    := e.y - size
        enemy_bottom := e.y + size

        overlap := player_right > enemy_left &&
                   player_left  < enemy_right &&
                   player_bottom > enemy_top &&
                   player_top   < enemy_bottom

        if overlap {
            player.hp -= damage * game.dt
        }
    }
}

// bullet and enemy
detect_bullet_collision :: proc() {
    enemies := &game.enemies
    bullets := &game.bullets

    for &b in bullets.bullets {
        if !b.alive {
            continue
        }
        bullet_left := b.x
        bullet_right := b.x + b.size
        bullet_top := b.y
        bullet_bottom := b.y + b.size

        for &e in enemies.enemies {
            if !e.alive {
                continue
            }
            size := enemy_size(e)

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
                if b.type == .BitPistol && rand.float32() < game_config.weapons.bitpistol.miss_chance {
                    // 50% chance of 0 dmg
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

// scope and enemy
scope_hitscan :: proc(enemies: ^EnemyPool, waves: ^PingWavePool, px, py, aim_angle, charge: f32) {
    nearest_dot := max(f32)
    nearest_enemy: ^Enemy = nil

    for &e in enemies.enemies {
        if !e.alive{
            continue
        }
        size := enemy_size(e)

        // perpendicular dist from enemy center to aim direction
        // if < enemy size,  shot passes through enemy hitbox
        perp_dist := abs((e.x - px) * math.sin(aim_angle) - (e.y - py) * math.cos(aim_angle))
        
        // dist along aim direction (signed)
        dot := (e.x - px) * math.cos(aim_angle) + (e.y - py) * math.sin(aim_angle)

        if perp_dist < size && dot > 0 && dot < nearest_dot {
            nearest_dot = dot
            nearest_enemy = &e
        }
    }

    if nearest_enemy != nil{
        cfg := game_config.weapons.scope
        
        nearest_enemy.hp -= (charge / cfg.max_charge) * cfg.damage
        
        spawn_wave(waves, nearest_enemy.x, nearest_enemy.y, 50.0, 300.0, sdl.Color{255, 0, 0, 255})

        if nearest_enemy.hp <= 0 {
            nearest_enemy.alive = false
        }
    }
}

// bus beam and enemy
detect_bus_damage :: proc(enemies: ^EnemyPool, bus: Bus, px, py, aim_angle: f32, input: Input, dt: f32) {
    if !input.fire || bus.is_overheated {
        return
    }
    for &e in enemies.enemies {
        if !e.alive {
            continue
        }
        size := enemy_size(e)

        // perpendicular dist from enemy center to aim direction
        // if < enemy size,  shot passes through enemy hitbox
        perp_dist := abs((e.x - px) * math.sin(aim_angle) - (e.y - py) * math.cos(aim_angle))
        
        // dist along aim direction (signed)
        dot := (e.x - px) * math.cos(aim_angle) + (e.y - py) * math.sin(aim_angle)
        
        if perp_dist < (size+5) && dot > 0 {
            if e.hp <= 0 {
                e.alive = false
            }
            e.hp -= game_config.weapons.bus.damage * dt
        }
    }
}

// ping wave and enemy
detect_ping_damage :: proc() {
    enemies := &game.enemies
    waves := &game.waves

    for &w in waves.waves {
        if !w.alive {
            continue
        }
        for &e in enemies.enemies {
            if !e.alive {
                continue
            }
            size := enemy_size(e)
            dx := e.x - w.x
            dy := e.y - w.y
            dist := math.sqrt(dx*dx + dy*dy)

            if dist < w.r + size {
                if e.hp <= 0 {
                    e.alive = false
                }
                e.hp -= game_config.weapons.ping.damage * (1 - w.r / w.max_r) * game.dt
            }
        }
    }
}
    */