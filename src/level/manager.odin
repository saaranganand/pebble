package level

import log "core:log"

Level_Manager :: struct {
    definitions: []Level_Definition,
    num_definitions: uint,
    definition_id_map: map[string]uint,

    active_level: ^Level_Definition,
}

@(private)
global_manager: Level_Manager

level_manager_create :: proc() -> (level_manager: ^Level_Manager) {
    log.infof("Creating level manager")

    global_manager.definition_id_map = make(map[string]uint)
    
    level_manager = &global_manager

    level_manager_load()

    return
}

level_manager_destroy :: proc() {
    log.infof("Destroying level manager")

    level_manager_unload()

    delete(global_manager.definition_id_map)
}

// load definitions and instances
level_manager_load :: proc() {
    log.infof("Loading level manager")

    level_definitions_load()
}

// unload definitions and instances
level_manager_unload :: proc() {
    log.infof("Unloading level manager")

    level_definitions_unload()
}