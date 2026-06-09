package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

draw_hud :: proc(renderer: ^sdl.Renderer, font: ^ttf.Font, player: Player) {
    weapon_name : cstring
    switch player.active_category {
        case .Manual:
            switch player.weaponManual {
                case .BitPistol: weapon_name = "Bit Pistol"
                case .Scope: weapon_name = "Scope"
            }
        case .Hold:
            switch player.weaponHold {
                case .Bus: weapon_name = "Bus"
                case .Trace: weapon_name = "Trace"
            }
        case .Auto:
            switch player.weaponAuto {
                case .Ping: weapon_name = "Ping"
                case .Daemon: weapon_name = "Daemon"
            }
    }

    surf := ttf.RenderText_Blended(font, weapon_name, 0, sdl.Color{0, 0, 0, 255})
    texture := sdl.CreateTextureFromSurface(renderer, surf)
    sdl.DestroySurface(surf)

    w, h : f32
    sdl.GetTextureSize(texture, &w, &h)

    dst := sdl.FRect{x = 10, y = f32(WINDOW_H) - h - 10, w = w, h = h}
    sdl.RenderTexture(renderer, texture, nil, &dst)
    sdl.DestroyTexture(texture)
}

update_cursor :: proc(player: Player, crosshair: ^sdl.Cursor) {
    if player.active_category == .Manual && player.weaponManual == .Scope {
        _ = sdl.SetCursor(crosshair)
    }
    else {
        _ =sdl.SetCursor(sdl.GetDefaultCursor())
    }
}