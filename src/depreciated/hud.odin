// hud elements like meters, text, hotbars and things

package depreciated

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import primatives "sdl_primatives"
import color "color"
import entity "entity"
import data_load "assets"



/*

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

draw_expiry_exclamation :: proc(font: ^ttf.Font) {
    // display exclamation when ping about to end
    surf := ttf.RenderText_Blended(font, "!", 0, sdl.Color{0, 0, 0, 255})
    texture := sdl.CreateTextureFromSurface(primatives.global_renderer, surf)
    sdl.DestroySurface(surf)

    w, h: f32
    sdl.GetTextureSize(texture, &w, &h)
    dst := sdl.FRect{
        x = f32(app.window_width) / 2 - w / 2,
        y = f32(app.window_height) / 2,
        w = w,
        h = h
    }
    sdl.RenderTexture(primatives.global_renderer, texture, nil, &dst)
    sdl.DestroyTexture(texture)
}
    */