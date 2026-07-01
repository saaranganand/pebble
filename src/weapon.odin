// weapon definitions and behaviours

package main

BITPISTOL_COOLDOWN :: 0.15 // time b/w bullets
BITPISTOL_DMG :: 10

SCOPE_MAX_CHARGE :: 0.75 // how many s for scope to max charge
SCOPE_MAX_DMG :: 70

BUS_MAX_HEAT :: 3.0 // how many s for bus to hit max heat
BUS_DMG :: 100 // normalized using dt

TRACE_COOLDOWN :: 1 // time b/w missiles
TRACE_DMG :: 30

PING_MAX_RADIUS :: 500 // how far a ping wave extends
PING_EXPAND_SPEED :: 150 // how fast a ping wave extends
PING_COOLDOWN :: f32(PING_MAX_RADIUS) / f32(PING_EXPAND_SPEED) / f32(MAX_PING_WAVES)
PING_DURATION :: 15 // how many s ping runs for after activation
PING_DMG :: 30

DAEMON_ORBIT_RADIUS :: 80 // how far from the player daemon orbits
DAEMON_ORBIT_SPEED :: 2 // how fast daemon orbits player
DAEMON_DURATION :: 15 // how many s daemon runs for after activation

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

// MANUYAL

// bitpistol
BitPistol :: struct {
    cooldown: f32
}

update_bitpistol :: proc(bp: ^BitPistol, pool: ^BulletPool, x: f32, y: f32, input: Input, aimAngle: f32, dt: f32) {
    if bp.cooldown > 0 {
        bp.cooldown -= dt
    }
    if input.fire && bp.cooldown <= 0 {
        spawn_bullet(pool, x, y, aimAngle, BulletType.BitPistol, BITPISTOL_DMG)
        bp.cooldown = BITPISTOL_COOLDOWN
    }
}

// scope
Scope :: struct {
    is_charging: bool,
    charge: f32,
    was_firing: bool
}

update_scope :: proc(sc: ^Scope, pool: ^BulletPool, x: f32, y: f32, input: Input, aimAngle: f32, dt: f32) {
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
        spawn_bullet(pool,x,y,aimAngle, BulletType.Scope, sc.charge / SCOPE_MAX_CHARGE * SCOPE_MAX_DMG)
        sc.is_charging = false
        sc.charge = 0
    }

    sc.was_firing = input.fire
}

// HOLD

// bus
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

// trace
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

// AUTO

// ping
Ping :: struct {
    cooldown: f32, // wave cooldown
    is_active: bool,
    timer: f32
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
        spawn_wave(pool, x, y)
        ping.cooldown = PING_COOLDOWN
    }
    for &w in pool.waves {
        if !w.alive {
            continue
        }
        else {
            w.r += PING_EXPAND_SPEED * dt
            if w.r >= PING_MAX_RADIUS {
                w.alive = false
            }
        }
    }
}

// daemin
Daemon :: struct {
    is_active: bool,
    timer: f32,
    orbit_angle: f32
}

update_daemon :: proc(d: ^Daemon, is_selected: bool, input: Input, dt: f32) {
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

    d.orbit_angle += DAEMON_ORBIT_SPEED * dt
}