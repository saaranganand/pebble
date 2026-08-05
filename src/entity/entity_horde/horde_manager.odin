package horde

import sdl "vendor:sdl3"

import handle "src:handle"

@(private)
global_horde_manager: Horde_Manager

Horde_Manager :: struct {
    hordes: [dynamic]Horde,
    followers_per_leader: int,

    grid: Spatial_Grid,
    grid_followers: map[handle.Entity_Handle][]handle.Entity_Handle,
}

DEFAULT_FOLLOWERS_PER_LEADER :: 100

horde_manager_create :: proc() -> ^Horde_Manager {
    global_horde_manager.hordes = make([dynamic]Horde)
    global_horde_manager.followers_per_leader = DEFAULT_FOLLOWERS_PER_LEADER
    global_horde_manager.grid_followers = make(map[handle.Entity_Handle][]handle.Entity_Handle)
    spatial_grid_create(&global_horde_manager.grid)

    return &global_horde_manager
}

horde_manager_destroy :: proc() {
    for &horde in global_horde_manager.hordes {
        horde_destroy(&horde)
    }
    delete(global_horde_manager.hordes)
    spatial_grid_destroy(&global_horde_manager.grid)

    for key, horde_grid_followers in global_horde_manager.grid_followers {
        delete(horde_grid_followers)
    }
    delete(global_horde_manager.grid_followers)
}

horde_manager_spawn_horde :: proc(horde_position: sdl.FPoint, target: handle.Entity_Handle) {
    new_horde: Horde
    horde_create(&new_horde, target, global_horde_manager.followers_per_leader)
    horde_populate(&new_horde, horde_position)
    append(&global_horde_manager.hordes, new_horde)
}

horde_manager_update :: proc() {
    spatial_grid_build(&global_horde_manager.grid)

    for &horde in global_horde_manager.hordes {
        horde_update(&horde)
    }

    horde_boid_update()
}