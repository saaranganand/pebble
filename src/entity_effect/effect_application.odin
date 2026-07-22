package effect

import primatives "../sdl_primatives"
import handle "../handle"

import log "core:log"

// The data needed to apply an effect
Effect_Application_Data :: struct {
    instance: ^Effect_Instance,
    callback_data: Effect_Callback_Data,
    source, target: handle.Entity_Handle
}

effect_application_data_from_tag :: proc(
    instance_tag: Effect_Instance_Tag, source, target: handle.Entity_Handle
) -> (data: Effect_Application_Data) {
    data.source = source
    data.target = target

    id, ok := global_effect_manager.instance_tag_to_id[instance_tag]
    if !ok {
        log.errorf("Tried to create effect application data from tag %v that is not in map", instance_tag)
        return
    }

    data.instance = &global_effect_manager.instances[id]

    return
}