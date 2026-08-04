package collision

import "src:HUD"
import sdl "vendor:sdl3"

import entity "src:entity"
import hm "core:container/handle_map"
import effect "src:entity/effect"
import projectile "src:geometry/projectile"
import handle "src:handle"
import geo "src:geometry"
import util "src:util"

import log "core:log"
import xar "core:container/xar"

resolve_collisions :: proc(
    projectile_manager: ^projectile.Projectile_Manager,
    entity_manager: ^entity.Entity_Manager,
    effect_manager: ^effect.Effect_Manager,
) {

    for entity_team in entity.Team {
        pool := &entity_manager.entities[entity_team]
        it := hm.iterator_make(pool)
        for e, e_h in hm.iterate(&it) {
            resolve_projectile_collisions(projectile_manager, entity_manager, e, e_h)
        }
    }

    
}

resolve_projectile_collisions :: proc(
    projectile_manager: ^projectile.Projectile_Manager,
    entity_manager: ^entity.Entity_Manager,
    check_entity: ^entity.Entity, check_entity_handle: util.Handle
) {
    for projectile_team in entity.Team {
        if projectile_team == check_entity.team do continue
        projectile_list := &projectile_manager.projectiles[projectile_team]

        it := xar.iterator(projectile_list)
        for projectile_state, idx in xar.iterate_by_ptr(&it) {
            if !projectile_state.active do continue

            collision := projectile.state_check_collision(
                projectile_state^, check_entity.collision
            )
            if !collision do continue

            effect_data := effect.effect_application_data_from_tag("damage.effect.instance", {}, check_entity_handle, check_entity.team)

            effect.effect_manager_queue_apply(effect_data, effect.Effect_Callback_Data_Override{
                tag = "damage", data = projectile_state.damage
            })

            if projectile_state.piercing > 0 do projectile_state.piercing -= 1
        }

        resolve_tracking_arrow_collisions(projectile_manager, entity_manager, check_entity, check_entity_handle, projectile_team)
    }
}

resolve_tracking_arrow_collisions :: proc(
    projectile_manager: ^projectile.Projectile_Manager,
    entity_manager: ^entity.Entity_Manager,
    check_entity: ^entity.Entity, check_entity_handle: util.Handle,
    projectile_team: entity.Team
) {
    tracking_arrow_list := &projectile_manager.tracking_arrows[projectile_team]

    tracking_it := xar.iterator(tracking_arrow_list)
    for tracking_arrow_state, idx in xar.iterate_by_ptr(&tracking_it) {
        if !tracking_arrow_state.active do continue

        collision := projectile.tracking_arrow_collision(
            tracking_arrow_state^, check_entity.collision
        )
        if !collision do continue

        effect_data := effect.effect_application_data_from_tag("damage.effect.instance", {}, check_entity_handle, check_entity.team)

        effect.effect_manager_queue_apply(effect_data, effect.Effect_Callback_Data_Override{
            tag = "damage", data = tracking_arrow_state.damage
        })

        if tracking_arrow_state.piercing > 0 do tracking_arrow_state.piercing -= 1
    }
}