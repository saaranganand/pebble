package effect

import util "src:util"

import filepath "core:path/filepath"
import json "core:encoding/json"
import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import os "core:os"

Effect_Instance_Tag :: string
Effect_Instance_ID :: uint

Effect_Instance :: struct {
    definition: ^Effect_Definition,
    definition_tag: string,

    tag: Effect_Instance_Tag,
    id: Effect_Instance_ID,

    duration: f32,
    interval: f32,

    callback_data: Effect_Callback_Data,
}


EFFECT_INSTANCE_MASTER_FOLDER :: "assets/"
EFFECT_INSTANCE_DATA_EXTENSION :: ".effect.instance.json"
@(private)
effect_instances_load :: proc() {
    log.infof("Loading effect instances")

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(EFFECT_INSTANCE_MASTER_FOLDER, EFFECT_INSTANCE_DATA_EXTENSION, &results)

    num_instances := len(results)
    global_effect_manager.num_instances = cast(uint) num_instances
    global_effect_manager.instances = make([]Effect_Instance, num_instances)
    instance_id_counter: uint = 0
    
    for path in results {
        defer instance_id_counter += 1
        tag := strings.clone(filepath.stem(path))

        global_effect_manager.instances[instance_id_counter] = {}
        instance := &global_effect_manager.instances[instance_id_counter]
        global_effect_manager.instance_id_map[tag] = instance_id_counter

        effect_instance_load(instance, path)
        
        instance.tag = tag
        instance.id = instance_id_counter

        definition_id := global_effect_manager.definition_id_map[instance.definition_tag]
        instance.definition = &global_effect_manager.definitions[definition_id]
    }
}

@(private)
effect_instance_load :: proc(instance: ^Effect_Instance, path: string) {
    data, err := os.read_entire_file(path, context.allocator)
	if err != os.General_Error.None {
        log.errorf("Failed to read effect instance file %v: %v", path, err)
        return
    }
	defer delete(data)

	json_err := json.unmarshal(data, instance, spec = .MJSON)
	if json_err != nil {
		log.errorf("Failed to parse effect instance json file %v: %v", path, json_err)
		return
	}
}

effect_instances_unload :: proc() {
    log.infof("Unloading effect instances")

    for instance in global_effect_manager.instances {
        delete(instance.tag)
        delete(instance.definition_tag)

        for key, value in instance.callback_data {
            delete(key)
            #partial switch v in value {
            case string:
                delete(v)
            }
        }
        delete(instance.callback_data)
    }
    delete(global_effect_manager.instances)
}