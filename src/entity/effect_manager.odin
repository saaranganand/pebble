package entity

import handle "../handle"

import log "core:log"

// The data needed to apply an effect
Effect_Application_Data :: struct {
    instance: ^Effect_Instance,
    source, target: Entity_Handle
}

Effect_Manager :: struct {
    pool: handle.Pool(handle.Effect_Tag, Effect_State),
    unqiue_definition_ids: Effect_Definition_ID,
    application_queue: [dynamic]Effect_Application_Data,
    removal_queue: [dynamic]Effect_Handle,
}

effect_manager_create :: proc(effect_manager: ^Effect_Manager) {
    effect_manager.pool = handle.pool_create(handle.Effect_Tag, Effect_State)
    effect_manager.application_queue = make([dynamic]Effect_Application_Data)
    effect_manager.removal_queue = make([dynamic]Effect_Handle)
}

effect_manager_destroy :: proc(effect_manager: ^Effect_Manager) {
    handle.pool_destroy(&effect_manager.pool)
    delete(effect_manager.application_queue)
    delete(effect_manager.removal_queue)
}

effect_manager_get_effect :: proc(effect_manager: ^Effect_Manager, effect_handle: Effect_Handle) -> (state: ^Effect_State, ok: bool) {
    state, ok = handle.pool_get(&effect_manager.pool, effect_handle)
    return 
}

effect_manager_queue_apply :: proc(effect_manager: ^Effect_Manager, instance: ^Effect_Instance, source, target: Entity_Handle) {
    data := Effect_Application_Data{instance, source, target}
    append(&effect_manager.application_queue, data)
}

effect_manager_queue_remove :: proc(effect_manager: ^Effect_Manager, to_remove: Effect_Handle) {
    append(&effect_manager.removal_queue, to_remove)
}

effect_manager_update :: proc(effect_manager: ^Effect_Manager, entity_manager: ^Entity_Manager) {
    //update effects
    i: u32 = 0
    for &effect in effect_manager.pool.data {
        defer i += 1

        if !effect.active do continue

        // Generate the corresponding handle
        current_handle := handle.pool_read_handle_with_index(&effect_manager.pool, i)

        // Find the target entity
        target_entity, entity_ok := entity_get(entity_manager, effect.target)
        if !entity_ok {
            log.errorf("Error in accessing target entity of handle %v while updaing effect of handle %v", effect.target, current_handle)

            // remove the effect
            append(&effect_manager.removal_queue, current_handle)
            entity_remove_active_effect_by_ID(target_entity, effect.instance.definition.unique_id)

            continue
        }

        should_remove := effect_state_update(&effect)

        if should_remove {
            append(&effect_manager.removal_queue, current_handle)
            entity_remove_active_effect_by_ID(target_entity, effect.instance.definition.unique_id)
        }

    }
    // do removals
    for len(effect_manager.removal_queue) > 0 {
        to_remove := pop(&effect_manager.removal_queue)
        handle.pool_remove(&effect_manager.pool, to_remove)
    }

    // do applications
    for len(effect_manager.application_queue) > 0 {
        application_data := pop(&effect_manager.application_queue)
        effect_manager_apply_effect(effect_manager, entity_manager, application_data)
    }
}

// This both checks if the effect should apply at all,
// as well as manages the stacking logic of the preexisiting effect.
effect_manager_stack_on_apply :: proc(
    effect_manager: ^Effect_Manager, entity_manager: ^Entity_Manager,
    definition: ^Effect_Definition, target_entity: ^Entity
) -> (should_apply: bool) {
    maybe_existing_effect := entity_get_active_effect_by_ID(target_entity, definition.unique_id)
    is_existing_effect := maybe_existing_effect != nil

    if !is_existing_effect do return true

    // While this would fail if there is no existing effect, we have already returned in such a case.
    // As such, be very careful not to move the above conditional return to below this block of code.
    existing_effect_handle, _ := maybe_existing_effect.(Effect_Handle)
    existing_effect, effect_ok := effect_manager_get_effect(effect_manager, existing_effect_handle)
    if !effect_ok {
        log.errorf("error in attempt to get existing effect with handle %v on entity while applying effect", existing_effect_handle)
        return false
    }

    switch definition.stack_behaviour {
    case .NONE:
        return false
    case .REFRESH:
        effect_state_refresh(existing_effect)
        return false
    case .EXTEND:
        effect_state_extend(existing_effect)
        return false
    case .STACK:
        // do nothing!
    }

    return true
}

@(private)
effect_manager_apply_effect :: proc(
    effect_manager: ^Effect_Manager, entity_manager: ^Entity_Manager,
    application_data: Effect_Application_Data,
) {
    target := application_data.target
    source := application_data.source
    instance := application_data.instance

    target_entity, entity_ok := entity_get(entity_manager, target)
    if !entity_ok {
        log.errorf("error in attempt to get entity of handle %v while applying effect", target)
        return
    }

    state := effect_state_create(instance, source, target)

    should_apply := effect_manager_stack_on_apply(effect_manager, entity_manager, instance.definition, target_entity)
    if !should_apply do return

    new_effect_handle := handle.pool_add(&effect_manager.pool, state)
    entity_add_active_effect_by_ID(target_entity, state.instance.definition.unique_id, new_effect_handle)
}