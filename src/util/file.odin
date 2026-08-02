package util

import os "core:os"
import strings "core:strings"

Data_Load_State :: enum {
    UNLOADED,
    LOADED,
    FAILED,
}

// strings that have null bytes before the end cause problems
// so we use this to shorten them
// we take raw char data as an input,
// since this only really happens when reading fixed length strings from files
string_from_char_data :: proc(data: []u8) -> string {
    ret: string

    valid_string_bytes := 0
    for b in data { if b != 0x0 { valid_string_bytes += 1 } }

    ret = string(data[:valid_string_bytes])

    return ret
}

scrape_files :: proc(master_folder, extension: string, results: ^[dynamic]string) {
    entries, read_err := os.read_directory_by_path(master_folder, -1, context.allocator)
	if read_err != os.ERROR_NONE do return
	defer os.file_info_slice_delete(entries, context.allocator)

    for entry in entries {
		if entry.type == .Directory do scrape_files(entry.fullpath, extension, results)
			
		else if strings.has_suffix(entry.fullpath, extension) do append(results, strings.clone(entry.fullpath))
	}
}