package entity

import sdl "vendor:sdl3"

import handle "../handle"

Entity_Handle :: handle.Handle(handle.Entity_Tag)

Entity :: struct {
    position: sdl.FPoint,
    move_velocity: sdl.FPoint,
    base_move_speed, move_speed: f32,
    forces: []sdl.FPoint,
    health: f32,

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
    active_effects: []union{Effect_Handle},
}

entity_get_active_effect_by_ID :: proc(entity: ^Entity, ID: Effect_Definition_ID) -> (active: union{Effect_Handle}) {
    return entity.active_effects[ID]
}

entity_add_active_effect_by_ID :: proc(entity: ^Entity, ID: Effect_Definition_ID, effect_handle: Effect_Handle) {
    union_wrapper: union{Effect_Handle} = effect_handle
    entity.active_effects[ID] = union_wrapper
}

entity_remove_active_effect_by_ID :: proc(entity: ^Entity, ID: Effect_Definition_ID) {
    entity.active_effects[ID] = nil
}

Entity_Manager :: struct {
    pool: handle.Pool(handle.Entity_Tag, Entity),
}

entity_get :: proc(manager: ^Entity_Manager, entity_handle: Entity_Handle) -> (entity: ^Entity, ok: bool) {
    entity, ok = handle.pool_get(&manager.pool, entity_handle)
    return 
}