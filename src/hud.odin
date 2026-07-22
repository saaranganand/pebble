// hud elements like meters, text, hotbars and things

package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import fmt "core:fmt"

import primatives "sdl_primatives"
import color "color"
import entity "entity"
import assets "assets"

HUD :: struct {
    effect_duration_text: ^ttf.Text,
}

create_hud :: proc() -> (hud: HUD) {
    hud.effect_duration_text = assets.font_create_text("fonts/ubuntu.ttf", 16, "0s")
    color.sdl_set_text_color(hud.effect_duration_text, color.Default_Palette_Color.BLACK)

    return
}

destroy_hud :: proc(hud: ^HUD) {
    ttf.DestroyText(hud.effect_duration_text)
}

draw_hud :: proc() {
    player := game.player
    input := game.input
    hud := game.hud

    player_entity, ok := entity.entity_get(player.entity)
    if !ok do return


    // top left player health bar
    hp_ratio := player_entity.health / player_entity.max_health
    bgRect := sdl.FRect{x = 10, y = 10, w = 200, h = 20}
    fillRect := sdl.FRect{x = 10, y = 10, w = 200 * hp_ratio, h = 20}

    color.sdl_set_color(color.Default_Palette_Color.DARK_GRAY)
    sdl.RenderFillRect(primatives.global_renderer, &bgRect)

    color.sdl_set_color(color.Default_Palette_Color.GRASS_GREEN)
    sdl.RenderFillRect(primatives.global_renderer, &fillRect)

    effect_rect := sdl.FRect{x = 10 + 200 + 10, y = 10, w = 20, h = 20}

    /*
    // top left player effects
    for i in 0..<game.effect_manager.unique_definition_ids {
        effect_maybe := entity.entity_get_active_effect_by_ID(player_entity, i)
        effect_handle, effect_handle_ok := effect_maybe.(entity.Effect_Handle)
        if !effect_handle_ok do continue

        effect, effect_ok := entity.effect_manager_get_effect(effect_handle)
        if !effect_ok do continue

        effect_color := color.Default_Palette_Color.PINK
        switch effect.instance.definition.unique_tag {
        case "burn":
            effect_color := color.Default_Palette_Color.RED
        case "gravity":
            effect_color := color.Default_Palette_Color.DARK_GREEN
        case "knockback":
            continue
        case "slow":
            effect_color := color.Default_Palette_Color.BABY_BLUE
        }

        color.sdl_set_color(effect_color)
        sdl.RenderFillRect(primatives.global_renderer, &effect_rect)

        duration_text := fmt.caprint(int(effect.duration - effect.elapsed), "s", sep = "")
        defer delete(duration_text)

        ttf.SetTextString(hud.effect_duration_text, duration_text, 0)
        ttf.DrawRendererText(hud.effect_duration_text, effect_rect.x + 20 + 2, effect_rect.y + 2)

        effect_rect.x += 40 + 5
    }*/
    
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
                      bgRect := sdl.FRect{
                          x = player_entity.position.x - 30,
                          y = player_entity.position.y + game_config.player.size / 2 + 10,
                          w = 60,
                          h = 6
                      }
                      fill_ratio := min(player.scope.charge / game_config.weapons.scope.max_charge, 1.0)
                      fillRect := sdl.FRect{
                          x = bgRect.x,
                          y = bgRect.y,
                          w = 60*(fill_ratio),
                          h= 6
                      }
                      sdl.SetRenderDrawColor(primatives.global_renderer, 50,50,50,255)
                      sdl.RenderFillRect(primatives.global_renderer, &bgRect)
                      sdl.SetRenderDrawColor(primatives.global_renderer, 255,200,0,255)
                      sdl.RenderFillRect(primatives.global_renderer, &fillRect)
                  }
            }
        case .Hold:
            switch player.weaponHold {
              case .Bus: 
                  weapon_name = "Bus"
                  // bus overheat meter - attached to cursor
                  bgRect :=sdl.FRect{
                      x = input.mouseX - 25,
                      y = input.mouseY + 40,
                      w = 60,
                      h = 6
                  }
                  fill_ratio := min(player.bus.heat / game_config.weapons.bus.max_heat, 1.0)
                  fillRect := sdl.FRect{
                      x = bgRect.x,
                      y = bgRect.y,
                      w = 60*(fill_ratio),
                      h= 6
                  }
                  sdl.SetRenderDrawColor(primatives.global_renderer, 50,50,50,255)
                  sdl.RenderFillRect(primatives.global_renderer, &bgRect)

                  r, g : u8
                  if fill_ratio < 0.5 {
                      r = u8(fill_ratio * 2 * 255)
                      g = 255
                  } else {
                      r = 255
                      g = u8((1 - fill_ratio) * 2 * 255)
                  }
                  sdl.SetRenderDrawColor(primatives.global_renderer, r, g, 0, 255)
                  sdl.RenderFillRect(primatives.global_renderer, &fillRect)

              case .Trace:
                weapon_name = "Trace"
            }
            fill_ratio := min(player.bus.heat / game_config.weapons.bus.max_heat, 1.0)
            fillRect :=sdl.FRect{
                x = bgRect.x,
                y = bgRect.y,
                w = 60*(fill_ratio),
                h= 6
            }
            sdl.SetRenderDrawColor(primatives.global_renderer, 50,50,50,255)
            sdl.RenderFillRect(primatives.global_renderer, &bgRect)

            r, g : u8
            if fill_ratio < 0.5 {
                r = u8(fill_ratio * 2 * 255)
                g = 255
            } else {
                r = 255
                g = u8((1 - fill_ratio) * 2 * 255)
            }
            sdl.SetRenderDrawColor(primatives.global_renderer, r, g, 0, 255)
            sdl.RenderFillRect(primatives.global_renderer, &fillRect)
            
        //case .Trace:
            //weapon_name = "Trace"
        case .Auto:
            switch player.weaponAuto {
            case .Ping: 
                weapon_name = "Ping"
            case .Daemon: 
                weapon_name = "Daemon"
            }
        }

    if any_auto_expiring(player) {
        //draw_expiry_exclamation(app.font)
    }

    // weapon name on bottom left
    /*surf := ttf.RenderText_Blended(app.font, weapon_name, 0, sdl.Color{0, 0, 0, 255})
    texture := sdl.CreateTextureFromSurface(primatives.global_renderer, surf)
    sdl.DestroySurface(surf)

    w, h : f32
    sdl.GetTextureSize(texture, &w, &h)

    dst := sdl.FRect{x = 10, y = f32(app.window_height) - h - 10, w = w, h = h}
    sdl.RenderTexture(primatives.global_renderer, texture, nil, &dst)
    sdl.DestroyTexture(texture)*/
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