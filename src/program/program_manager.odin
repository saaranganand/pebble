package program

import util "src:util"

import filepath "core:path/filepath"
import strings "core:strings"
import log "core:log"

@(private)
global_program_manager: Program_Manager

Program_Manager :: struct {
    programs: []Program_Definition,
    definition_tag_to_id: map[Program_Definition_Tag]Program_Definition_ID,
    unique_definition_ids: Program_Definition_ID,
}

program_manager_create :: proc() -> ^Program_Manager {
    log.infof("Created program manager")
    return &global_program_manager
}

program_manager_destroy :: proc() {
    for &program in global_program_manager.programs {
        program_definition_unload(&program)
    }
    delete(global_program_manager.programs)
    delete(global_program_manager.definition_tag_to_id)

    log.infof("Destroyed program manager")
}

program_manager_num_definitions :: proc() -> Program_Definition_ID {
    return global_program_manager.unique_definition_ids
}

program_manager_get_definition_by_id :: proc(id: Program_Definition_ID) -> ^Program_Definition {
    if id >= global_program_manager.unique_definition_ids {
        log.errorf("Attempted to get program definition with out of range ID %v", id)
        return nil
    }
    return &global_program_manager.programs[id]
}

program_manager_get_definition :: proc(definition_tag: Program_Definition_Tag) -> ^Program_Definition {
    definition_ID, def_ok := global_program_manager.definition_tag_to_id[definition_tag]
    if !def_ok {
        log.errorf("Attempted to get program definition ID from tag %v that does not have an ID mapping", definition_tag)
        return nil
    }

    return &global_program_manager.programs[definition_ID]
}

PROGRAM_MASTER_FOLDER :: "assets/"
PROGRAM_DATA_EXTENSION :: ".program.json"

// Must load after the weapon and effect managers:
// program definitions resolve weapon tags and effect instance tags to IDs at load.
program_manager_load :: proc() {
    log.infof("Loading program manager")

    global_program_manager.definition_tag_to_id = make(map[Program_Definition_Tag]Program_Definition_ID)

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(PROGRAM_MASTER_FOLDER, PROGRAM_DATA_EXTENSION, &results)

    num_definitions := len(results)
    global_program_manager.unique_definition_ids = cast(Program_Definition_ID) num_definitions
    global_program_manager.programs = make([]Program_Definition, num_definitions)
    definition_id_counter: Program_Definition_ID = 0

    for path in results {
        defer definition_id_counter += 1
        tag := strings.clone(filepath.stem(path))

        global_program_manager.programs[definition_id_counter] = {}
        definition := &global_program_manager.programs[definition_id_counter]
        global_program_manager.definition_tag_to_id[tag] = definition_id_counter

        program_definition_load(definition, path)

        definition.unique_tag = tag
        definition.unique_id = definition_id_counter

        program_definition_resolve(definition)
    }
}
