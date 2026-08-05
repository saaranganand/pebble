// short-lived floating text that rise and fade out (eg program names)

package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import primatives "src:sdl_primatives"
import font "src:data_load/font"
import camera "src:camera"
import color "src:util/color"

import log "core:log"
import fmt "core:fmt"

FLOATING_TEXT_LIFETIME :: 2.5
FLOATING_TEXT_RISE_SPEED :: 40.0
FLOATING_TEXT_FONT :: "ubuntu"
FLOATING_TEXT_FONT_SIZE :: 24

Floating_Text :: struct {
    text: ^ttf.Text,
    world_position: sdl.FPoint,
    elapsed: f32,
    base_color: sdl.Color,
}

Floating_Text_System :: struct {
    texts: [dynamic]Floating_Text,
}

floating_text_system_create :: proc() -> (system: Floating_Text_System) {
    system.texts = make([dynamic]Floating_Text)
    return
}

floating_text_system_destroy :: proc(system: ^Floating_Text_System) {
    for &floating in system.texts {
        if floating.text != nil do ttf.DestroyText(floating.text)
    }
    delete(system.texts)
}

floating_text_spawn :: proc(
    system: ^Floating_Text_System, label: cstring, world_position: sdl.FPoint,
    text_color: color.Default_Palette_Color = .BLACK
) {
    text := font.font_create_text(FLOATING_TEXT_FONT, FLOATING_TEXT_FONT_SIZE, label)
    if text == nil {
        log.errorf("Failed to create floating text %v (is font %v loaded at size %v?)", label, FLOATING_TEXT_FONT, FLOATING_TEXT_FONT_SIZE)
        return
    }

    append(&system.texts, Floating_Text{
        text = text,
        world_position = world_position,
        elapsed = 0,
        base_color = color.default_color_palette[text_color],
    })

    log.debugf("Spawned floating text %v", label)
}

floating_text_system_update :: proc(system: ^Floating_Text_System) {
    #reverse for &floating, i in system.texts {
        floating.elapsed += primatives.dt
        floating.world_position.y -= FLOATING_TEXT_RISE_SPEED * primatives.dt

        if floating.elapsed >= FLOATING_TEXT_LIFETIME {
            if floating.text != nil do ttf.DestroyText(floating.text)
            unordered_remove(&system.texts, i)
        }
    }
}

floating_text_system_draw :: proc(system: ^Floating_Text_System) {
    for &floating in system.texts {
        // fade alpha linearly
        remaining := 1.0 - (floating.elapsed / FLOATING_TEXT_LIFETIME)
        alpha := u8(clamp(remaining, 0, 1) * 255)
        ttf.SetTextColor(floating.text, floating.base_color.r, floating.base_color.g, floating.base_color.b, alpha)

        view_position := camera.world_position_to_view(floating.world_position)

        // centre label
        w, h: i32
        ttf.GetTextSize(floating.text, &w, &h)
        ttf.DrawRendererText(floating.text, view_position.x - f32(w) / 2, view_position.y - f32(h) / 2)
    }
}

// part of reaction systme
reaction_number_popup :: proc(world_position: sdl.FPoint, value: f32, popup_color: color.Default_Palette_Color) {
    label := fmt.caprint(int(value))
    defer delete(label)
    floating_text_spawn(&game.floating_texts, label, world_position + {0, -30}, popup_color)
}
