package effect

import handle "../handle"
import entity "../entity"

import log "core:log"

@(private)
global_effect_manager: Effect_Manager

Effect_Instance_Tag_To_ID_Map :: map[Effect_Instance_Tag]Effect_Instance_ID
Effect_Definition_Tag_To_ID_Map :: map[Effect_Definition_Tag]Effect_Definition_ID

Effect_Manager :: struct {
    pool: handle.Pool(handle.Effect_Tag, Effect_State),

    unique_definition_ids: Effect_Definition_ID,
    definitions: []Effect_Definition,
    definition_tag_to_id: Effect_Definition_Tag_To_ID_Map,

    unique_instance_ids: Effect_Instance_ID,
    instances: []Effect_Instance,
    instance_tag_to_id: Effect_Instance_Tag_To_ID_Map,

    application_queue: [dynamic]Effect_Application_Data,
    removal_queue: [dynamic]Effect_Handle,

    // A slice that is sized as the total number of unqiue effect definitions loaded in.
    // When an effect is applied, give this the handle.
    // When the effect is removed, set this to nil.
    // For all cases where we dont want to stack, this operates as a boolean check, as well as a source
    // for the exisiting effect in case we need to modify it (for ex. to extend it).
    // For cases where we do want to stack, this check is INVALID.
    // What I mean by that is, because stacking is handled by definition, but instances of a definition can differ,
    // just-applied effect A of definition X could be for 20s -> 5s into A, effect B, also of definition X, and 10s long, is applied
    // B overwrites A in this active_effects slice -> 10s later, B ends, and this the slot for the definition in active_effects is set to nil ->
    // however, A is still active for 5s. Thus this check is invalid and misses the shadowed effect.
    // This is OKAY because currently, the only situations were there could possibly be more than one effect of a definition on an entity,
    // and thus this shadowing situation is possible, are also situations where we do not care if there is or is not the effect on the entity.
    // Thus, whether or not this check is valid or invalid does not matter to us.
    // !! If that were to change !! Then this system would need to be reworked.
    entity_active_effects: Effect_Active_Entity_Effect_Map,

    events: [dynamic]Effect_Event,

    loaded: bool,
}

effect_manager_create :: proc() -> (effect_manager: ^Effect_Manager) {
    log.infof("Creating effect manager")

    global_effect_manager.pool = handle.pool_create(handle.Effect_Tag, Effect_State)

    global_effect_manager.application_queue = make([dynamic]Effect_Application_Data)
    global_effect_manager.removal_queue = make([dynamic]Effect_Handle)

    global_effect_manager.definition_tag_to_id = make(Effect_Definition_Tag_To_ID_Map)
    global_effect_manager.instance_tag_to_id = make(Effect_Instance_Tag_To_ID_Map)

    global_effect_manager.entity_active_effects = make(Effect_Active_Entity_Effect_Map)
    global_effect_manager.events = make([dynamic]Effect_Event)

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

    effect_manager_wipe_entity_active_effect_map()
    delete(global_effect_manager.events)

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

effect_manager_queue_event :: proc(event_data: Effect_Event) {
    append(&global_effect_manager.events, event_data)
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
        target_entity, entity_ok := entity.entity_get(effect.target, effect.target_team)
        if !entity_ok {
            //log.errorf("Error in accessing target entity of handle %v while updaing effect of handle %v", effect.target, current_handle)

            // remove the effect
            effect.active = false
            effect_manager_queue_remove(current_handle)
            effect_manager_wipe_entity_active_effect_key(effect.target)

            continue
        }

        // todo: manage application queue? in case an effect wants to apply an effect?
        should_remove := effect_state_update(&effect, target_entity)

        if should_remove {
            effect.active = false
            effect_manager_queue_remove(current_handle)
            effect_manager_remove_entity_active_effect(effect.target, effect.instance.definition.unique_id, current_handle)
        }

        

    }
    // do removals
    for len(global_effect_manager.removal_queue) > 0 {
        to_remove := pop(&global_effect_manager.removal_queue)
        defer handle.pool_remove(&global_effect_manager.pool, to_remove)

        removal_effect, ok := effect_manager_get_effect(to_remove)
        if !ok do continue

        effect_manager_queue_event(Effect_Event{
            type = .REMOVE, target = removal_effect.target,
            target_team = removal_effect.target_team,
            definition_id = removal_effect.instance.definition.unique_id,
            magnitude = effect_fn_data_get_reaction_magnitude(removal_effect.callback_data.data)
        }) 
    }

    // do applications
    for len(global_effect_manager.application_queue) > 0 {
        //log.errorf("app queue len = %v", len(global_effect_manager.application_queue))
        application_data := pop(&global_effect_manager.application_queue)
        effect_manager_apply_effect(application_data)
    }
}

// This both checks if the effect should apply at all,
// as well as manages the stacking logic of the preexisiting effect.
effect_manager_stack_on_apply :: proc(
    instance: ^Effect_Instance, target: handle.Entity_Handle
) -> (should_apply: bool) {
    if instance.definition.stack_behaviour == .STACK do return true
    //maybe_existing_effect := entity_get_active_effect_by_ID(target_entity, instance.definition.unique_id)
    //is_existing_effect := maybe_existing_effect != nil

    //if !is_existing_effect do return true

    // While this would fail if there is no existing effect, we have already returned in such a case.
    // As such, be very careful not to move the above conditional return to below this block of code.
    
    existing_effect_handle, existing_effect_handle_ok := effect_manager_get_entity_active_effect(target, instance.definition.unique_id)
    // No effect, dont care about stacking
    if !existing_effect_handle_ok do return true

    // If the effect is already applied, make sure we can resolve the supposed exisiting effect
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

    state := effect_state_create(application_data)

    should_apply := effect_manager_stack_on_apply(instance, target)
    if !should_apply do return

    // Queue event that will cause reaction
    effect_manager_queue_event(Effect_Event{
        type = .APPLY, target = application_data.target,
        target_team = application_data.target_team,
        definition_id = application_data.instance.definition.unique_id,
        magnitude = effect_fn_data_get_reaction_magnitude(application_data.callback_data.data)
    })

    new_effect_handle := handle.pool_add(&global_effect_manager.pool, state)
    
    // TODO
    effect_manager_add_entity_active_effect(target, {new_effect_handle, instance.definition.unique_id})
}