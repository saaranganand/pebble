package assets

import img "img"

import fmt "core:fmt"

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
    audio_entry_load("sounds/silly/pirate_bell.wav")
    audio_entry_load("sounds/effects/burn_tick.wav")

    audio_entry_load("sounds/weapons/bit_pistol/shoot.wav")
    audio_entry_load("sounds/weapons/bit_pistol/select.wav")
    audio_entry_load("sounds/weapons/bit_pistol/charge.wav")
    audio_entry_load("sounds/weapons/bit_pistol/bow_draw.wav")
    audio_entry_load("sounds/weapons/bit_pistol/bow_shoot.wav")

    audio_entry_load("music/shanty.ogg")
    //music_play("music/shanty.ogg")

    font_load("fonts/ubuntu.ttf", 32)
    font_load("fonts/ubuntu.ttf", 24)
    font_load("fonts/ubuntu.ttf", 16)

    img.img_load("player.png")
    img.img_load("weapons.png")
    img.img_load("player_bullet.png")
    img.img_load("player_arrow.png")
    img.img_load("enemy_horde.png")
}

global_init :: proc() {
    global_manager_create()

    load_group_procs[.DEBUG_ALL].load()
}

global_destroy :: proc() {
    global_manager_destroy()
}