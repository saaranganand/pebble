package yaml_parse

import yaml "../../../libs/odin-yaml"

import log "core:log"

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