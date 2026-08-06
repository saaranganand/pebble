package load_group

import animation "src:data_load/animation"
import audio "src:data_load/audio"
import font "src:data_load/font"
import img "src:data_load/img"

debug_all_load :: proc() {
    audio.audio_load("pirate_bell.wav")
    audio.audio_load("burn_tick.wav")

    audio.audio_load("weapon_shoot.wav")
    audio.audio_load("weapon_select.wav")
    audio.audio_load("weapon_charge.wav")
    audio.audio_load("bow_draw.wav")
    audio.audio_load("bow_shoot.wav")

    audio.audio_load("shanty.ogg")
    //music_play("music/shanty.ogg")

    font.font_load("ubuntu", 32)
    font.font_load("ubuntu", 24)
    font.font_load("ubuntu", 16)

    img.img_load("player")
    img.img_load("weapons")
    img.img_load("player_bullet")
    img.img_load("trace")
    img.img_load("enemy_horde")
}

debug_all_unload :: proc() {

}