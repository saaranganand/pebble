package projectile

import sdl "vendor:sdl3"

import entity "src:entity"

import xar "core:container/xar"

@(private)
global_projectile_manager: Projectile_Manager

Projectile_Manager :: struct {
    lists: [entity.Team]xar.Array(Projectile_State, 8),
    remove_queues: [entity.Team][dynamic]uint,
}

projectile_manager_create :: proc() -> ^Projectile_Manager {
    for team in entity.Team {
        xar.array_init(&global_projectile_manager.lists[team])
        global_projectile_manager.remove_queues[team] = make([dynamic]uint)
    }
    
    return &global_projectile_manager
}

projectile_manager_destroy :: proc() {
    for team in entity.Team {
        xar.array_destroy(&global_projectile_manager.lists[team])
        delete(global_projectile_manager.remove_queues[team])
    }
}

// While XAR has a clear function, it retains the allocated chunks.
// Because of how XAR is set up, that might leave us with a crazy amount of allocated space, which we may never reclaim.
// Take an example of a special bossfight that spawns a lot of bullets, something on the magnitude of a few thousand per frame.
// Because of how XAR is set up, the amount of space allocated could even be, at most, double of the number of maximum bullets in 1 frame.
// There may never be another boss the user fights, especially in their current session, that spawns even 1/10th of as many bullets.
// This would mean the user's machine would continue on with space allocated for that many bullets.
// Thus, it makes more sense to use XAR's destroy on clear rather than XAR's "clear".
projectile_manager_clear :: proc() {
    for team in entity.Team {
        xar.array_destroy(&global_projectile_manager.lists[team])
        xar.array_init(&global_projectile_manager.lists[team])

        clear(&global_projectile_manager.remove_queues[team])
    }
}

// Recycle is what we will use as a traditional "clear". This would be used for things like going from room to room
projectile_manager_recycle :: proc() {
    for team in entity.Team {
        xar.array_clear(&global_projectile_manager.lists[team])
        clear(&global_projectile_manager.remove_queues[team])
    }
}

projectile_manager_spawn :: proc(shell: Projectile_Shell, position: sdl.FPoint, shoot_angle: f32) {
    state := projectile_state_init(shell, position, shoot_angle)

    xar.array_push_back_elem(&global_projectile_manager.lists[shell.team], state)
}

projectile_manager_remove :: proc(index: uint, team: entity.Team) {
    append(&global_projectile_manager.remove_queues[team], index)
}

projectile_manager_update :: proc() {
    for team in entity.Team {
        list := &global_projectile_manager.lists[team]

        it := xar.iterator(list)
        for state, idx in xar.iterate_by_ptr(&it) {
            projectile_state_update(state, uint(idx))
        }

        queue := &global_projectile_manager.remove_queues[team]

        #reverse for idx in queue {
            xar.unordered_remove(list, idx)
        }

        clear(queue)
    }
}

projectile_manager_draw :: proc() {
    for team in entity.Team {
        list := &global_projectile_manager.lists[team]

        it := xar.iterator(list)
        for state, idx in xar.iterate_by_ptr(&it) {
            projectile_state_draw(state)
        }
    }
}