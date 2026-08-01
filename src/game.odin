package main

import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

import primatives "sdl_primatives"
import entity "entity"
import effect "entity_effect"
import reaction "entity_effect_reaction"
import projectile "projectile"
import color "color"
import horde "entity_horde"
import program "program"
import collision "collision"
import script "script"

import camera "camera"
import assets "assets" 
import weapon "weapon"
import input "input"

AIM_DIST :: 50
AIM_SIZE :: 8

TILE_SIZE :: 64

game := struct {
    player: Player,
    bullets: BulletPool,
    waves: PingWavePool,
    //enemies: EnemyPool,
    game_over: bool,
    input: input.Input,
    //horde: horde.Horde,
    horde_manager: ^horde.Horde_Manager,
    effect_manager: ^effect.Effect_Manager,
    entity_manager: ^entity.Entity_Manager,
    reaction_manager: ^reaction.Reaction_Manager,
    weapon_manager: ^weapon.Weapon_Manager,
    program_manager: ^program.Program_Manager,
    projectile_manager: ^projectile.Projectile_Manager,
    program_pickups: Program_Pickup_System,
    floating_texts: Floating_Text_System,
    hud: HUD,
}{}

game_loop :: proc() {
    // deltatime
    primatives.global_timer_update()

    game_input()
    game_update()
    game_draw()
}

game_create :: proc() {
    primatives.global_timer_init()

    assets.global_init()

    // lua scrupts
    script.script_create()
    script.script_load()

    // Effect manager must be created and loaded before other entity processes.
    // This is because the number of total effect definitions is important for the ability to use
    // malloced arrays instead of dynamic ones.
    game.effect_manager = effect.effect_manager_create()
    effect.effect_manager_load()

    game.entity_manager = entity.entity_manager_create()
    game.reaction_manager = reaction.reaction_manager_create(game.effect_manager.unique_definition_ids)
    reaction.reaction_manager_load(game.effect_manager.definition_tag_to_id)
    reaction.number_popup_callback = reaction_number_popup

    game.weapon_manager = weapon.weapon_manager_create()
    weapon.weapon_manager_load()

    // programs resolve weapon and effect tags to IDs at load, so this is after both of those
    game.program_manager = program.program_manager_create()
    program.program_manager_load()

    game.projectile_manager = projectile.projectile_manager_create()

    game.player = player_init()

    program.program_loadout_create(&game.player.program_loadout, game.player.entity, .ALLY, &game.player.weapon_controller)

    // program.program_loadout_equip(&game.player.program_loadout, "amplify")

    game.floating_texts = floating_text_system_create()
    game.program_pickups = program_pickup_system_create()

    game.horde_manager = horde.horde_manager_create()

    horde.horde_manager_spawn_horde({600,400}, game.player.entity)
    //horde.horde_manager_spawn_horde({500,0}, game.player.entity)

    //game.horde = horde.create(&game.player.tracking_position)
    //horde.leader_spawn(&game.horde, {200, 200})

    camera.global_camera_create(f32(app.window_width), f32(app.window_height))
    camera.camera_set_follow(&game.player.tracking_position, 1)//0.05)

    game.hud = create_hud()
}

game_destroy :: proc() {
    destroy_hud(&game.hud)

    program_pickup_system_destroy(&game.program_pickups)
    floating_text_system_destroy(&game.floating_texts)

    horde.horde_manager_destroy()

    //horde.destroy(&game.horde)

    player_destroy(&game.player)

    projectile.projectile_manager_destroy()

    camera.global_camera_destroy()

    program.program_manager_destroy()
    weapon.weapon_manager_destroy()

    reaction.reaction_manager_destroy()
    entity.entity_manager_destroy()
    effect.effect_manager_destroy()

    script.script_destroy()

    assets.global_destroy()
}

game_input :: proc() {
    game.input = input.process_input()
}
/*case sdl.K_1:
                        player.active_category = WeaponCategory.Manual
                    case sdl.K_2:
                        player.active_category = WeaponCategory.Hold
                    case sdl.K_3:
                        player.active_category = WeaponCategory.Auto
                }
            case .MOUSE_WHEEL:
                switch player.active_category {
                    case .Manual:
                        player.weaponManual = WeaponManual((int(player.weaponManual)+1) % len(WeaponManual)) //autowrap
                    case .Hold:
                        player.weaponHold = WeaponHold((int(player.weaponHold)+1) % len(WeaponHold))
                    case .Auto:
                        player.weaponAuto = WeaponAuto((int(player.weaponAuto)+1) % len(WeaponAuto))
                }*/

game_update :: proc() {
    apply_movement_penalty()

    update_player()
    update_bullets()

    program_pickup_system_update(&game.program_pickups)
    floating_text_system_update(&game.floating_texts)

    horde.horde_manager_update()

    entity.entity_manager_update()

    update_waves()

    projectile.projectile_manager_update()

    camera.camera_update()

    //horde.update(&game.horde, &game.player.allied_damage_areas)
    collision.resolve_collisions(game.projectile_manager, game.entity_manager, game.effect_manager)

    // Since reactions are explicitly reactions to effects, must update this after effects.
    effect.effect_manager_update()
    reaction.reaction_manager_update(game.effect_manager)
}

draw_background :: proc() {
    space_width := f32(app.window_width)
    space_height := f32(app.window_height)

    /*
    // bg texture
    color.sdl_set_color(color.Default_Palette_Color.BLACK)

    x := -math.mod(cam.x, f32(TILE_SIZE))
    for x < space_width {
        sdl.RenderLine(primatives.global_renderer, x, 0, x, space_height)
        x += TILE_SIZE
    }

    y := -math.mod(cam.y, f32(TILE_SIZE))
    for y < space_height {
        sdl.RenderLine(primatives.global_renderer, 0, y, space_width, y)
        y += TILE_SIZE
    }*/
}

game_draw :: proc() {
    color.sdl_set_color(color.Default_Palette_Color.WHITE)
    sdl.RenderClear(primatives.global_renderer)

    // drawing
    camera.camera_draw_grid()
    draw_background()

    //horde.horde_manager_draw()

    entity.entity_manager_draw()

    program_pickup_system_draw(&game.program_pickups)

    draw_player()

    projectile.projectile_manager_draw()

    //horde.draw(&game.horde)

    floating_text_system_draw(&game.floating_texts)

    draw_hud()
    draw_bullets()
    draw_ping_waves()

    camera.camera_draw_center_lines()
}