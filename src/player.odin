// player drawing and handling

package main
import sdl "vendor:sdl3"
import "core:math"

Player :: struct {
    x,y: f32,
    aimAngle: f32,
    weaponManual: WeaponManual,
    weaponHold: WeaponHold,
    weaponAuto: WeaponAuto,
    active_category: WeaponCategory,
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
    // player rectangle
    playerRect:=sdl.FRect{
        x = player.x - PLAYER_SIZE / 2,
        y = player.y - PLAYER_SIZE / 2,
        w = PLAYER_SIZE,
        h = PLAYER_SIZE
    }
    sdl.SetRenderDrawColor(renderer, 255, 0, 0, 255)
    sdl.RenderFillRect(renderer, &playerRect)

    // player aim cube
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

update_player :: proc(player: ^Player, camera: ^Camera, bullets: ^BulletPool, centerX: f32, centerY: f32, input: Input, dt: f32) {
    
    input := input

    switch player.active_category {
        
        case .Manual:
            switch player.weaponManual {
                case .BitPistol:
                    update_bitpistol(&player.bitPistol, bullets, player.x, player.y, input, player.aimAngle, dt)
                case .Scope:
                    update_scope(&player.scope, bullets, player.x, player.y, input, player.aimAngle, dt)
                    // slow player down
                    if player.scope.is_charging {
                        input.dx *= 0.2
                        input.dy *= 0.2
                    }       
            }

        case .Hold:
            switch player.weaponHold {
                case .Bus:
                    update_bus(&player.bus, input, dt)
                case .Trace:
                    update_trace(&player.trace, bullets, player.x, player.y, input, player.aimAngle, dt)
            }

        case .Auto:
            switch player.weaponAuto {
                case .Ping:
                    update_ping()
                case .Daemon:
                    update_daemon()
            }
    }
    
    // always centers player
    update_camera(camera, input.dx, input.dy, dt)

    targetX := centerX + input.dx * NUDGE_RADIUS
    targetY := centerY + input.dy * NUDGE_RADIUS
    player.x += (targetX-player.x) * NUDGE_SPEED
    player.y += (targetY-player.y) * NUDGE_SPEED
    player.aimAngle = math.atan2(input.mouseY - player.y, input.mouseX - player.x)
}