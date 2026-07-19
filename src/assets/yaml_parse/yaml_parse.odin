package yaml_parse

import yaml "../../../libs/odin-yaml"

import runtime "base:runtime"
import log "core:log"
import fmt "core:fmt"

// This function really does not care if your trying to use it incorrectly.
// Please be advised that this function is not liable for all missed values, wrong types, missed connections, or accidental death.
read_value_from_map :: proc(ymap: yaml.Mapping, ykey: string, $T: typeid, default: T) -> (data: T) {
    data = default
    
    value, ok := ymap[ykey]
    // This is not an error, this just means the data doesnt have it and should use the default value
    // Basically, the data being read here is going to be unused.
    if !ok do return

    #partial switch v in value {
    case T:
        data = cast(T) v
    }

    return
}

get_yaml_mapping :: proc(file_path: string, arena_allocator: runtime.Allocator) -> (data_map: yaml.Mapping, map_ok: bool) {
    data, err := yaml.decode_from_file(file_path, arena_allocator)
    if err != nil {
        log.errorf("yaml parser error in loading file %v: %v", file_path, err)
        return nil, false
    }

    data_map, map_ok = data.(yaml.Mapping)
    if !map_ok {
        log.errorf("Error in casting loaded yaml data from %v to a yaml map.", file_path)
        return nil, false
    }

    return
}