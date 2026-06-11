// weapon definitions and behaviours

package main

BITPISTOL_COOLDOWN :: 0.15 // time b/w bp bullets
SCOPE_MAX_CHARGE :: 0.75 // how many s for scope to max charge
BUS_MAX_HEAT :: 3.0
BUS_OVERHEAT_COOLDOWN :: 1.0

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
        spawn_bullet(pool, x, y, aimAngle, BulletType.BitPistol)
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
        spawn_bullet(pool,x,y,aimAngle, BulletType.Scope)
        sc.is_charging = false
        sc.charge = 0
    }

    sc.was_firing = input.fire
}

// HOLD

// bus
Bus :: struct {
    heat: f32,
    is_overheated: bool,
    cooldown: f32
}

update_bus :: proc(bus: ^Bus, input: Input, dt: f32) {
    if bus.is_overheated {
        bus.cooldown -= dt
        if bus.cooldown <= 0 { // not overheated anymore
            bus.is_overheated = false
            bus.cooldown = 0
        }
    }
    else {
        if input.fire {
            bus.heat += dt
            if bus.heat >= BUS_MAX_HEAT { // overheat
                bus.is_overheated = true
                bus.heat = 0
            }
        }
        else {
            bus.heat = max(bus.heat - dt, 0)
        }
    }
}

// trace
Trace :: struct {
    cooldown: f32
}

update_trace :: proc() {

}

// AUTO

// ping
Ping :: struct {
    cooldown: f32
}

update_ping :: proc() {

}

// daemin
Daemon :: struct {
    cooldown: f32,
    is_deployed: bool,
    timer: f32
}

update_daemon :: proc() {

}