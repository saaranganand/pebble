package main
import sdl "vendor:sdl3"
import "core:math"

Player :: struct {
    x,y: f32,
    aimAngle: f32,
    weaponManual: WeaponManual,
    weaponHold: WeaponHold,
    weaponAuto: WeaponAuto,
    bitPistol: BitPistol,
    scope: Scope,
    bus: Bus,
    trace: Trace,
    ping: Ping,
    daemon: Daemon
}

player_init :: proc() -> Player {
    return Player{x = WINDOW_W/2, y = WINDOW_H/2}
}

draw_player :: proc(renderer: ^sdl.Renderer, player: Player) {
    // rectangel
    playerRect:=sdl.FRect{
        x = player.x - PLAYER_SIZE / 2,
        y = player.y - PLAYER_SIZE / 2,
        w = PLAYER_SIZE,
        h = PLAYER_SIZE
    }
    sdl.SetRenderDrawColor(renderer, 255, 0, 0, 255)
    sdl.RenderFillRect(renderer, &playerRect)

    aimX := player.x + math.cos(player.aimAngle) * AIM_DIST
    aimY := player.y + math.sin(player.aimAngle) * AIM_DIST
    aimRect:=sdl.FRect{
        x = aimX - AIM_SIZE / 2,
        y = aimY - AIM_SIZE / 2,
        w = AIM_SIZE,
        h = AIM_SIZE
    }
    sdl.SetRenderDrawColor(renderer, 100, 255, 100, 255)
    sdl.RenderFillRect(renderer, &aimRect)
}

update_player :: proc(player: ^Player, bullets: ^BulletPool, centerX: f32, centerY: f32, input: Input, dt: f32) {
    targetX := centerX + input.dx * NUDGE_RADIUS
    targetY := centerY + input.dy * NUDGE_RADIUS
    player.x += (targetX-player.x) * NUDGE_SPEED
    player.y += (targetY-player.y) * NUDGE_SPEED
    player.aimAngle = math.atan2(input.mouseY - player.y, input.mouseX - player.x)

    switch player.weaponManual {
        case .BitPistol:
            update_bitpistol(&player.bitPistol, bullets, player.x, player.y, input, player.aimAngle, dt)
        case .Scope:
            update_scope()
    }
    switch player.weaponHold {
        case .Bus:
            update_bus()
        case .Trace:
            update_trace()
    }
    switch player.weaponAuto {
        case .Ping:
            update_ping()
        case .Daemon:
            update_daemon()
    }
}