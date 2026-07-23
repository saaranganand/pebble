package projectile

import sdl "vendor:sdl3"

import entity "../entity"

@(private)
global_projectile_manager: Projectile_Manager

Projectile_Manager :: struct {
    lists: [entity.Team][Category][dynamic]Projectile_State,
    free_lists: [entity.Team][Category][dynamic]u32,
}

projectile_manager_create :: proc() -> ^Projectile_Manager {
    for team in entity.Team {
        for cat in Category {
            global_projectile_manager.lists[team][cat] = make([dynamic]Projectile_State)
            global_projectile_manager.free_lists[team][cat] = make([dynamic]u32)
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

projectile_manager_spawn :: proc(shell: Projectile_State, position: sdl.FPoint, shoot_angle: f32, damage: f32) {
    shell := shell
    projectile_state_init(&shell, position, shoot_angle, damage)

    if len(global_projectile_manager.free_lists[shell.team][shell.category]) > 0 {
        insert := pop(&global_projectile_manager.free_lists[shell.team][shell.category])

        global_projectile_manager.lists[shell.team][shell.category][insert] = shell
        return
    }
    append(&global_projectile_manager.lists[shell.team][shell.category], shell)
}

projectile_manager_remove :: proc(index: u32, team: entity.Team, category: Category) {
    state := &global_projectile_manager.lists[team][category][index]

    state.active = false

    append(&global_projectile_manager.free_lists[team][category], index)
}

projectile_manager_update :: proc() {
    for team in entity.Team {
        for cat in Category {
            idx: u32 = 0
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