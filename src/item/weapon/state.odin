package weapon

import sdl "vendor:sdl3"
import primatives "src:sdl_primatives"

import animation "src:data_load/animation"
import effect "src:entity/effect"
import projectile "src:geometry/projectile"
import camera "src:camera"
import entity "src:entity"
import util "src:util"
import color "src:util/color"
import geo "src:geometry"

import rand "core:math/rand"
import math "core:math"
import hm "core:container/handle_map"
import log "core:log"

Weapon_State :: struct {
    definition: ^Weapon_Definition,

    cooldown_counter: f32,
    uses_since_cooldown: uint,

    owner_team: entity.Team,

    charging: bool,
    time_since_charge_start: f32,

    // beam weapons only
    heat: f32,
    overheated: bool,
    beam_firing: bool,
    beam_start, beam_end: sdl.FPoint,

    animated: bool,
    animation_controller: animation.Animation_Controller,
}

weapon_is_beam :: proc(state: Weapon_State) -> bool {
    return state.definition.beam.length > 0
}

weapon_state_create :: proc(definition_tag: string, team: entity.Team, animated: bool = false) -> (state: Weapon_State) {
    state.definition = weapon_manager_get_definition(definition_tag)

    state.cooldown_counter = 0.0
    state.uses_since_cooldown = 0

    state.charging = false
    state.time_since_charge_start = 0.0

    state.owner_team = team

    state.animated = animated
    state.animation_controller = animation.animation_controller_create(state.definition.animation_source)

    return
}

weapon_state_init :: proc(state: ^Weapon_State) {
    state.charging = false
    state.time_since_charge_start = 0.0
}

weapon_state_select :: proc(state: ^Weapon_State) {
    weapon_state_init(state)
    sound_set_play(&state.definition.sounds, .SELECT)
}

weapon_on_cooldown :: proc(state: Weapon_State) -> bool {
    return state.cooldown_counter > 0
}

// runs for every weapon the controller holds, stowed or not.
// heat only builds in the active update, but cooling has to keep ticking for stowed weapons
// too - otherwise swapping off an overheated beam freezes it overheated forever
weapon_state_update :: proc(state: ^Weapon_State, is_active: bool) {
    if state.cooldown_counter > 0 do state.cooldown_counter -= primatives.dt

    if !weapon_is_beam(state^) do return

    // a stowed weapon is never firing, whatever it was doing when you swapped off it
    if !is_active do state.beam_firing = false

    // the active weapon builds heat in weapon_beam_update instead
    if state.beam_firing do return

    cool_rate := state.definition.heat.cool_rate
    if state.overheated do cool_rate = state.definition.heat.overheat_cool_rate

    state.heat = max(state.heat - cool_rate * primatives.dt, 0)
    if state.overheated && state.heat <= 0 do state.overheated = false
}

weapon_state_active_update :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, fire: bool, shoot_position: sdl.FPoint) {
    state.animation_controller.current_animation = "idle"

    if weapon_is_beam(state^) {
        weapon_beam_update(controller, state, fire, shoot_position)
        return
    }

    if state.charging do state.time_since_charge_start += primatives.dt
    else do state.time_since_charge_start = 0

    if fire do weapon_fire(controller, state, shoot_position)
    else if state.charging {
        weapon_shoot(controller, state, shoot_position)
    }
}

// beam is held not fired, so no projectile
weapon_beam_update :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, fire: bool, shoot_position: sdl.FPoint) {
    heat := state.definition.heat

    state.beam_firing = fire && !state.overheated

    // cooling in weapon_state_update
    if state.beam_firing {
        state.heat += heat.build_rate * primatives.dt
        if heat.max > 0 && state.heat >= heat.max {
            state.heat = heat.max
            state.overheated = true
            state.beam_firing = false
            sound_stop_loop(&state.definition.sounds, .SHOOT)
        }
    }

    if !state.beam_firing {
        sound_stop_loop(&state.definition.sounds, .SHOOT)
        return
    }

    state.animation_controller.current_animation = "shoot"

    mults := STAT_MULTS_IDENTITY
    if controller.stat_mults != nil do mults = controller.stat_mults[state.definition.id]

    direction := sdl.FPoint{ math.cos(controller.aim_angle), math.sin(controller.aim_angle) }
    state.beam_start = shoot_position
    state.beam_end = shoot_position + direction * state.definition.beam.length

    damage_this_tick := state.definition.beam.damage_per_second * mults[.DAMAGE] * primatives.dt
    weapon_beam_apply_damage(controller, state, damage_this_tick)
}

