package program

import effect "src:entity/entity_effect"
import weapon "src:item/weapon"
import entity "src:entity"
import handle "src:handle"

import log "core:log"

// A program loadout is owned by a program-wielding entity (currently player)
// equip/unequip rebuilds the folded aggregates below, so per-shot reads in the weapon package stay a single table lookup
Program_Loadout :: struct {
    owner: handle.Entity_Handle,
    owner_team: entity.Team,
    weapon_controller: ^weapon.Weapon_Controller,

    equipped: [dynamic]^Program_Definition,

    stat_mults: weapon.Stat_Mult_Table,
    entity_stat_mults: entity.Entity_Stat_Mults,
    hit_effects: [dynamic]effect.Effect_Instance_ID,
}

// Must be called after weapon manager load (mult table is sized based on total number of weapon definitions)
program_loadout_create :: proc(
    loadout: ^Program_Loadout, owner: handle.Entity_Handle, owner_team: entity.Team,
    weapon_controller: ^weapon.Weapon_Controller,
) {
    loadout.owner = owner
    loadout.owner_team = owner_team
    loadout.weapon_controller = weapon_controller

    loadout.equipped = make([dynamic]^Program_Definition)
    loadout.stat_mults = make(weapon.Stat_Mult_Table, weapon.weapon_manager_num_definitions())
    loadout.hit_effects = make([dynamic]effect.Effect_Instance_ID)

    program_loadout_recompute(loadout)
}

program_loadout_destroy :: proc(loadout: ^Program_Loadout) {
    delete(loadout.equipped)
    delete(loadout.stat_mults)
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

// recalculates the player's total program bonuses from scratch and applies them
// runs on every pickup (and eventual drop)
@(private)
program_loadout_recompute :: proc(loadout: ^Program_Loadout) {
    for &mults in loadout.stat_mults {
        mults = weapon.STAT_MULTS_IDENTITY
    }
    clear(&loadout.hit_effects)

    entity_mults := entity.ENTITY_STAT_MULTS_IDENTITY

    for definition in loadout.equipped {
        for buff in definition.buffs {
            if weapon_id, targeted := buff.weapon_id.(weapon.Weapon_Definition_ID); targeted {
                loadout.stat_mults[weapon_id][buff.stat] *= buff.multiplier
            } else {
                for &mults in loadout.stat_mults {
                    mults[buff.stat] *= buff.multiplier
                }
            }
        }
        for buff in definition.entity_buffs {
            entity_mults[buff.stat] *= buff.multiplier
        }

        for instance_id in definition.hit_effects {
            append(&loadout.hit_effects, instance_id)
        }
    }

    loadout.entity_stat_mults = entity_mults
    if owner, ok := entity.entity_get(loadout.owner, loadout.owner_team); ok {
        old_max_health := owner.max_health
        owner.max_health = owner.base_max_health * entity_mults[.MAX_HEALTH]
        if old_max_health > 0 do owner.health *= owner.max_health / old_max_health
        owner.health = min(owner.health, owner.max_health)
        owner.damage_taken_mult = entity_mults[.DAMAGE_TAKEN]
        owner.move_speed_mult = entity_mults[.MOVE_SPEED]
    }

    // hit_effects maybe realloced, refresh
    weapon.weapon_controller_set_program_data(loadout.weapon_controller, loadout.stat_mults, loadout.hit_effects[:])
}
