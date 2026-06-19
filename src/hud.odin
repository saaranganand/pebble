// hud elements like meters, text, hotbars and things

package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

draw_hud :: proc(renderer: ^sdl.Renderer, font: ^ttf.Font, player: Player, input: Input) {
    weapon_name : cstring
    switch player.active_category {
        case .Manual:
            switch player.weaponManual {
                case .BitPistol: 
                    weapon_name = "Bit Pistol"
                case .Scope: 
                    weapon_name = "Scope"
                    // scope charge meter - attached to player
                    if player.scope.is_charging {
                        bgRect :=sdl.FRect{
                            x =  player.x - 30,
                            y = player.y + PLAYER_SIZE/2 + 10,
                            w = 60,
                            h = 6
                        }
                        fill_ratio := min(player.scope.charge / SCOPE_MAX_CHARGE, 1.0)
                        fillRect :=sdl.FRect{
                            x = bgRect.x,
                            y = bgRect.y,
                            w = 60*(fill_ratio),
                            h= 6
                        }
                        sdl.SetRenderDrawColor(renderer, 50,50,50,255)
                        sdl.RenderFillRect(renderer, &bgRect)
                        sdl.SetRenderDrawColor(renderer, 255,200,0,255)
                        sdl.RenderFillRect(renderer, &fillRect)
                    }
            }
        case .Hold:
            switch player.weaponHold {
                case .Bus: 
                    weapon_name = "Bus"
                    // bus overheat meter - attached to cursor
                    bgRect :=sdl.FRect{
                        x =  input.mouseX - 25,
                        y = input.mouseY + 40,
                        w = 60,
                        h = 6
                    }
                    fill_ratio := min(player.bus.heat / BUS_MAX_HEAT, 1.0)
                    fillRect :=sdl.FRect{
                        x = bgRect.x,
                        y = bgRect.y,
                        w = 60*(fill_ratio),
                        h= 6
                    }
                    sdl.SetRenderDrawColor(renderer, 50,50,50,255)
                    sdl.RenderFillRect(renderer, &bgRect)

                    r, g : u8
                    if fill_ratio < 0.5 {
                        r = u8(fill_ratio * 2 * 255)
                        g = 255
                    } else {
                        r = 255
                        g = u8((1 - fill_ratio) * 2 * 255)
                    }
                    sdl.SetRenderDrawColor(renderer, r, g, 0, 255)
                    sdl.RenderFillRect(renderer, &fillRect)
                    
                case .Trace: weapon_name = "Trace"
            }
        case .Auto:
            switch player.weaponAuto {
                case .Ping: 
                    weapon_name = "Ping"
                case .Daemon: 
                    weapon_name = "Daemon"
            }
    }
    if any_auto_expiring(player) {
        draw_expiry_exclamation(renderer, font)
    }

    // weapon name on bottom left
    surf := ttf.RenderText_Blended(font, weapon_name, 0, sdl.Color{0, 0, 0, 255})
    texture := sdl.CreateTextureFromSurface(renderer, surf)
    sdl.DestroySurface(surf)

    w, h : f32
    sdl.GetTextureSize(texture, &w, &h)

    dst := sdl.FRect{x = 10, y = f32(WINDOW_H) - h - 10, w = w, h = h}
    sdl.RenderTexture(renderer, texture, nil, &dst)
    sdl.DestroyTexture(texture)
}

any_auto_expiring :: proc(player: Player) -> bool {
    return (player.ping.is_active && player.ping.timer <= 3.0) || (player.daemon.is_active && player.daemon.timer <= 3.0)
}

update_cursor :: proc(player: Player, crosshair: ^sdl.Cursor) {
    if player.active_category == .Manual && player.weaponManual == .Scope {
        _ = sdl.SetCursor(crosshair)
    }
    else {
        _ =sdl.SetCursor(sdl.GetDefaultCursor())
    }
}

draw_expiry_exclamation :: proc(renderer: ^sdl.Renderer, font: ^ttf.Font) {
    // display exclamation when ping about to end
    surf := ttf.RenderText_Blended(font, "!", 0, sdl.Color{0, 0, 0, 255})
    texture := sdl.CreateTextureFromSurface(renderer, surf)
    sdl.DestroySurface(surf)

    w, h: f32
    sdl.GetTextureSize(texture, &w, &h)
    dst := sdl.FRect{
        x = WINDOW_W/2 - w/2,
        y = WINDOW_H/2,
        w = w,
        h = h
    }
    sdl.RenderTexture(renderer, texture, nil, &dst)
    sdl.DestroyTexture(texture)
}