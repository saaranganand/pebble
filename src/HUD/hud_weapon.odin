package HUD

import sdl "vendor:sdl3"

import animation "../data_load/animation"
import primatives "src:sdl_primatives"
import color "src:util/color"
import weapon "src:item/weapon"

import math "core:math"

draw_hud_weapon_select :: proc(hud: ^HUD, weapon_controller: weapon.Weapon_Controller) {
    WEAPON_BOX_SIZE: f32 : 50
    WEAPON_BOX_MARGIN_SIZE: f32 : 20
    WEAPON_BOX_AREA_MARGINS: f32 : 10
    num_weapons := cast(f32) len(weapon_controller.weapons)

    total_boxes_width := num_weapons * WEAPON_BOX_SIZE + (num_weapons - 1) * WEAPON_BOX_MARGIN_SIZE + WEAPON_BOX_AREA_MARGINS * 2
    total_hud_width := hud.bottom_right.x - hud.top_left.x
    boxes_start_x := (total_hud_width - total_boxes_width) / 2.0
    boxes_Start_y := hud.bottom_right.y - (WEAPON_BOX_SIZE + WEAPON_BOX_AREA_MARGINS * 2)

    total_boxes_rect := sdl.FRect{
        boxes_start_x,
        boxes_Start_y,
        total_boxes_width,
        WEAPON_BOX_SIZE + WEAPON_BOX_AREA_MARGINS * 2
    }

    // STEP 1: draw weapon box outline
    color.sdl_set_color(color.Default_Palette_Color.LIGHT_GRAY)
    sdl.RenderFillRect(primatives.global_renderer, &total_boxes_rect)

    // STEP 2: for player selected weapon I, highlight box I=N
    HIGHLIGHT_BOX_MARGIN :: 2

    selected_box_rect := sdl.FRect{
        boxes_start_x + WEAPON_BOX_AREA_MARGINS + f32(weapon_controller.active_weapon) * (WEAPON_BOX_SIZE + WEAPON_BOX_MARGIN_SIZE),
        boxes_Start_y + WEAPON_BOX_AREA_MARGINS,
        WEAPON_BOX_SIZE,
        WEAPON_BOX_SIZE
    }

    highlight_box_rect := selected_box_rect
    highlight_box_rect.x -= HIGHLIGHT_BOX_MARGIN
    highlight_box_rect.y -= HIGHLIGHT_BOX_MARGIN
    highlight_box_rect.w += HIGHLIGHT_BOX_MARGIN * 2
    highlight_box_rect.h += HIGHLIGHT_BOX_MARGIN * 2
    
    color.sdl_set_color(color.Default_Palette_Color.RED)
    sdl.RenderFillRect(primatives.global_renderer, &highlight_box_rect)

    // STEP 3: for player's N weapons, draw N empty rectangles evenly spaced, centered at bottom of screen
    box_rect := sdl.FRect{
        boxes_start_x + WEAPON_BOX_AREA_MARGINS,
        boxes_Start_y + WEAPON_BOX_AREA_MARGINS,
        WEAPON_BOX_SIZE,
        WEAPON_BOX_SIZE
    }


    iterate_box_rect := box_rect
    color.sdl_set_color(color.Default_Palette_Color.WHITE)
    for weapon_num in 0..<num_weapons {
        sdl.RenderFillRect(primatives.global_renderer, &iterate_box_rect)

        iterate_box_rect.x += WEAPON_BOX_SIZE + WEAPON_BOX_MARGIN_SIZE
    }

    // STEP 4: for Nth weapon K, draw Ks sprite in the Nth box
    sprite_box_rect := box_rect
    for weapon in weapon_controller.weapons {
        animation_controller := weapon.animation_controller
        animation_controller.current_animation = "hud_display"

        draw_weapon_pos := sdl.FPoint{sprite_box_rect.x, sprite_box_rect.y} + sdl.FPoint{sprite_box_rect.w, sprite_box_rect.h} / 2
        animation.animation_draw(&animation_controller, draw_weapon_pos)

        sprite_box_rect.x += WEAPON_BOX_SIZE + WEAPON_BOX_MARGIN_SIZE
    }

    // STEP 5: For each weapon, draw a cooldown timer if active
    i := 0
    cooldown_box_rect := box_rect
    for weapon in weapon_controller.weapons {
        defer i += 1
        draw_cooldown_overlay(
            cooldown_box_rect, weapon.cooldown_counter,
            weapon.definition.cooldown,
            color.Default_Palette_Color.BLUE
        )

        cooldown_box_rect.x += WEAPON_BOX_SIZE + WEAPON_BOX_MARGIN_SIZE
    }
    
    // STEP 6: while weapon I's gcd is active, draw a transulcent gray rectangle over it, the rectangle being segmented radially, like the arc of a circle
    draw_cooldown_overlay(
        selected_box_rect, weapon_controller.gcd_counter,
        weapon_controller.weapons[weapon_controller.active_weapon].definition.gcd_interval,
        color.Default_Palette_Color.BLACK
    )

    // STEP 7: draw charge counter graphics
    charge_box_rect := box_rect
    for weapon in weapon_controller.weapons {
        defer charge_box_rect.x += WEAPON_BOX_SIZE + WEAPON_BOX_MARGIN_SIZE

        if weapon.definition.max_charge_time == 0 do continue

        draw_cooldown_overlay(
            charge_box_rect, weapon.time_since_charge_start,
            weapon.definition.max_charge_time,
            color.Default_Palette_Color.YELLOW
        )

        
    }
}

