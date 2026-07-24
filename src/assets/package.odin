package assets

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
// tag IB tag surendra
debug_all_load :: proc() {
    audio_entry_load("sounds/silly/pirate_bell.wav")
    audio_entry_load("sounds/effects/burn_tick.wav")

    audio_entry_load("sounds/weapons/bit_pistol/shoot.wav")
    audio_entry_load("sounds/weapons/bit_pistol/select.wav")

    audio_entry_load("music/shanty.ogg")
    //music_play("music/shanty.ogg")

    font_load("fonts/ubuntu.ttf", 32)
    font_load("fonts/ubuntu.ttf", 24)
    font_load("fonts/ubuntu.ttf", 16)

    img_load("img/player/move.png")
    img_load("img/weapon/ranged.png")
    img_load("img/projectile/bullet.png")
    img_load("img/entity/horde.png")
    img_load("img/program.png")

    animation_instance_load("animations/entity/player.yaml")
    animation_instance_load("animations/weapon/bit_pistol.yaml")
    animation_instance_load("animations/weapon/bit_rifle.yaml")
    animation_instance_load("animations/projectile/bullet.yaml")
    animation_instance_load("animations/entity/horde_leader.yaml")
    animation_instance_load("animations/entity/horde_follower.yaml")
}

global_init :: proc() {
    global_manager_create()

    load_group_procs[.DEBUG_ALL].load()
}

global_destroy :: proc() {
    global_manager_destroy()
}