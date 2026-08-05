package effect

import handle "src:handle"
import entity "src:entity"
import util "src:util"

import hm "core:container/handle_map"
import log "core:log"

@(private)
global_manager: Effect_Manager

Effect_Manager :: struct {
    effects: hm.Dynamic_Handle_Map(Effect_State, util.Handle),

    definitions: []Effect_Definition,
    num_definitions: uint,
    definition_id_map: map[string]uint,

    instances: []Effect_Instance,
    num_instances: uint,
    instance_id_map: map[string]uint,

    application_queue: [dynamic]Effect_Application_Data,
    removal_queue: [dynamic]util.Handle,
    events: [dynamic]Effect_Event,

    // A slice that is sized as the total number of unique effect definitions loaded in.
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
}

effect_manager_create :: proc() -> (effect_manager: ^Effect_Manager) {
    log.infof("Creating effect manager")

    hm.dynamic_init(&global_manager.effects, context.allocator)

    global_manager.application_queue = make([dynamic]Effect_Application_Data)
    global_manager.removal_queue = make([dynamic]util.Handle)

    global_manager.definition_id_map = make(map[string]uint)
    global_manager.instance_id_map = make(map[string]uint)

    global_manager.entity_active_effects = make(Effect_Active_Entity_Effect_Map)
    global_manager.events = make([dynamic]Effect_Event)
    
    effect_manager = &global_manager

    effect_manager_load()

    return
}

effect_manager_destroy :: proc() {
    log.infof("Destroying effect manager")

    pool := &global_manager.effects
    it := hm.iterator_make(pool)
    for e, h in hm.iterate(&it) {
        //effect_destroy(e)
    }

    hm.dynamic_destroy(pool)

    effect_manager_unload()

    delete(global_manager.instance_id_map)
    delete(global_manager.definition_id_map)

    delete(global_manager.application_queue)
    delete(global_manager.removal_queue)

    effect_manager_wipe_entity_active_effect_map()
    delete(global_manager.events)
}

// load definitions and instances
effect_manager_load :: proc() {
    log.infof("Loading effect manager")

    effect_definitions_load()
    effect_instances_load()
}

// unload definitions and instances
effect_manager_unload :: proc() {
    log.infof("Unloading effect manager")

    effect_instances_unload()
    effect_definitions_unload()
}

effect_manager_queue_event :: proc(event_data: Effect_Event) {
    append(&global_manager.events, event_data)
}

effect_manager_get_effect :: proc(handle: util.Handle) -> (state: ^Effect_State, ok: bool) {
    state, ok = hm.get(&global_manager.effects, handle)
    return 
}

effect_manager_queue_apply :: proc(data: Effect_Application_Data, callback_override: ..Effect_Callback_Data_Override) {
    data := data
    // Effects by default use their instance's data
    data.callback_data = data.instance.callback_data

    // Effect data can be overwritten. This is for dynamic purposes.
    // For example, all damage is carried out through the effect system.
    // Player damage is dynamic, and for example, could be boosted by 30% due to an item.
    // Thus, when the player applies damage to another.
    for override in callback_override {
        if override.tag not_in data.callback_data do data.callback_data[override.tag] = nil
        data.callback_data[override.tag] = override.data
    }

    append(&global_manager.application_queue, data)
}

effect_manager_remove :: proc(to_remove: util.Handle) {
    append(&global_manager.removal_queue, to_remove)
}

effect_manager_update :: proc() {
    //update effects
    pool := &global_manager.effects
    it := hm.iterator_make(pool)
    for e, h in hm.iterate(&it) {
        // Find the target entity
        target_entity, entity_ok := entity.entity_get(e.target, e.target_team)

        if !entity_ok {
            // remove the effect
            effect_manager_remove(h)
            effect_manager_wipe_entity_active_effect_key(e.target)

            continue
        }

        should_remove := effect_state_update(e, target_entity)

        if should_remove {
            effect_manager_remove(h)
            effect_manager_remove_entity_active_effect(e.target, e.instance.definition.id, h)
        }
    }

    effect_manager_process_removal_queue()
    effect_manager_process_application_queue()
}

effect_manager_process_removal_queue :: proc() {
    for len(global_manager.removal_queue) > 0 {
        to_remove := pop(&global_manager.removal_queue)

        remove_e, e_ok := hm.get(&global_manager.effects, to_remove)
        if !e_ok do continue

        defer hm.remove(&global_manager.effects, to_remove)

        //effect_destroy(e)
        effect_manager_queue_event(Effect_Event{
            type = .REMOVE, target = remove_e.target,
            target_team = remove_e.target_team,
            definition_id = remove_e.instance.definition.id,
            magnitude = effect_fn_data_get_reaction_magnitude(remove_e.callback_data)
        }) 
    }
}

effect_manager_process_application_queue :: proc() {
    for len(global_manager.application_queue) > 0 {
        //log.errorf("app queue len = %v", len(global_manager.application_queue))
        application_data := pop(&global_manager.application_queue)
        effect_manager_apply_effect(application_data)
    }
}

// This both checks if the effect should apply at all,
// as well as manages the stacking logic of the preexisiting effect.
effect_manager_stack_on_apply :: proc(
    instance: ^Effect_Instance, target: util.Handle
) -> (should_apply: bool) {
    if instance.definition.stack_behaviour == .STACK do return true

    // While this would fail if there is no existing effect, we have already returned in such a case.
    // As such, be very careful not to move the above conditional return to below this block of code.
    
    existing_effect_handle, existing_effect_handle_ok := effect_manager_get_entity_active_effect(target, instance.definition.id)
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
        definition_id = application_data.instance.definition.id,
        magnitude = effect_fn_data_get_reaction_magnitude(application_data.callback_data)
    })

    new_handle, err := hm.add(&global_manager.effects, state)
    if err != .None {
        log.errorf("Failed adding entity to handle map")
        return
    }
    
    effect_manager_add_entity_active_effect(target, {new_handle, instance.definition.id})
}