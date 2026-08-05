package main

import sdl "vendor:sdl3"

import reaction   "src:entity/effect/reaction"
import projectile "src:geometry/projectile"
import collision  "src:geometry/collision"
import primatives "src:sdl_primatives"
import player     "src:entity/player"
import effect     "src:entity/effect"
import horde      "src:entity/horde"
import weapon     "src:item/weapon"
import color      "src:util/color"
import data_load  "src:data_load"
import camera     "src:camera"
import entity     "src:entity"
import input      "src:input"
import level      "src:level"
import hud        "src:HUD"

import log "core:log"

AIM_SIZE :: 8

TILE_SIZE :: 64

game := struct {
    player: player.Player_Character,

    game_over: bool,
    input: input.Input,

    horde_manager: ^horde.Horde_Manager,
    effect_manager: ^effect.Effect_Manager,
    entity_manager: ^entity.Entity_Manager,
    reaction_manager: ^reaction.Reaction_Manager,
    weapon_manager: ^weapon.Weapon_Manager,
    projectile_manager: ^projectile.Projectile_Manager,
    level_manager: ^level.Level_Manager,

    hud: hud.HUD,
}{}

game_loop :: proc() {
    game_input()
    game_update()
    game_draw()
}

game_create :: proc() {
    primatives.global_timer_init()

    log.infof("\n\n\n\n==================== GAME INITIALIZATION ====================")
    // Effect manager must be created and loaded before other entity processes.
    // This is because the number of total effect definitions is important for the ability to use
    // alloced arrays instead of dynamic ones.
    game.effect_manager = effect.effect_manager_create()

    game.entity_manager = entity.entity_manager_create()
    game.reaction_manager = reaction.reaction_manager_create(game.effect_manager.num_definitions, game.effect_manager.definition_id_map)
    
    game.weapon_manager = weapon.weapon_manager_create()

    game.projectile_manager = projectile.projectile_manager_create()

    game.level_manager = level.level_manager_create()

    program_system_create()

    game.player = player.player_init()

    game.horde_manager = horde.horde_manager_create()
    horde.horde_manager_spawn_horde({0,0}, game.player.entity)

    camera.global_camera_create(f32(app.window_width), f32(app.window_height))
    camera.set_follow(&game.player.tracking_position, 1)//0.05)

    game.hud = hud.create_hud({0,0}, {f32(app.window_width), f32(app.window_height)})

    log.infof("\n\n\n\n==================== ENTERING GAME ====================")
}

game_destroy :: proc() {
    log.infof("\n\n\n\n==================== GAME DE-INITIALIZATION ====================")

    hud.destroy_hud(&game.hud)
    program_system_destroy()

    horde.horde_manager_destroy()

    player.player_destroy(&game.player)

    level.level_manager_destroy()

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

game_update :: proc() {
    player.update_player(&game.player, game.input)

    horde.horde_manager_update()

    entity.entity_manager_update()

    projectile.projectile_manager_update()

    camera.update()

    //horde.update(&game.horde, &game.player.allied_damage_areas)
    collision.resolve_collisions(game.projectile_manager, game.entity_manager, game.effect_manager)

    // Since reactions are explicitly reactions to effects, must update this after effects.
    effect.effect_manager_update()
    reaction.reaction_manager_update(game.effect_manager)

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