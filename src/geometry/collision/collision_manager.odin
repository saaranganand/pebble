package collision

import sdl "vendor:sdl3"

import entity "src:entity"
import effect "src:entity/entity_effect"
import projectile "src:geometry/projectile"
import handle "src:handle"
import geo "src:geometry"

import log "core:log"

resolve_collisions :: proc(
    projectile_manager: ^projectile.Projectile_Manager, entity_manager: ^entity.Entity_Manager, effect_manager: ^effect.Effect_Manager,
) {
    for projectile_team in entity.Team {
        projectile_list := &projectile_manager.lists[projectile_team]
        for entity_team in entity.Team {
            if projectile_team == entity_team do continue
            entity_pool := &entity_manager.pools[entity_team]

            for &projectiles, cat in projectile_list {
                //log.warnf("num projectiles = %v", len(projectiles))
                for &check_projectile in projectiles {
                    if !check_projectile.active do continue

                    //log.warnf("num entities = %v", len(entity_pool.data))
                    entity_handle := handle.Entity_Handle{ 0, 0 }
                    for &check_entity in entity_pool.data {
                        defer entity_handle.index += 1
                        if !check_entity.active do continue

                        entity_handle.generation = entity_pool.generations[entity_handle.index]

                        collision := projectile.projectile_state_check_collision(
                            check_projectile, geo.Circle{check_entity.position, check_entity.col_radius}
                        )
                        if !collision do continue

                        effect_data := effect.effect_application_data_from_tag("damage.effect.instance", {}, entity_handle, check_entity.team)

                        effect.effect_manager_queue_apply(effect_data, effect.Effect_Callback_Data_Override{
                            tag = "damage", data = check_projectile.damage
                        })

                        // weapon's own on-hit effect
                        if apply_tag, has_apply := check_projectile.apply_effect.(effect.Effect_Instance_Tag); has_apply {
                            apply_data := effect.effect_application_data_from_tag(apply_tag, {}, entity_handle, check_entity.team)
                            effect.effect_manager_queue_apply(apply_data)
                        }

                        // On-hit effects granted by the shooter's programs
                        for i in 0..<check_projectile.num_extra_effects {
                            extra_data := effect.effect_application_data_from_id(check_projectile.extra_effects[i], {}, entity_handle, check_entity.team)
                            effect.effect_manager_queue_apply(extra_data)
                        }

                        if check_projectile.piercing > 0 do check_projectile.piercing -= 1
                    }
                }
            }
        }
    }
}