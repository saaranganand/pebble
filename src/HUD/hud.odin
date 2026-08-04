package HUD

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import font "src:data_load/font"
import color "src:util/color"
import entity "src:entity"
import player "src:entity/player"
import input "src:input"
import weapon "src:item/weapon"

import log "core:log"

HUD :: struct {
    top_left, bottom_right: sdl.FPoint,
    effect_duration_text: ^ttf.Text,
}

create_hud :: proc(top_left, bottom_right: sdl.FPoint) -> (hud: HUD) {
    hud.effect_duration_text = font.font_create_text("ubuntu", 16, "0s")
    color.sdl_set_text_color(hud.effect_duration_text, color.Default_Palette_Color.BLACK)

    hud.top_left = top_left
    hud.bottom_right = bottom_right

    return
}

destroy_hud :: proc(hud: ^HUD) {
    ttf.DestroyText(hud.effect_duration_text)
}

draw_hud :: proc(hud: ^HUD, player_character: ^player.Player_Character, player_input: input.Input) {
    
    player_entity, ok := entity.entity_get(player_character.entity, .ALLY)
    if !ok do return


    // top left player health bar
    draw_hud_health_bar(player_entity.hp, player_entity.max_hp)
    
    draw_hud_weapon_select(hud, player_character.weapon_controller)
}