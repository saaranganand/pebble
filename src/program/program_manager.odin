package program

import assets "../assets"

import strings "core:strings"
import log "core:log"
import mem "core:mem"

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

// Must load after the weapon and effect managers
// program definitions resolve weapon tags and effect instance tags to IDs at load
program_manager_load :: proc() {
    log.infof("Loading program manager")

    global_program_manager.definition_tag_to_id = make(map[Program_Definition_Tag]Program_Definition_ID)

    arena_memory := make([]byte, 1*mem.Megabyte)
    defer delete(arena_memory)

    config_arena: mem.Arena
    mem.arena_init(&config_arena, arena_memory)
    arena_alloc := mem.arena_allocator(&config_arena)

    file_paths := make([dynamic]string)
    defer delete(file_paths)

    pre_path := "data/program/"
    assets.data_tag_resursive_grab_and_process_precursors(pre_path, "*.yaml", &file_paths, "")

    num_definitions := len(file_paths)
    global_program_manager.unique_definition_ids = cast(u32) num_definitions
    global_program_manager.programs = make([]Program_Definition, num_definitions)
    definition_id_counter: Program_Definition_ID = 0

    for path in file_paths {
        program_definition_load(pre_path, path, &definition_id_counter, arena_alloc)
        delete(path)
    }
}
