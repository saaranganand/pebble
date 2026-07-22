// weapon definitions and behaviours

package main

import sdl "vendor:sdl3"
import "core:math"

import primatives "sdl_primatives"
import assets "assets" 
import entity "entity"
import effect "entity_effect"
import input "input"

WeaponCategory :: enum {
    Manual,
    Hold,
    Auto,
}

WeaponManual :: enum {
    BitPistol,
    Scope
}
WeaponHold :: enum {
    Bus,
    Trace
}
WeaponAuto :: enum {
    Ping,
    Daemon
}

// ---
// MANUAL
// ---

// BITPISTOL
BitPistol :: struct {
    cooldown: f32
}

update_bitpistol :: proc(bp: ^BitPistol, x: f32, y: f32, aimAngle: f32) {
    pool := &game.bullets
    input := &game.input
    cfg := game_config.weapons.bitpistol

    if bp.cooldown > 0 {
        bp.cooldown -= primatives.dt
    }
    if input.fire && bp.cooldown <= 0 {
        //effect_data := effect.effect_application_data_from_tag("burn_high", game.player.entity, game.player.entity)
        //effect.effect_manager_queue_apply(effect_data)

        //assets.sound_play("sounds/silly/pirate_bell.wav")
        //spawn_bullet(pool, x, y, aimAngle, BulletType.BitPistol, cfg.damage, cfg.bullet_speed, cfg.bullet_size)
        bp.cooldown = 1.0 / cfg.fire_rate
    }
}

// SCOPE
Scope :: struct {
    is_charging: bool,
    charge: f32,
    was_firing: bool
}

// slowdown when charging
// must run before update_player and update_enemies or it fucks up cam :(
apply_movement_penalty :: proc() {
    player := &game.player
    input := &game.input

    if player.active_category == .Manual && player.weaponManual == .Scope && player.scope.is_charging {
        input.direction *= 0.2
    }
}

update_scope :: proc(sc: ^Scope, x: f32, y: f32, aimAngle: f32) {
    pool := &game.bullets
    input := &game.input
    waves := &game.waves
    //enemies := &game.enemies
    cfg := game_config.weapons.scope

    // check if was firing already
    if input.fire && !sc.was_firing {
        sc.is_charging = true
    }
    // if firing, charge go up
    if sc.is_charging {
        sc.charge += primatives.dt
    }

    // fire only when mouse let go / max charge reached
    should_fire:= (!input.fire && sc.is_charging) || sc.charge >= cfg.max_charge
    if should_fire {
        //scope_hitscan(enemies, waves, x, y, aimAngle, sc.charge)
        sc.is_charging = false
        sc.charge = 0
    }

    // prevents retriggering if mouse still held after fire
    sc.was_firing = input.fire
}

// ---
// HOLD
// ---

// BUS
Bus :: struct {
    heat: f32,
    is_overheated: bool
}

update_bus :: proc(bus: ^Bus) {
    input := &game.input
    cfg := game_config.weapons.bus
    if bus.is_overheated {
        bus.heat = max(bus.heat - primatives.dt, 0) // slow cooldown
        if bus.heat <= 0 { // not overheated anymore
            bus.is_overheated = false
        }
    }
    else {
        if input.fire { // firing
            bus.heat += primatives.dt // build heat
            if bus.heat >= cfg.max_heat { // max heat reached
                bus.is_overheated = true
            }
        }
        else { // not firing
            bus.heat = max(bus.heat - primatives.dt * 2, 0) // fast cooldown
        }
    }
}

