package entity

import sdl "vendor:sdl3"

import handle "../handle"

import log "core:log"

global_init :: proc() -> (effect_manger: ^Effect_Manager, entity_manager: ^Entity_Manager, reaction_manager: ^Reaction_Manager) {
    // Effect manager must be created and loaded before other entity processes.
    // This is because the number of total effect definitions is important for the ability to use
    // malloced arrays instead of dynamic ones.
    effect_manger = effect_manager_create()
    effect_manager_load()

    entity_manager = entity_manager_create()
    reaction_manager = reaction_manager_create()
    reaction_manager_load()

    return
}

global_destroy :: proc() {
    reaction_manager_destroy()
    entity_manager_destroy()
    effect_manager_destroy()
}

global_update :: proc() {
    effect_manager_update()

    // Since reactions are explicitly reactions to effects, must update this after effects.
    reaction_manager_update()
}