package effect

import handle "src:handle"
import entity "src:entity"
import util "src:util"

import log "core:log"

Active_Effect_Data :: struct {
    handle: Effect_Handle,
    ID: Effect_Definition_ID
}
Effect_Active_Entity_Effect_Map :: map[util.Handle][dynamic]Active_Effect_Data

effect_manager_add_entity_active_effect :: proc(target: util.Handle, effect_data: Active_Effect_Data) {
    _, ok := &global_effect_manager.entity_active_effects[target]
    if !ok do global_effect_manager.entity_active_effects[target] = make([dynamic]Active_Effect_Data)

    append(&global_effect_manager.entity_active_effects[target], effect_data)
}

effect_manager_get_entity_active_effect :: proc(
    target: util.Handle, effect_ID: Effect_Definition_ID
) -> (handle: Effect_Handle, ok: bool){
    active_effects, active_effects_ok := &global_effect_manager.entity_active_effects[target]
    if !active_effects_ok do return {}, false

    for effect in active_effects {
        if effect.ID != effect_ID do continue
        return effect.handle, true
    }
    return {}, false
}

effect_manager_remove_entity_active_effect :: proc(
    target: util.Handle, effect_ID: Effect_Definition_ID, effect_handle: Effect_Handle
) {
    active_effects, ok := &global_effect_manager.entity_active_effects[target]
    if !ok {
        log.errorf(
            "Tried to remove active entity effect with definition ID %v from active entity effect list that does not exist for entity with handle %v",
            effect_ID, target
        )
        return
    }

    i := 0
    removed_effect := false
    for effect in active_effects {
        defer i += 1
        if effect.ID != effect_ID || effect.handle != effect_handle do continue
        unordered_remove(active_effects, i)
        removed_effect = true
        break
    }

    if !removed_effect do log.errorf("Tried to remove non-existing expected active effect from entity %v", target)

    if len(active_effects) == 0 do effect_manager_wipe_entity_active_effect_key(target)
}

effect_manager_wipe_entity_active_effect_key :: proc(target: util.Handle) {
    delete(global_effect_manager.entity_active_effects[target])
    delete_key(&global_effect_manager.entity_active_effects, target)
}

effect_manager_wipe_entity_active_effect_map :: proc() {
    for key, value in global_effect_manager.entity_active_effects {
        delete(value)
    }
    delete(global_effect_manager.entity_active_effects)
}