package horde

import sdl "vendor:sdl3"

import handle "../handle"

@(private)
global_horde_manager: Horde_Manager

Horde_Manager :: struct {
    hordes: [dynamic]Horde,
    followers_per_leader: int,
}

DEFAULT_FOLLOWERS_PER_LEADER :: 50

horde_manager_create :: proc() -> ^Horde_Manager {
    global_horde_manager.hordes = make([dynamic]Horde)
    global_horde_manager.followers_per_leader = DEFAULT_FOLLOWERS_PER_LEADER

    return &global_horde_manager
}

horde_manager_destroy :: proc() {
    for &horde in global_horde_manager.hordes {
        horde_destroy(&horde)
    }
    delete(global_horde_manager.hordes)
}

horde_manager_spawn_horde :: proc(horde_position: sdl.FPoint, target: handle.Entity_Handle) {
    new_horde: Horde
    horde_create(&new_horde, target, global_horde_manager.followers_per_leader)
    horde_populate(&new_horde, horde_position)
    append(&global_horde_manager.hordes, new_horde)
}

horde_manager_update :: proc() {
    for &horde in global_horde_manager.hordes {
        horde_update(&horde)
    }
}

horde_manager_draw :: proc() {
    for horde in global_horde_manager.hordes {
        horde_draw(horde)
    }
}