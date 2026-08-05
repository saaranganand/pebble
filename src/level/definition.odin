package level

import util "src:util"

import filepath "core:path/filepath"
import json "core:encoding/json"
import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import os "core:os"

Level_Definition :: struct {
    id: uint,
    tag: string,
}

LEVEL_DEFINITION_MASTER_FOLDER :: "assets/"
LEVEL_DEFINITION_DATA_EXTENSION :: ".level.json"
@(private)
level_definitions_load :: proc() {
    log.infof("Loading level definitions")

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(LEVEL_DEFINITION_MASTER_FOLDER, LEVEL_DEFINITION_DATA_EXTENSION, &results)

    num_definitions := len(results)
    global_manager.num_definitions = cast(uint) num_definitions
    global_manager.definitions = make([]Level_Definition, num_definitions)
    definition_id_counter: uint = 0
    
    for path in results {
        defer definition_id_counter += 1
        tag := strings.clone(filepath.stem(path))

        global_manager.definitions[definition_id_counter] = {}
        definition := &global_manager.definitions[definition_id_counter]
        global_manager.definition_id_map[tag] = definition_id_counter

        level_definition_load(definition, path)
        
        definition.tag = tag
        definition.id = definition_id_counter
    }
}

@(private)
level_definition_load :: proc(definition: ^Level_Definition, path: string) {
    data, err := os.read_entire_file(path, context.allocator)
	if err != os.General_Error.None {
        log.errorf("Failed to read level definition file %v: %v", path, err)
        return
    }
	defer delete(data)

	json_err := json.unmarshal(data, definition, spec = .MJSON)
	if json_err != nil {
		log.errorf("Failed to parse level definition json file %v: %v", path, json_err)
		return
	}
}

@(private)
level_definitions_unload :: proc() {
    log.infof("Unloading level definitions")

    for &definition in &global_manager.definitions {
        delete(definition.tag)
    }
    defer delete(global_manager.definitions)
}