// weapon definitions and behaviours

package main

import sdl "vendor:sdl3"
import "core:math"
import "core:fmt"

BITPISTOL_FIRERATE :: 1 // shots per s
BITPISTOL_INTERVAL :: 1.0 / BITPISTOL_FIRERATE // time b/w bullets
BITPISTOL_DMG :: 10

SCOPE_MAX_CHARGE :: 0.75 // how many s for scope to max charge
SCOPE_MAX_DMG :: 70

BUS_MAX_HEAT :: 3.0 // how many s for bus to hit max heat
BUS_DMG :: 100 // normalized using dt

TRACE_COOLDOWN :: 1 // time b/w missiles
TRACE_DMG :: 30

PING_MAX_RADIUS :: 500 // how far a ping wave extends
PING_EXPAND_SPEED :: 150 // how fast a ping wave extends
PING_COOLDOWN :: f32(PING_MAX_RADIUS) / f32(PING_EXPAND_SPEED) / f32(MAX_PING_WAVES) // spawn interval=lifetime/wavecount, keeps waves evenly spaced
PING_DURATION :: 15 // how many s ping runs for after activation
PING_DMG :: 30

DAEMON_ORBIT_RADIUS :: 80 // how far from the player daemon orbits
DAEMON_CONE_ANGLE :: math.PI // 180deg cone
DAEMON_ORBIT_SPEED :: 1.5 // how fast daemon orbits player
DAEMON_DURATION :: 15 // how many s daemon runs for after activation
DAEMON_FIRERATE :: 1 // shots per s
DAEMON_INTERVAL :: 1.0 / DAEMON_FIRERATE // time b/w bullets
DAEMON_DMG :: 10

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

update_bitpistol :: proc(bp: ^BitPistol, pool: ^BulletPool, x: f32, y: f32, input: Input, aimAngle: f32, dt: f32) {
    if bp.cooldown > 0 {
        bp.cooldown -= dt
    }
    if input.fire && bp.cooldown <= 0 {
        spawn_bullet(pool, x, y, aimAngle, BulletType.BitPistol, BITPISTOL_DMG)
        bp.cooldown = BITPISTOL_INTERVAL
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
apply_movement_penalty :: proc(player: Player, input: ^Input) {
    if player.active_category == .Manual && player.weaponManual == .Scope && player.scope.is_charging {
        input.dx *= 0.2 // 80% slowdown
        input.dy *= 0.2
    }
}

update_scope :: proc(sc: ^Scope, enemies: ^EnemyPool, waves: ^PingWavePool, pool: ^BulletPool, x: f32, y: f32, input: Input, aimAngle: f32, dt: f32) {
    // check if was firing already
    if input.fire && !sc.was_firing {
        sc.is_charging = true
    }
    // if firing, charge go up
    if sc.is_charging {
        sc.charge += dt
    }

    // fire only when mouse let go / max charge reached
    should_fire:= (!input.fire && sc.is_charging) || sc.charge >= SCOPE_MAX_CHARGE
    if should_fire {
        scope_hitscan(enemies, waves, x, y, aimAngle, sc.charge)
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

update_bus :: proc(bus: ^Bus, input: Input, dt: f32) {
    if bus.is_overheated {
        bus.heat = max(bus.heat-dt, 0) // slow cooldown
        if bus.heat <= 0 { // not overheated anymore
            bus.is_overheated = false
        }
    }
    else {
        if input.fire { // firing
            bus.heat += dt // build heat
            if bus.heat >= BUS_MAX_HEAT { // max heat reached
                bus.is_overheated = true
            }
        }
        else { // not firing
            bus.heat = max(bus.heat - dt * 2, 0) // fast cooldown
        }
    }
}

// TRACE
Trace :: struct {
    cooldown: f32
}

update_trace :: proc(tr: ^Trace, pool: ^BulletPool, x: f32, y: f32, input: Input, aimAngle: f32, dt: f32) {
    if tr.cooldown > 0 {
        tr.cooldown -= dt
    }
    if input.fire && tr.cooldown <= 0 {
        spawn_bullet(pool, x, y, aimAngle, BulletType.Trace, TRACE_DMG)
        tr.cooldown = TRACE_COOLDOWN
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

update_waves :: proc(pool: ^PingWavePool, dt: f32) {
    for &w in pool.waves {
        if !w.alive {
            continue
        }
        else {
            w.r += w.expand_speed * dt
            if w.r >= w.max_r {
                w.alive = false
            }
        }
    }
}

update_ping :: proc(ping: ^Ping, pool: ^PingWavePool, x, y: f32, input: Input, is_selected: bool, dt: f32) {
    if is_selected && input.fire && !ping.is_active {
        ping.is_active = true
        ping.timer = PING_DURATION
        ping.cooldown = 0
    }

    if !ping.is_active {
        return
    }

    ping.timer -= dt
    if ping.timer <= 0 {
        ping.is_active = false
        for &w in pool.waves {
            w.alive = false
        }
        return
    }
    
    if ping.cooldown > 0 {
        ping.cooldown -= dt
    }
    else {
        spawn_wave(pool, x, y, PING_MAX_RADIUS, PING_EXPAND_SPEED, sdl.Color{0, 255, 0, 255})
        ping.cooldown = PING_COOLDOWN
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

update_daemon :: proc(d: ^Daemon, pool: ^BulletPool, enemies: ^EnemyPool, px, py: f32, is_selected: bool, input: Input, dt: f32) {
    if is_selected && input.fire && !d.is_active {
        d.is_active = true
        d.timer = DAEMON_DURATION
    }

    if !d.is_active {
        return
    }

    d.timer -= dt
    if d.timer <= 0 {
        d.is_active = false
        return
    }
    if d.fire_cooldown > 0 {
        d.fire_cooldown -= dt
    } else {
        nearest_ex, nearest_ey, found := find_nearest_enemy(enemies, d.x, d.y)
        fmt.println(found)
        d.fire_cooldown = DAEMON_INTERVAL
        if found {
            player_to_enemy := math.atan2(nearest_ey - py, nearest_ex - px)
            diff2 := player_to_enemy - d.orbit_angle
            same_side := abs(math.atan2(math.sin(diff2), math.cos(diff2))) < math.PI / 2
            if same_side  {
                spawn_bullet(pool, d.x, d.y, player_to_enemy, .BitPistol, DAEMON_DMG)
            }
        }
    }


    d.x = px + math.cos(d.orbit_angle) * DAEMON_ORBIT_RADIUS
    d.y = py + math.sin(d.orbit_angle) * DAEMON_ORBIT_RADIUS
    d.orbit_angle += DAEMON_ORBIT_SPEED * dt
}