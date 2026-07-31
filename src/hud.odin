// hud elements like meters, text, hotbars and things

package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import img "vendor:sdl3/image"

import fmt "core:fmt"

import primatives "sdl_primatives"
import color "color"
import entity "entity"
import assets "assets"

HUD :: struct {
    effect_duration_text: ^ttf.Text,
    weapon_name_text: ^ttf.Text,
    weapon_cursors: map[string]^sdl.Cursor,
}

create_hud :: proc() -> (hud: HUD) {
    hud.effect_duration_text = assets.font_create_text("fonts/ubuntu.ttf", 16, "0s")
    color.sdl_set_text_color(hud.effect_duration_text, color.Default_Palette_Color.BLACK)

    hud.weapon_name_text = assets.font_create_text("fonts/ubuntu.ttf", 24, "")
    color.sdl_set_text_color(hud.weapon_name_text, color.Default_Palette_Color.BLACK)


    hud.weapon_cursors = make(map[string]^sdl.Cursor)

    crosshair_surface := img.Load("assets/img/crosshair.png")
    crosshair := sdl.CreateColorCursor(crosshair_surface, 32, 32)
    sdl.DestroySurface(crosshair_surface)
    hud.weapon_cursors["scope"] = crosshair

    return
}

destroy_hud :: proc(hud: ^HUD) {
    ttf.DestroyText(hud.effect_duration_text)
    ttf.DestroyText(hud.weapon_name_text)
    for _, cursor in hud.weapon_cursors {
        sdl.DestroyCursor(cursor)
    }
    delete(hud.weapon_cursors)   
}

draw_hud :: proc() {
    player := game.player
    input := game.input
    hud := game.hud

    player_entity, ok := entity.entity_get(player.entity, .ALLY)
    if !ok do return


    // top left player health bar - scales with max hp
    hp_scale := player_entity.max_health / player_entity.base_max_health
    bar_width := 200 * hp_scale
    
    hp_ratio := player_entity.health / player_entity.max_health
    bgRect := sdl.FRect{x = 10, y = 10, w = bar_width, h = 20}
    fillRect := sdl.FRect{x = 10, y = 10, w = bar_width * hp_ratio, h = 20}

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

    // weapon name
    active_name := fmt.caprint(game.player.weapon_controller.active_weapon)
    defer delete(active_name)
    ttf.SetTextString(game.hud.weapon_name_text, active_name, 0)
    w, h: i32
    ttf.GetTextSize(game.hud.weapon_name_text, &w, &h)
    ttf.DrawRendererText(game.hud.weapon_name_text, 10, f32(app.window_height) - f32(h) - 10)
}

any_auto_expiring :: proc(player: Player) -> bool {
    return (player.ping.is_active && player.ping.timer <= 3.0) || (player.daemon.is_active && player.daemon.timer <= 3.0)
}

update_cursor :: proc() {
    active := game.player.weapon_controller.active_weapon
    if cursor, ok := game.hud.weapon_cursors[active]; ok {
        _ = sdl.SetCursor(cursor)
    } else {
        _ = sdl.SetCursor(sdl.GetDefaultCursor())
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