package weapon

import entity "src:entity"
import camera "src:camera"
import handle "src:handle"
import effect "src:entity/entity_effect"
import geo "src:geometry"
import sdl "vendor:sdl3"

import log "core:log"

// Escape hatch for weapon behaviour that isn't expressible as parameters.
// A weapon's json names the behaviour it wants, the name is resolved to one of the procs
// below once at load, and the weapon then calls it without ever knowing what it does.
// Adding a behaviour is a proc plus a line in the switch - no changes to Weapon_State.
// damage is the fully resolved amount for this shot - program mults, charge scaling and
// dud rolls are already applied, so a callback never has to recompute any of that
Shoot_Callback :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint, damage: f32)
Charge_Callback :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint)

// fires once per shot, after the projectiles are spawned
weapon_shoot_callback_get :: proc(name: string) -> Shoot_Callback {
    switch name {
    case "scope":
        return scope_shoot_callback
    }

    log.errorf("Weapon names shoot callback %v, which is not registered in weapon_shoot_callback_get", name)
    return nil
}

// Scope hits whatever the crosshair is sitting on and nothing else. No projectile travels,
// so enemies in front of the target cant soak the shot. Missing the crosshair wastes it.
scope_shoot_callback :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint, damage: f32) {
    target_team := entity.Team.ENEMY
    if controller.team == .ENEMY do target_team = .ALLY

    cursor_world := camera.view_position_to_world(controller.mouse_pos)
    pool := entity.entity_manager_get_team_pool(target_team)

    hit_handle: handle.Entity_Handle
    hit_distance: f32
    found := false

    target_handle := handle.Entity_Handle{ 0, 0 }
    for &target in pool.data {
        defer target_handle.index += 1
        if !target.active do continue

        target_handle.generation = pool.generations[target_handle.index]

        // the crosshair has to actually be sitting on them
        distance := geo.get_point_distance(cursor_world, target.position)
        if distance > target.col_radius do continue

        // if a few overlap under the cursor, take whichever is most centred on it
        if found && distance >= hit_distance do continue

        hit_handle = target_handle
        hit_distance = distance
        found = true
    }

    if !found do return

    damage_data := effect.effect_application_data_from_tag("damage.effect.instance", {}, hit_handle, target_team)
    effect.effect_manager_queue_apply(damage_data, effect.Effect_Callback_Data_Override{
        tag = "damage", data = damage,
    })

    for instance_id in controller.hit_effects {
        extra_data := effect.effect_application_data_from_id(instance_id, {}, hit_handle, target_team)
        effect.effect_manager_queue_apply(extra_data)
    }
}

// fires every frame the weapon is being charged
weapon_charge_callback_get :: proc(name: string) -> Charge_Callback {
    switch name {
    case "charge_slow":
        return charge_slow_callback
    }

    log.errorf("Weapon names charge callback %v, which is not registered in weapon_charge_callback_get", name)
    return nil
}

// slows the wielder while they hold a charge. the amount comes from the weapon's json.
// entity_update recomputes move_speed from base * mult every frame, so this penalty
// undoes itself the moment we stop charging and never fights the program stat mults.
charge_slow_callback :: proc(controller: ^Weapon_Controller, state: ^Weapon_State, shoot_position: sdl.FPoint) {
    if state.definition.charge_move_speed_mult <= 0 do return

    owner, ok := entity.entity_get(controller.owner, controller.team)
    if !ok do return

    owner.move_speed *= state.definition.charge_move_speed_mult
}
