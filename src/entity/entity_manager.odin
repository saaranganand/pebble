package entity

import sdl "vendor:sdl3"

import handle "../handle"

import log "core:log"

Entity_Manager :: struct {
    pool: handle.Pool(handle.Entity_Tag, Entity),
    borrowed_effect_definition_count: Effect_Definition_ID,
}

entity_manager_create :: proc(entity_manager: ^Entity_Manager, effect_manager: ^Effect_Manager) {
    log.infof("Creating entity manager")

    entity_manager.pool = handle.pool_create(handle.Entity_Tag, Entity)
    entity_manager.borrowed_effect_definition_count = effect_manager.unique_definition_ids
}

entity_manager_destroy :: proc(entity_manager: ^Entity_Manager) {
    log.infof("Destroying entity manager")

    
    i: u32 = 0
    for &effect in entity_manager.pool.data {
        defer i += 1

        current_handle := handle.pool_read_handle_with_index(&entity_manager.pool, i)

        // Find the target entity
        entity, entity_ok := entity_get(entity_manager, current_handle)
        if !entity_ok do continue
        entity_destroy(entity)
    }

    handle.pool_destroy(&entity_manager.pool)
}

entity_get :: proc(entity_manager: ^Entity_Manager, entity_handle: Entity_Handle) -> (entity: ^Entity, ok: bool) {
    entity, ok = handle.pool_get(&entity_manager.pool, entity_handle)
    return 
}

entity_manager_add_entity :: proc(entity_manager: ^Entity_Manager, entity_data: Entity) -> (new_handle: Entity_Handle) {
    new_entity := entity_data
    entity_create(&new_entity, entity_manager)

    new_handle = handle.pool_add(&entity_manager.pool, new_entity)
    log.debugf("Adding entity with handle %v", new_handle)

    return 
}

entity_manager_remove_entity :: proc(entity_manager: ^Entity_Manager, to_remove: Entity_Handle) {
    entity, ok := entity_get(entity_manager, to_remove)
    if !ok do return

    log.debugf("Removing entity with handle %v", to_remove)

    entity_destroy(entity)

    handle.pool_remove(&entity_manager.pool, to_remove)
}