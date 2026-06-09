package main

BITPISTOL_COOLDOWN :: 0.15

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

// AIM

// bitpistol
BitPistol :: struct {
    cooldown: f32
}

update_bitpistol :: proc(bp: ^BitPistol, pool: ^BulletPool, x: f32, y: f32, input: Input, aimAngle: f32, dt: f32) {
    if bp.cooldown > 0 {
        bp.cooldown -= dt
    }
    if input.fire && bp.cooldown <= 0 {
        spawn_bullet(pool, x, y, aimAngle)
        bp.cooldown = BITPISTOL_COOLDOWN
    }
}

// scope
Scope :: struct {
    is_charging: bool,
    charge: f32
}

update_scope :: proc(sc: ^Scope, pool: ^BulletPool, x: f32, y: f32, input: Input, aimAngle: f32, dt: f32) {
    if input.fire {
        sc.is_charging = true
        sc.charge += dt
    }
    else if !input.fire{
        if sc.is_charging == true {
            spawn_bullet(pool, x, y, aimAngle)
            sc.charge = 0
            sc.is_charging = false
        }
    }
}

// HOLD

// bus
Bus :: struct {
    heat: f32,
    is_overheated: bool,
    cooldown: f32
}

update_bus :: proc() {

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