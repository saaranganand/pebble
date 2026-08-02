package assets

import animation "animation"
import audio "audio"
import img "img"

import log "core:log"

Load_Group_Proc :: struct {
    load: proc(),
    unload: proc(),
}

Load_Group :: enum{ DEBUG_ALL }

@(rodata)
load_group_procs := [Load_Group]Load_Group_Proc{
    .DEBUG_ALL = { load = debug_all_load }
}

debug_all_load :: proc() {
    audio.audio_entry_load("pirate_bell.wav")
    audio.audio_entry_load("burn_tick.wav")

    audio.audio_entry_load("weapon_shoot.wav")
    audio.audio_entry_load("weapon_select.wav")
    audio.audio_entry_load("weapon_charge.wav")
    audio.audio_entry_load("bow_draw.wav")
    audio.audio_entry_load("bow_shoot.wav")

    audio.audio_entry_load("shanty.ogg")
    //music_play("music/shanty.ogg")

    font_load("fonts/ubuntu.ttf", 32)
    font_load("fonts/ubuntu.ttf", 24)
    font_load("fonts/ubuntu.ttf", 16)

    img.img_load("player")
    img.img_load("weapons")
    img.img_load("player_bullet")
    img.img_load("player_arrow")
    img.img_load("enemy_horde")
}

global_init :: proc() {
    img.img_manager_create()
    animation.animation_manager_create()

    audio.audio_manager_create()

    global_manager_create()

    load_group_procs[.DEBUG_ALL].load()
}

global_destroy :: proc() {
    animation.animation_manager_destroy()
    img.img_manager_destroy()

    audio.audio_manager_destroy()

    global_manager_destroy()
}