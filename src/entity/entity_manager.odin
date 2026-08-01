package entity

import sdl "vendor:sdl3"

import handle "../handle"

import log "core:log"

@(private)
global_entity_manager: Entity_Manager

Entity_Manager :: struct {
    pools: [Team]handle.Pool(handle.Entity_Tag, Entity)
}

entity_manager_create :: proc() -> (entity_manager: ^Entity_Manager){
    log.infof("Creating entity manager")

    for team in Team {
        global_entity_manager.pools[team] = handle.pool_create(handle.Entity_Tag, Entity)
    }
    
    entity_manager = &global_entity_manager
    return
}

entity_manager_destroy :: proc() {
    log.infof("Destroying entity manager")

    for team in Team {
        pool := &global_entity_manager.pools[team]
        for &entity in pool.data do entity_destroy(&entity)
        

        handle.pool_destroy(pool)
    }
}

entity_get :: proc(entity_handle: Entity_Handle, team: Team) -> (entity: ^Entity, ok: bool) {
    entity, ok = handle.pool_get(&global_entity_manager.pools[team], entity_handle)
    
    return 
}

entity_manager_add_entity :: proc(entity_data: Entity) -> (new_handle: Entity_Handle) {
    new_entity := entity_data
    entity_create(&new_entity)

    new_handle = handle.pool_add(&global_entity_manager.pools[entity_data.team], new_entity)

    entity_give_handle, ok := entity_get(new_handle, entity_data.team)
    if !ok {
        log.errorf("Failed getting entity via handle %v that was just created for said entity", new_handle)
        return
    }
    entity_give_handle.own_handle = new_handle
    
    log.debugf("Adding entity with handle %v", new_handle)

    return 
}

entity_manager_remove_entity :: proc(to_remove: Entity_Handle, team: Team) {
    entity, ok := handle.pool_get(&global_entity_manager.pools[team], to_remove)
    if !ok do return
    

    entity_destroy(entity)

    handle.pool_remove(&global_entity_manager.pools[entity.team], to_remove)
}

entity_manager_update :: proc() {
    for team in Team {
        pool := &global_entity_manager.pools[team]
        for &entity in pool.data {
            entity_update(&entity)
        }
    }
}

// deals damage to every entity of `team` whose center is within `radius` of `center`.
// used by aoe
entity_damage_in_radius :: proc(center: sdl.FPoint, radius: f32, team: Team, amount: f32) {
    pool := &global_entity_manager.pools[team]
    for &e in pool.data {
        if !e.active do continue
        dx := e.position.x - center.x
        dy := e.position.y - center.y
        if dx*dx + dy*dy <= radius*radius do entity_deal_damage(&e, amount)
    }
}

entity_manager_draw :: proc() {
    pool := &global_entity_manager.pools[.ENEMY]
    for &entity in pool.data {
        entity_draw(&entity)
    }

    pool = &global_entity_manager.pools[.NEUTRAL]
    for &entity in pool.data {
        entity_draw(&entity)
    }

    pool = &global_entity_manager.pools[.ALLY]
    for &entity in pool.data {
        entity_draw(&entity)
    }
}