package collision

import sdl "vendor:sdl3"

import entity "src:entity"
import effect "src:entity/entity_effect"
import projectile "src:geometry/projectile"
import handle "src:handle"
import geo "src:geometry"

import log "core:log"
import xar "core:container/xar"

resolve_collisions :: proc(
    projectile_manager: ^projectile.Projectile_Manager, entity_manager: ^entity.Entity_Manager, effect_manager: ^effect.Effect_Manager,
) {
    for entity_team in entity.Team {
        entity_pool := &entity_manager.pools[entity_team]
        entity_handle := handle.Entity_Handle{ 0, 0 }

        for &check_entity in entity_pool.data {
            defer entity_handle.index += 1
            if !check_entity.active do continue

            entity_handle.generation = entity_pool.generations[entity_handle.index]

            for projectile_team in entity.Team {
                if projectile_team == entity_team do continue
                projectile_list := &projectile_manager.projectiles[projectile_team]

                it := xar.iterator(projectile_list)
                for projectile_state, idx in xar.iterate_by_ptr(&it) {
                    if !projectile_state.active do continue

                    collision := projectile.state_check_collision(
                        projectile_state^, geo.Circle{check_entity.position, check_entity.col_radius}
                    )
                    if !collision do continue

                    effect_data := effect.effect_application_data_from_tag("damage.effect.instance", {}, entity_handle, check_entity.team)

                    effect.effect_manager_queue_apply(effect_data, effect.Effect_Callback_Data_Override{
                        tag = "damage", data = projectile_state.damage
                    })

                    if projectile_state.piercing > 0 do projectile_state.piercing -= 1
                }

                tracking_arrow_list := &projectile_manager.tracking_arrows[projectile_team]

                tracking_it := xar.iterator(tracking_arrow_list)
                for tracking_arrow_state, idx in xar.iterate_by_ptr(&tracking_it) {
                    if !tracking_arrow_state.active do continue

                    collision := projectile.tracking_arrow_collision(
                        tracking_arrow_state^, geo.Circle{check_entity.position, check_entity.col_radius}
                    )
                    if !collision do continue

                    effect_data := effect.effect_application_data_from_tag("damage.effect.instance", {}, entity_handle, check_entity.team)

                    effect.effect_manager_queue_apply(effect_data, effect.Effect_Callback_Data_Override{
                        tag = "damage", data = tracking_arrow_state.damage
                    })

                    if tracking_arrow_state.piercing > 0 do tracking_arrow_state.piercing -= 1
                }
            }
        }
    }
}