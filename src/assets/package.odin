package assets

global_init :: proc() {
    global_manager_create()
    audio_entry_load("sounds/silly/pirate_bell.wav")
    audio_entry_load("sounds/effects/burn_tick.wav")
    audio_entry_load("music/shanty.ogg")
    music_play("music/shanty.ogg")

    font_load("fonts/ubuntu.ttf", 32)
    font_load("fonts/ubuntu.ttf", 24)
    font_load("fonts/ubuntu.ttf", 16)

    img_load("img/player/move.png")

    animation_instance_load("animations/entity/player.yaml")
}

global_destroy :: proc() {
    global_manager_destroy()
}