@(private)
weapon_beam_apply_damage :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, damage: f32) {
    // a beam only ever hits the team it is not on
    target_team := entity.Team.ENEMY
    if state.owner_team == .ENEMY do target_team = .ALLY

    pool := entity.entity_manager_get_team_map(target_team)

    it := hm.iterator_make(pool)
    for target, target_handle in hm.iterate(&it) {
        if !target.active do continue

        hit := geo.line_angle_segment_circle_colliding(
            state.beam_start, state.definition.beam.length, controller.aim_angle,
            geo.Circle{ target.collision.position, target.collision.radius },
        )
        if !hit do continue

        damage_data := effect.effect_application_data_from_tag("damage.effect.instance", {}, target_handle, target.team)
        effect.effect_manager_queue_apply(damage_data, effect.Effect_Callback_Data_Override{
            tag = "damage", data = damage,
        })

        // programs that add on-hit effects apply to the beam too
        for instance_id in controller.hit_effects {
            extra_data := effect.effect_application_data_from_id(instance_id, {}, target_handle, target.team)
            effect.effect_manager_queue_apply(extra_data)
        }
    }
}

weapon_state_active_draw :: proc(state: ^Weapon_State, draw_position: sdl.FPoint, natural_draw_angle: f64, flip_mode: sdl.FlipMode) {
    if state.beam_firing {
        color.sdl_set_color(state.definition.beam.beam_color)
        camera.draw_line(state.beam_start, state.beam_end, state.definition.beam.thickness)
    }

    if !state.animated do return

    camera.draw_animation(&state.animation_controller, draw_position, natural_draw_angle, flip_mode)

    color.sdl_set_color(color.Default_Palette_Color.SKY_BLUE)
    camera.fill_circle(geo.Circle{draw_position, 5.0})
}

weapon_fire :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint) {
    if controller.gcd_counter > 0 || weapon_on_cooldown(state^) do return
    
    state.animation_controller.current_animation = "fire"

    if state.definition.max_charge_time > 0 {
        weapon_charge(controller, state, shoot_position)
        return
    }

    weapon_shoot(controller, state, shoot_position)
}

weapon_charge :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint) {
    state.charging = true

    if state.time_since_charge_start == 0 {
        sound_set_play_and_loop(&state.definition.sounds, .CHARGE)
    }
    state.time_since_charge_start += primatives.dt
    if state.time_since_charge_start > state.definition.max_charge_time do state.time_since_charge_start = state.definition.max_charge_time

    if state.definition.charge_callback_proc != nil {
        state.definition.charge_callback_proc(controller, state, shoot_position)
    }
}

weapon_shoot :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint) {
    state.animation_controller.current_animation = "shoot"

    // weapon buffs from programs
    mults := STAT_MULTS_IDENTITY
    if controller.stat_mults != nil do mults = controller.stat_mults[state.definition.id]

    // gcd
    controller.gcd_counter = state.definition.gcd_interval * mults[.GCD_INTERVAL]

    // cooldown
    state.uses_since_cooldown += 1
    if state.uses_since_cooldown >= state.definition.uses_before_cooldown do state.cooldown_counter = state.definition.cooldown * mults[.COOLDOWN]

    // copy shell
    proj_shell := state.definition.projectile_shell

    projectile.shell_add_defaults(&proj_shell, state.owner_team)

    proj_shell.damage = state.definition.damage * mults[.DAMAGE]

    // a dud round still flies and still connects, it just lands for nothing
    miss_chance := state.definition.miss_chance * mults[.MISS_CHANCE]
    if miss_chance > 0 && rand.float32() < miss_chance do proj_shell.damage = 0

    proj_shell.speed *= mults[.PROJECTILE_SPEED]
    proj_shell.team = state.owner_team

    // charging
    if state.charging {
        charge_ratio := state.time_since_charge_start / state.definition.max_charge_time
        proj_shell.speed *= charge_ratio
        proj_shell.damage *= charge_ratio
        proj_shell.piercing = max(uint(f32(proj_shell.piercing) * charge_ratio), 1)
        proj_shell.shape_radius *= charge_ratio

        proj_shell.scale = 1 + state.definition.max_charge_time * charge_ratio

        sound_stop_loop(&state.definition.sounds, .CHARGE)
        state.charging = false
        state.time_since_charge_start = 0.0
    }

    // program hit effects are on the projectile
    for instance_id in controller.hit_effects {
        if proj_shell.num_extra_effects >= projectile.MAX_EXTRA_EFFECTS {
            log.errorf("Weapon %v dropped program hit effects past the projectile cap of %v", state.definition.tag, projectile.MAX_EXTRA_EFFECTS)
            break
        }
        proj_shell.extra_effects[proj_shell.num_extra_effects] = instance_id
        proj_shell.num_extra_effects += 1
    }

    if !state.definition.no_projectile {
        for i in 0..<proj_shell.shots {
            projectile.projectile_manager_spawn(proj_shell, shoot_position, controller.aim_angle)
        }
    }

    // whatever extra behaviour this weapon's json asked for
    if state.definition.shoot_callback_proc != nil {
        state.definition.shoot_callback_proc(controller, state, shoot_position, proj_shell.damage)
    }

    sound_set_play(&state.definition.sounds, .SHOOT)
}