package data_load

import load_group "load_group"
import animation "src:data_load/animation"
import audio "audio"
import font "font"
import img "img"

import log "core:log"

global_init :: proc() {
    log.infof("\n\n\n\n==================== ASSETS INITIALIZATION ====================")

    img.img_manager_create()
    animation.animation_manager_create()

    audio.audio_manager_create()

    font.font_manager_create()

    load_group.load_group_procs[.DEBUG_ALL].load()
}

global_destroy :: proc() {
    log.infof("\n\n\n\n==================== ASSETS DE-INITIALIZATION ====================")

    font.font_manager_destroy()

    audio.audio_manager_destroy()

    animation.animation_manager_destroy()
    img.img_manager_destroy()
}