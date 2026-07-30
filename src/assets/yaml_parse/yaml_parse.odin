package yaml_parse

import yaml "../../../libs/odin-yaml"

import log "core:log"
import mem "core:mem"
import runtime "base:runtime"
import reflect "core:reflect"
import intrinsincs "base:intrinsics"

Yaml_Read_Argument :: struct {
    yaml_key: string,
    target_type: typeid,
    target: ^any,
}

yaml_read :: proc(yaml_path: string, read_args: []Yaml_Read_Argument) {
    // arena allocator for odin-yaml
    arena_memory := make([]byte, 1*mem.Megabyte)
    defer delete(arena_memory)

    config_arena: mem.Arena
    mem.arena_init(&config_arena, arena_memory)
    arena_alloc := mem.arena_allocator(&config_arena)

    data, err := yaml.decode_from_file(yaml_path, arena_alloc)
    if err != nil {
        log.errorf("YAML parser could not find path %v", yaml_path)
        return
    }

    data_map, map_ok := data.(yaml.Mapping)
    if !map_ok do log.panicf("YAML syntax error in path %v", yaml_path)

    yaml_parse_map(yaml_path, data_map, read_args)
}

yaml_parse_value :: proc(yaml_path: string, data: yaml.Value, arg: Yaml_Read_Argument) {
    read_string, is_string := data.(string)
    read_bool,   is_bool   := data.(bool)
    read_int,    is_int    := data.(i64)
    read_float,  is_float  := data.(f64)
    read_map,    is_map    := data.(yaml.Mapping)
    read_seq,    is_seq    := data.(yaml.Sequence)

    // String case
    target_is_string := arg.target_type == typeid_of(string)
    if is_string && target_is_string {
        (^string)(arg.target)^ = read_string
        return
    }

    // Bool case
    target_is_bool := arg.target_type == typeid_of(bool)
    if is_bool && target_is_bool {
        (^bool)(arg.target)^ = read_bool
        return
    }

    // Numeric cases
    read_numeric: f64
    if is_float do read_numeric = read_float
    else if is_int do read_numeric = f64(read_int)

    if is_int || is_float {
        switch arg.target_type {
        case typeid_of(int ):
            (^int)(arg.target)^ = int(read_numeric)
        case typeid_of(i32 ):
            (^i32)(arg.target)^ = i32(read_numeric)
        case typeid_of(i64 ):
            (^i64)(arg.target)^ = i64(read_numeric)
        case typeid_of(uint):
            (^uint)(arg.target)^ = uint(read_numeric)
        case typeid_of(u32 ):
            (^u32)(arg.target)^ = u32(read_numeric)
        case typeid_of(u64 ):
            (^u64)(arg.target)^ = u64(read_numeric)
        case typeid_of(f32 ):
            (^f32)(arg.target)^ = f32(read_numeric)
        case typeid_of(f64 ):
            (^f64)(arg.target)^ = f64(read_numeric)
        case:
            log.panicf("YAML parser tried to read value to target of type %v which is not supported yet. Implement ASAP", arg.target_type)
        }
        return
    }
    
    // Map case
    if is_map {
        // interpret target as a slice of read_args
        new_args := arg.target^.([]Yaml_Read_Argument)
        yaml_parse_map(yaml_path, read_map, new_args)
        return
    }
    
    // Seq case
    if is_seq {
        // interpret target as a slice of read_args
        seq_args := arg.target^.([]Yaml_Read_Argument)

        read_seq_num := len(read_seq)
        arg_seq_num  := len(seq_args)
        if read_seq_num != arg_seq_num {
            log.panicf("YAML parser read key %v in path %v: key sequence argument number and provided argument number do not match", arg.yaml_key, yaml_path)
        }

        for i in 0..<len(read_seq) {
            yaml_parse_value(yaml_path, read_seq[i], seq_args[i])
        }
        return
    }

    log.panicf("YAML parser read key %v in path %v: key is not of type int, float, bool, string, map, or sequence", arg.yaml_key, yaml_path)
}

yaml_parse_map :: proc(yaml_path: string, data_map: yaml.Mapping, read_args: []Yaml_Read_Argument) {
    for arg in read_args {
        value, value_ok := data_map[arg.yaml_key]
        if !value_ok do log.panicf("YAML parser expected key %v in path %v: not found", arg.yaml_key, yaml_path)

        yaml_parse_value(yaml_path, value, arg)
    }
}

yaml_parse_seq :: proc() {

}

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