draw_bus :: proc(renderer: ^sdl.Renderer, bus: Bus, input: input.Input, x: f32, y: f32, aimAngle: f32) {
    sdl.SetRenderDrawColor(renderer, 0, 200, 255, 255) // cyan

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

// TRACE
Trace :: struct {
    cooldown: f32
}

update_trace :: proc(tr: ^Trace, x: f32, y: f32, aimAngle: f32) {
    pool := &game.bullets
    input := &game.input
    cfg := game_config.weapons.trace

    if tr.cooldown > 0 {
        tr.cooldown -= primatives.dt
    }
    if input.fire && tr.cooldown <= 0 {
        spawn_bullet(pool, x, y, aimAngle, BulletType.Trace, cfg.damage, cfg.bullet_speed, cfg.bullet_size)
        tr.cooldown = cfg.cooldown
    }
}

// ---
// AUTO
// ---

// PING
Ping :: struct {
    cooldown: f32, // wave cooldown
    is_active: bool,
    timer: f32
}

update_waves :: proc() {
    pool := &game.waves

    for &w in pool.waves {
        if !w.alive {
            continue
        }
        else {
            w.r += w.expand_speed * primatives.dt
            if w.r >= w.max_r {
                w.alive = false
            }
        }
    }
}

update_ping :: proc(ping: ^Ping, pool: ^PingWavePool, x, y: f32, input: input.Input, is_selected: bool) {
    cfg := game_config.weapons.ping

    wave_interval := cfg.max_radius / cfg.expand_speed / f32(MAX_PING_WAVES)

    if is_selected && input.fire && !ping.is_active {
        ping.is_active = true
        ping.timer = cfg.duration
        ping.cooldown = 0
    }

    if !ping.is_active {
        return
    }

    ping.timer -= primatives.dt
    if ping.timer <= 0 {
        ping.is_active = false
        for &w in pool.waves {
            w.alive = false
        }
        return
    }

    if ping.cooldown > 0 {
        ping.cooldown -= primatives.dt
    }
    else {
        spawn_wave(pool, x, y, cfg.max_radius, cfg.expand_speed, sdl.Color{0, 255, 0, 255})
        ping.cooldown = wave_interval
    }
}

// DAEMON
Daemon :: struct {
    is_active: bool,
    x, y: f32,
    timer: f32,
    orbit_angle: f32,
    fire_cooldown: f32
}

draw_daemon :: proc(renderer: ^sdl.Renderer, d: Daemon) {
    if !d.is_active {
        return
    }
    rect := sdl.FRect{
        x = d.x-8,
        y = d.y-8,
        w = 16,
        h = 16
    }
    sdl.SetRenderDrawColor(renderer, 180, 0, 255, 255)
    sdl.RenderFillRect(renderer, &rect)
}

update_daemon :: proc(d: ^Daemon, pool: ^BulletPool, /*enemies: ^EnemyPool,*/ px, py: f32, is_selected: bool, input: input.Input) {
    cfg := game_config.weapons.daemon
    if is_selected && input.fire && !d.is_active {
        d.is_active = true
        d.timer = cfg.duration
    }

    if !d.is_active {
        return
    }

    d.timer -= primatives.dt
    if d.timer <= 0 {
        d.is_active = false
        return
    }
    /*if d.fire_cooldown > 0 {
        d.fire_cooldown -= primatives.dt
    } else {
        nearest_ex, nearest_ey, found := find_nearest_enemy(enemies, d.x, d.y)
        d.fire_cooldown = 1.0 / cfg.fire_rate
        if found {
            player_to_enemy := math.atan2(nearest_ey - py, nearest_ex - px)
            diff2 := player_to_enemy - d.orbit_angle
            same_side := abs(math.atan2(math.sin(diff2), math.cos(diff2))) < cfg.cone_angle / 2
            if same_side  {
                spawn_bullet(pool, d.x, d.y, player_to_enemy, .BitPistol, cfg.damage, game_config.weapons.bitpistol.bullet_speed, game_config.weapons.bitpistol.bullet_size)
            }
        }
    }*/

    d.x = px + math.cos(d.orbit_angle) * cfg.orbit_radius
    d.y = py + math.sin(d.orbit_angle) * cfg.orbit_radius
    d.orbit_angle += cfg.orbit_speed * primatives.dt
}