package program

import effect "src:entity/effect"
import weapon "src:item/weapon"
import entity "src:entity"
import util "src:util"

import reflect "core:reflect"
import log "core:log"

// a program loadout is owned by a program-wielding entity (player)
// equip/unequip rebuilds below
Program_Loadout :: struct {
    owner: util.Handle,
    owner_team: entity.Team,
    weapon_controller: ^weapon.Weapon_Controller,

    equipped: [dynamic]^Program_Definition,

    stat_mults: weapon.Stat_Mult_Table,
    stat_adds: weapon.Stat_Add_Table,
    entity_stat_mults: entity.Entity_Stat_Mults,
    entity_stat_adds: entity.Entity_Stat_Adds,
    hit_effects: [dynamic]effect.Effect_Instance_ID,
}

// must be called after weapon manager load
program_loadout_create :: proc(
    loadout: ^Program_Loadout, owner: util.Handle, owner_team: entity.Team,
    weapon_controller: ^weapon.Weapon_Controller,
) {
    loadout.owner = owner
    loadout.owner_team = owner_team
    loadout.weapon_controller = weapon_controller

    loadout.equipped = make([dynamic]^Program_Definition)
    loadout.stat_mults = make(weapon.Stat_Mult_Table, weapon.weapon_manager_num_definitions())
    loadout.stat_adds = make(weapon.Stat_Add_Table, weapon.weapon_manager_num_definitions())
    loadout.hit_effects = make([dynamic]effect.Effect_Instance_ID)

    program_loadout_recompute(loadout)
}

program_loadout_destroy :: proc(loadout: ^Program_Loadout) {
    delete(loadout.equipped)
    delete(loadout.stat_mults)
    delete(loadout.stat_adds)
    delete(loadout.hit_effects)
}

program_loadout_equip :: proc(loadout: ^Program_Loadout, definition_tag: Program_Definition_Tag) -> bool {
    definition := program_manager_get_definition(definition_tag)
    if definition == nil do return false

    for equipped in loadout.equipped {
        if equipped == definition {
            log.warnf("Attempt to equip program %v that is already equipped", definition_tag)
            return false
        }
    }

    append(&loadout.equipped, definition)

    for self_effect in definition.self_effects {
        application_data := effect.effect_application_data_from_id(
            self_effect.instance_id, loadout.owner, loadout.owner, loadout.owner_team
        )
        effect.effect_manager_queue_apply(application_data)
    }

    program_loadout_recompute(loadout)

    log.infof("Equipped program %v", definition_tag)
    return true
}

program_loadout_unequip :: proc(loadout: ^Program_Loadout, definition_tag: Program_Definition_Tag) -> bool {
    for equipped, i in loadout.equipped {
        if equipped.unique_tag != definition_tag do continue

        for self_effect in equipped.self_effects {
            removed := effect.effect_manager_remove_effect_from_entity(loadout.owner, self_effect.definition_id)
            if !removed do log.errorf("Program %v unequip could not find its self effect on owner", definition_tag)
        }

        ordered_remove(&loadout.equipped, i)
        program_loadout_recompute(loadout)

        log.infof("Unequipped program %v", definition_tag)
        return true
    }

    log.warnf("Attempt to unequip program %v that is not equipped", definition_tag)
    return false
}

// Writes every equipped program's named entity params onto owner
// Recompute rebuilds from scratc
@(private)
program_loadout_apply_entity_params :: proc(loadout: ^Program_Loadout) {
    owner, ok := entity.entity_get(loadout.owner, loadout.owner_team)
    if !ok do return

    entity_base := cast(uintptr) owner
    previous_max_shield := owner.max_shield

    // reset
    for id in 0..<program_manager_num_definitions() {
        definition := program_manager_get_definition_by_id(id)
        if definition == nil do continue

        for name in definition.entity_params {
            field := reflect.struct_field_by_name(typeid_of(entity.Entity), name)
            if field.name == "" do continue
            (cast(^f32)(entity_base + field.offset))^ = 0
        }
    }

    // apply
    for definition in loadout.equipped {
        for name, value in definition.entity_params {
            field := reflect.struct_field_by_name(typeid_of(entity.Entity), name)
            if field.name == "" do continue
            (cast(^f32)(entity_base + field.offset))^ = value
        }
    }

    if owner.max_shield != previous_max_shield do owner.shield = owner.max_shield
    owner.shield = min(owner.shield, owner.max_shield)
}

// recalculates the player's total program bonuses from scratch and applies them
// runs on every pickup (and eventual drop)
@(private)
program_loadout_recompute :: proc(loadout: ^Program_Loadout) {
    for &mults in loadout.stat_mults {
        mults = weapon.STAT_MULTS_IDENTITY
    }
    for &adds in loadout.stat_adds {
        adds = weapon.STAT_ADDS_ZERO
    }
    clear(&loadout.hit_effects)

    entity_mults := entity.ENTITY_STAT_MULTS_IDENTITY
    entity_adds := entity.ENTITY_STAT_ADDS_ZERO

    for definition in loadout.equipped {
        for buff in definition.buffs {
            multiplier := buff.multiplier if buff.multiplier != 0 else 1

            if weapon_id, targeted := buff.weapon_id.(weapon.Weapon_Definition_ID); targeted {
                loadout.stat_mults[weapon_id][buff.stat] *= multiplier
                loadout.stat_adds[weapon_id][buff.stat] += buff.add
            } else {
                for &mults, i in loadout.stat_mults {
                    mults[buff.stat] *= multiplier
                    loadout.stat_adds[i][buff.stat] += buff.add
                }
            }
        }
        for buff in definition.entity_buffs {
            entity_mults[buff.stat] *= buff.multiplier if buff.multiplier != 0 else 1
            entity_adds[buff.stat] += buff.add
        }

        for instance_id in definition.hit_effects {
            append(&loadout.hit_effects, instance_id)
        }
    }

    program_loadout_apply_entity_params(loadout)

    loadout.entity_stat_mults = entity_mults
    loadout.entity_stat_adds = entity_adds
    if owner, ok := entity.entity_get(loadout.owner, loadout.owner_team); ok {
        old_max_hp := owner.max_hp
        owner.max_hp = (owner.base_max_hp + entity_adds[.MAX_HEALTH]) * entity_mults[.MAX_HEALTH]
        if old_max_hp > 0 do owner.hp *= owner.max_hp / old_max_hp
        owner.hp = min(owner.hp, owner.max_hp)
        owner.damage_taken_mult = entity_mults[.DAMAGE_TAKEN]
        owner.move_speed_mult = entity_mults[.MOVE_SPEED]

    }

    // hit_effects maybe realloced, refresh
    weapon.weapon_controller_set_program_data(
        loadout.weapon_controller, loadout.stat_mults, loadout.stat_adds, loadout.hit_effects[:],
    )
}
