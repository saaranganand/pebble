package item_api

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

    scrape_files(master_folder, full_extension, &item_results)

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

@(private)
scrape_files :: proc(master_folder, extension: string, results: ^[dynamic]string) {
    entries, read_err := os.read_directory_by_path(master_folder, -1, context.allocator)
	if read_err != os.ERROR_NONE do return
	defer os.file_info_slice_delete(entries, context.allocator)

    for entry in entries {
		if entry.type == .Directory do scrape_files(entry.fullpath, extension, results)
			
		else if strings.has_suffix(entry.fullpath, extension) do append(results, strings.clone(entry.fullpath))
	}
}