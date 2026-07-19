package entity

import handle "../handle"

import log "core:log"

@(private)
global_effect_manager: Effect_Manager

Effect_Manager :: struct {
    pool: handle.Pool(handle.Effect_Tag, Effect_State),

    unique_definition_ids: Effect_Definition_ID,
    definitions: []Effect_Definition,
    definition_tag_to_id: map[Effect_Definition_Tag]Effect_Definition_ID,

    unique_instance_ids: Effect_Instance_ID,
    instances: []Effect_Instance,
    instance_tag_to_id: map[Effect_Instance_Tag]Effect_Instance_ID,

    application_queue: [dynamic]Effect_Application_Data,
    removal_queue: [dynamic]Effect_Handle,

    loaded: bool,
}

effect_manager_create :: proc() -> (effect_manager: ^Effect_Manager) {
    log.infof("Creating effect manager")

    global_effect_manager.pool = handle.pool_create(handle.Effect_Tag, Effect_State)

    global_effect_manager.application_queue = make([dynamic]Effect_Application_Data)
    global_effect_manager.removal_queue = make([dynamic]Effect_Handle)

    global_effect_manager.definition_tag_to_id = make(map[Effect_Definition_Tag]Effect_Definition_ID)

    global_effect_manager.loaded = false
    
    effect_manager = &global_effect_manager

    return
}

effect_manager_destroy :: proc() {
    log.infof("Destroying effect manager")

    handle.pool_destroy(&global_effect_manager.pool)

    delete(global_effect_manager.instance_tag_to_id)
    delete(global_effect_manager.definition_tag_to_id)

    delete(global_effect_manager.application_queue)
    delete(global_effect_manager.removal_queue)

    effect_manager_unload()
}

// load definitions and instances
effect_manager_load :: proc() {
    if global_effect_manager.loaded {
        log.errorf("Tried to load effect manager when already loaded")
        return
    }

    log.infof("Loading effect manager")
    global_effect_manager.loaded = true

    effect_definitions_load()
    effect_instances_load()
}

// unload definitions and instances
effect_manager_unload :: proc() {
    if !global_effect_manager.loaded do return

    log.infof("Unloading effect manager")
    global_effect_manager.loaded = false

    effect_instances_unload()
    effect_definitions_unload()
}

effect_manager_get_effect :: proc(effect_handle: Effect_Handle) -> (state: ^Effect_State, ok: bool) {
    state, ok = handle.pool_get(&global_effect_manager.pool, effect_handle)
    return 
}

effect_manager_queue_apply :: proc(data: Effect_Application_Data, override: Maybe(Effect_Fn_Data) = nil) {
    data := data
    // Effects by default use their instance's data
    data.callback_data = data.instance.callback_data

    // Effect data can be overwritten. This is for dynamic purposes.
    // For example, all damage is carried out through the effect system.
    // Player damage is dynamic, and for example, could be boosted by 30% due to an item.
    // Thus, when the player applies damage to another.
    override_data, should_override := override.(Effect_Fn_Data)
    if should_override {
        success := effect_state_override_data(&data.callback_data, override_data)
        if !success do log.errorf("Tried to overrite effect state with wrong override data type for instance with tag %v", data.instance.unique_tag)
    }

    append(&global_effect_manager.application_queue, data)
}

effect_manager_queue_remove :: proc(to_remove: Effect_Handle) {
    append(&global_effect_manager.removal_queue, to_remove)
}

effect_manager_update :: proc() {
    //update effects
    i: u32 = 0
    for &effect in global_effect_manager.pool.data {
        defer i += 1

        if !effect.active do continue

        // Generate the corresponding handle
        current_handle := handle.pool_read_handle_with_index(&global_effect_manager.pool, i)

        // Find the target entity
        target_entity, entity_ok := entity_get(effect.target)
        if !entity_ok {
            log.errorf("Error in accessing target entity of handle %v while updaing effect of handle %v", effect.target, current_handle)

            // remove the effect
            append(&global_effect_manager.removal_queue, current_handle)
            entity_remove_active_effect_by_ID(target_entity, effect.instance.definition.unique_id)

            continue
        }

        // todo: manage application queue? in case an effect wants to apply an effect?
        should_remove := effect_state_update(&effect, target_entity)

        if should_remove {
            append(&global_effect_manager.removal_queue, current_handle)
            entity_remove_active_effect_by_ID(target_entity, effect.instance.definition.unique_id)
        }

    }
    // do removals
    for len(global_effect_manager.removal_queue) > 0 {
        to_remove := pop(&global_effect_manager.removal_queue)
        defer handle.pool_remove(&global_effect_manager.pool, to_remove)

        removal_effect, ok := effect_manager_get_effect(to_remove)
        if !ok do continue

        reaction_manager_queue_event(Reaction_Event{
            type = .REMOVE, target = removal_effect.target,
            definition_id = removal_effect.instance.definition.unique_id,
            magnitude = effect_fn_data_get_reaction_magnitude(removal_effect.callback_data.data)
        })        
    }

    // do applications
    for len(global_effect_manager.application_queue) > 0 {
        application_data := pop(&global_effect_manager.application_queue)
        effect_manager_apply_effect(application_data)
    }
}

// This both checks if the effect should apply at all,
// as well as manages the stacking logic of the preexisiting effect.
effect_manager_stack_on_apply :: proc(
    instance: ^Effect_Instance, target_entity: ^Entity
) -> (should_apply: bool) {
    maybe_existing_effect := entity_get_active_effect_by_ID(target_entity, instance.definition.unique_id)
    is_existing_effect := maybe_existing_effect != nil

    if !is_existing_effect do return true

    // While this would fail if there is no existing effect, we have already returned in such a case.
    // As such, be very careful not to move the above conditional return to below this block of code.
    existing_effect_handle, _ := maybe_existing_effect.(Effect_Handle)
    existing_effect, effect_ok := effect_manager_get_effect(existing_effect_handle)
    if !effect_ok {
        log.errorf("error in attempt to get existing effect with handle %v on entity while applying effect", existing_effect_handle)
        return false
    }

    switch instance.definition.stack_behaviour {
    case .NONE:
        return false
    case .REFRESH:
        effect_state_refresh(existing_effect)
        return false
    case .EXTEND:
        effect_state_extend(existing_effect, instance^)
        return false
    case .STACK:
        // do nothing!
    }

    return true
}

@(private)
effect_manager_apply_effect :: proc(
    application_data: Effect_Application_Data,
) {
    target := application_data.target
    source := application_data.source
    instance := application_data.instance

    target_entity, entity_ok := entity_get(target)
    if !entity_ok {
        log.errorf("error in attempt to get entity of handle %v while applying effect", target)
        return
    }

    state := effect_state_create(application_data)

    should_apply := effect_manager_stack_on_apply(instance, target_entity)
    if !should_apply do return

    // Queue event that will cause reaction
    reaction_manager_queue_event(Reaction_Event{
        type = .APPLY, target = application_data.target,
        definition_id = application_data.instance.definition.unique_id,
        magnitude = effect_fn_data_get_reaction_magnitude(application_data.callback_data.data)
    })

    new_effect_handle := handle.pool_add(&global_effect_manager.pool, state)
    entity_add_active_effect_by_ID(target_entity, state.instance.definition.unique_id, new_effect_handle)
}