package item_api

import util "src:util"

import os "core:os"
import log "core:log"
import fmt "core:fmt"
import strings "core:strings"
import json "core:encoding/json"

implementation_load :: proc(
    $Implement_Type: typeid, master_folder, implement_extension: string
) -> (master_list: []Implement_Type, tag_to_id_list: map[string]uint) {
    log.infof("Loading item API implementation for type %v", typeid_of(Implement_Type))

    full_extension := fmt.aprint(implement_extension, ".json", sep = "")
    defer delete(full_extension)

    item_results := make([dynamic]string)

    util.scrape_files(master_folder, full_extension, &item_results)

    num_items := len(item_results)
    master_list = make([]Implement_Type, num_items)
    tag_to_id_list = make(map[string]uint)

    // Load in each file
    // Populates master category list as well
    i: uint = 0
    for result in item_results {
        defer i += 1
        master_list[i] = implementation_item_load(Implement_Type, result)
        tag_to_id_list[master_list[i].api_tag] = i

        delete(result)
    }
    delete(item_results)

    return
}

implementation_item_load :: proc($Implement_Type: typeid, path: string) -> (item: Implement_Type) {
    data, err := os.read_entire_file(path, context.allocator)
	if err != os.General_Error.None {
        log.errorf("Failed to read file %v: %v", path, err)
        return
    }
	defer delete(data)

	json_err := json.unmarshal(data, &item, spec = .MJSON)
	if json_err != nil {
		log.errorf("Failed to parse json file %v of item implementation type %v: %v", path, typeid_of(Implement_Type), json_err)
		return
	}

    return
}