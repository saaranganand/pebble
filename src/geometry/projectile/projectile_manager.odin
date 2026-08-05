package projectile

import sdl "vendor:sdl3"

import entity "src:entity"

@(private)
global_projectile_manager: Projectile_Manager

Projectile_Manager :: struct {
    lists: [entity.Team][Category][dynamic]Projectile_State,
    free_lists: [entity.Team][Category][dynamic]uint,
}

projectile_manager_create :: proc() -> ^Projectile_Manager {
    for team in entity.Team {
        for cat in Category {
            global_projectile_manager.lists[team][cat] = make([dynamic]Projectile_State)
            global_projectile_manager.free_lists[team][cat] = make([dynamic]uint)
        }
    }
    
    return &global_projectile_manager
}

projectile_manager_destroy :: proc() {
    for team in entity.Team {
        for cat in Category {
            delete(global_projectile_manager.lists[team][cat])
            delete(global_projectile_manager.free_lists[team][cat])
        }
    }
}

projectile_manager_spawn :: proc(shell: Projectile_Shell, position: sdl.FPoint, shoot_angle: f32) {
    state := projectile_state_init(shell, position, shoot_angle)

    if len(global_projectile_manager.free_lists[shell.team][shell.category]) > 0 {
        insert := pop(&global_projectile_manager.free_lists[shell.team][shell.category])

        global_projectile_manager.lists[shell.team][shell.category][insert] = state
        return
    }
    append(&global_projectile_manager.lists[shell.team][shell.category], state)
}

projectile_manager_remove :: proc(index: uint, team: entity.Team, category: Category) {
    state := &global_projectile_manager.lists[team][category][index]

    state.active = false
    tracking_line, tracking_line_ok := state.shape.(Tracking_Line)

    append(&global_projectile_manager.free_lists[team][category], index)
}

projectile_manager_update :: proc() {
    for team in entity.Team {
        for cat in Category {
            idx: uint = 0
            for &state in global_projectile_manager.lists[team][cat] {
                defer idx += 1
                projectile_state_update(&state, idx)
            }
        }
    }
}

projectile_manager_draw :: proc() {
    for team in entity.Team {
        for cat in Category {
            for &state in global_projectile_manager.lists[team][cat] {
                projectile_state_draw(&state)
            }
        }
    }
}