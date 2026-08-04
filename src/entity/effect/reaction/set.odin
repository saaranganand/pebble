package reaction

import json "core:encoding/json"
import os "core:os"
import log "core:log"

// All reaction sets have at least a default data object.
// For each necessary combination of team and category, a tag is created through the enum names in a comma seperated string
Reaction_Set :: struct {
    definition_tag: string,
    default_reaction_data: Maybe(Reaction_Data),
    reaction_data_map: map[string]Reaction_Data,
}

reaction_set_create :: proc(set: ^Reaction_Set, default_data: Maybe(Reaction_Data) = nil) {
    set.default_reaction_data = default_data

    set.reaction_data_map = make(map[string]Reaction_Data)
}

reaction_set_destroy :: proc(set: ^Reaction_Set) {
    for key, &data in set.reaction_data_map {
        delete(key)
        reaction_data_destroy(&data)
    }

    default_reaction_data, ok := &set.default_reaction_data.(Reaction_Data)
    if ok do reaction_data_destroy(default_reaction_data)

    delete(set.reaction_data_map)
    delete(set.definition_tag)
}

reaction_set_load :: proc(set: ^Reaction_Set, path: string) {
    data, err := os.read_entire_file(path, context.allocator)
	if err != os.General_Error.None {
        log.errorf("Failed to read effect reaction file %v: %v", path, err)
        return
    }
	defer delete(data)

	json_err := json.unmarshal(data, set, spec = .MJSON)
	if json_err != nil {
		log.errorf("Failed to parse effect reaction json file %v: %v", path, json_err)
		return
	}
}