// Draws a translucent gray radial-wipe cover over `box`, exact to its edges.
// current == max  -> box fully covered (cooldown just started)
// current == 0    -> nothing drawn (weapon ready)
draw_cooldown_overlay :: proc(box: sdl.FRect, current, max: f32, pcolor: color.Default_Palette_Color) {
    if current <= 0 || max <= 0 do return

    frac := min(current / max, 1.0)

    cx := box.x + box.w * 0.5
    cy := box.y + box.h * 0.5

    // radius large enough that the fan always reaches past every corner
    half_w := box.w * 0.5
    half_h := box.h * 0.5
    radius := math.sqrt(half_w * half_w + half_h * half_h) + 1

    start_angle: f32 = -math.PI * 0.5      // 12 o'clock; flip sign / add PI to change start point
    sweep := frac * math.TAU               // shrinks toward 0 as cooldown depletes

    // resolution: one segment per ~10 degrees of sweep, always at least 1
    segment_count := int(math.ceil(sweep / (math.PI / 18)))
    if segment_count < 1 do segment_count = 1

    vertices := make([dynamic]sdl.Vertex, 0, segment_count + 2)
    defer delete(vertices)

    set_color := color.sdl_fcolor_from_color_palette(pcolor)
    set_color.a = 0.5

    append(&vertices, sdl.Vertex{
        position  = { cx, cy },
        color     = set_color,
        tex_coord = { 0, 0 },
    })

    for i in 0..=segment_count {
        t := f32(i) / f32(segment_count)
        angle := start_angle + sweep * t
        append(&vertices, sdl.Vertex{
            position  = { cx + radius * math.cos(angle), cy + radius * math.sin(angle) },
            color     = set_color,
            tex_coord = { 0, 0 },
        })
    }

    indices := make([dynamic]i32, 0, segment_count * 3)
    defer delete(indices)
    for i in 1..=segment_count {
        append(&indices, 0, i32(i), i32(i + 1))
    }

    clip_rect := sdl.Rect{ i32(box.x), i32(box.y), i32(box.w), i32(box.h) }
    sdl.SetRenderClipRect(primatives.global_renderer, &clip_rect)
    sdl.SetRenderDrawBlendMode(primatives.global_renderer, sdl.BLENDMODE_BLEND)

    sdl.RenderGeometry(
        primatives.global_renderer,
        nil,
        raw_data(vertices), i32(len(vertices)),
        raw_data(indices), i32(len(indices)),
    )

    sdl.SetRenderClipRect(primatives.global_renderer, nil) // clear clip for subsequent draws
}