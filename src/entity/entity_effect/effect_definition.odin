package effect

import handle "src:handle"
import util "src:util"

import filepath "core:path/filepath"
import json "core:encoding/json"
import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import os "core:os"

Effect_Handle :: handle.Effect_Handle

// Defines what happens when an effect is attempted to be applied to an entity that already has said effect.
// NONE:    the effect is not applied
// REFRESH: the effect is applied, and the exisiting effect is removed. If the effect is pulse, then an extra pulse occurs.
// STACK:   the effect is applied
// EXTEND:  the effect is applied with its duration absorbing the remaining time left of the existing effect. The exisiting effect is removed.
//          if the effect is pulse, then the new effect's max applications absorbs the remaining applications of the exisiting effect.
Stack_Behaviour :: enum { NONE, REFRESH, STACK, EXTEND }

Effect_Type :: enum { PULSE, CONTINUOUS, SINGLE }

Effect_Definition_Tag :: string
Effect_Definition_ID :: uint

Effect_Definition :: struct {
    unique_id: uint,
    unique_tag: string,

    callback: Effect_Callback,
    // Name of the global Lua function to call. Only read when callback is .LUA.
    lua_callback: string,
    stack_behaviour: Stack_Behaviour,
    type: Effect_Type,
}

EFFECT_DEFINITION_MASTER_FOLDER :: "assets/"
EFFECT_DEFINITION_DATA_EXTENSION :: ".effect.definition.json"
@(private)
effect_definitions_load :: proc() {
    log.infof("Loading effect definitions")

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(EFFECT_DEFINITION_MASTER_FOLDER, EFFECT_DEFINITION_DATA_EXTENSION, &results)

    num_definitions := len(results)
    global_effect_manager.unique_definition_ids = cast(uint) num_definitions
    global_effect_manager.definitions = make([]Effect_Definition, num_definitions)
    definition_id_counter: uint = 0
    
    for path in results {
        defer definition_id_counter += 1
        tag := strings.clone(filepath.stem(path))

        global_effect_manager.definitions[definition_id_counter] = {}
        definition := &global_effect_manager.definitions[definition_id_counter]
        global_effect_manager.definition_tag_to_id[tag] = definition_id_counter

        effect_definition_load(definition, path)
        
        definition.unique_tag = tag
        definition.unique_id = definition_id_counter
    }
}

@(private)
effect_definition_load :: proc(definition: ^Effect_Definition, path: string) {
    data, err := os.read_entire_file(path, context.allocator)
	if err != os.General_Error.None {
        log.errorf("Failed to read effect definition file %v: %v", path, err)
        return
    }
	defer delete(data)

	json_err := json.unmarshal(data, definition, spec = .MJSON)
	if json_err != nil {
		log.errorf("Failed to parse effect definition json file %v: %v", path, json_err)
		return
	}
}

@(private)
effect_definitions_unload :: proc() {
    log.infof("Unloading effect definitions")

    for &definition in &global_effect_manager.definitions {
        delete(definition.unique_tag)
        delete(definition.lua_callback)
    }
    defer delete(global_effect_manager.definitions)
}