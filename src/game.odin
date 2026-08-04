package main

import sdl "vendor:sdl3"

import reaction   "src:entity/entity_effect_reaction"
import effect     "src:entity/entity_effect"
import horde      "src:entity/entity_horde"
import projectile "src:geometry/projectile"
import collision  "src:geometry/collision"
import primatives "src:sdl_primatives"
import player     "src:entity/player"
import weapon     "src:item/weapon"
import color      "src:util/color"
import data_load  "src:data_load"
import camera     "src:camera"
import entity     "src:entity"
import input      "src:input"
import hud        "src:HUD"

import log "core:log"

AIM_SIZE :: 8

TILE_SIZE :: 64

game := struct {
    player: player.Player_Character,
    bullets: BulletPool,
    waves: PingWavePool,

    game_over: bool,
    input: input.Input,

    horde_manager: ^horde.Horde_Manager,
    effect_manager: ^effect.Effect_Manager,
    entity_manager: ^entity.Entity_Manager,
    reaction_manager: ^reaction.Reaction_Manager,
    weapon_manager: ^weapon.Weapon_Manager,
    projectile_manager: ^projectile.Projectile_Manager,
    hud: hud.HUD,
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

    log.infof("\n\n\n\n==================== GAME INITIALIZATION ====================")
    // Effect manager must be created and loaded before other entity processes.
    // This is because the number of total effect definitions is important for the ability to use
    // malloced arrays instead of dynamic ones.
    game.effect_manager = effect.effect_manager_create()

    game.entity_manager = entity.entity_manager_create()
    game.reaction_manager = reaction.reaction_manager_create(game.effect_manager.unique_definition_ids, game.effect_manager.definition_tag_to_id)
    
    game.weapon_manager = weapon.weapon_manager_create()

    game.projectile_manager = projectile.projectile_manager_create()

    program_system_create()

    game.player = player.player_init()

    game.horde_manager = horde.horde_manager_create()
    horde.horde_manager_spawn_horde({0,0}, game.player.entity)
    //horde.horde_manager_spawn_horde({500,0}, game.player.entity)

    //game.horde = horde.create(&game.player.tracking_position)
    //horde.leader_spawn(&game.horde, {200, 200})

    camera.global_camera_create(f32(app.window_width), f32(app.window_height))
    camera.set_follow(&game.player.tracking_position, 1)//0.05)

    game.hud = hud.create_hud({0,0}, {f32(app.window_width), f32(app.window_height)})

    log.infof("\n\n\n\n==================== ENTERING GAME ====================")
}

game_destroy :: proc() {
    log.infof("\n\n\n\n==================== GAME DE-INITIALIZATION ====================")

    hud.destroy_hud(&game.hud)
    program_system_destroy()

    //data.global_manager_destroy()

    horde.horde_manager_destroy()

    //horde.destroy(&game.horde)

    player.player_destroy(&game.player)

    projectile.projectile_manager_destroy()

    camera.global_camera_destroy()

    weapon.weapon_manager_destroy()

    reaction.reaction_manager_destroy()
    entity.entity_manager_destroy()
    effect.effect_manager_destroy()

    data_load.global_destroy()
}

game_input :: proc() {
    game.input = input.process_input(&game.player.weapon_controller)
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
    player.update_player(&game.player, game.input)
    update_bullets()    

    horde.horde_manager_update()

    entity.entity_manager_update()

    projectile.projectile_manager_update()

    camera.update()

    //horde.update(&game.horde, &game.player.allied_damage_areas)
    collision.resolve_collisions(game.projectile_manager, game.entity_manager, game.effect_manager)

    // Since reactions are explicitly reactions to effects, must update this after effects.
    effect.effect_manager_update()
    reaction.reaction_manager_update(game.effect_manager)

    /*
    is_ping_selected := player.active_category == .Auto && player.weaponAuto == .Ping
    is_daemon_selected := player.active_category == .Auto && player.weaponAuto == .Daemon

    if (is_ping_selected && input.fire && !player.ping.is_active) ||
    (is_daemon_selected && input.fire && !player.daemon.is_active) {
        reset_auto_weapons(&player, &waves)
    }
    */

    
    //update_ping(&player.ping, &waves, player.x, player.y, input, is_ping_selected, dt)
    //update_daemon(&player.daemon, &bullets, &enemies, player.x, player.y, is_daemon_selected, input, dt)

    //update_enemies(game.player.x, game.player.y)

    //detect_collision()
    //detect_bullet_collision()

    

    //if game.player.ping.is_active {
        //detect_ping_damage()
    //}
    
    //if game.player.hp <=0 {
      //  game.game_over = true
    //}

    
}

game_draw :: proc() {
    
    color.sdl_set_color(color.Default_Palette_Color.WHITE)
    sdl.RenderClear(primatives.global_renderer)

    // drawing
    camera.draw_grid()

    entity.entity_manager_draw()
    projectile.projectile_manager_draw()

    player.draw_player_accessories(&game.player)

    hud.draw_hud(&game.hud, &game.player, game.input)
}