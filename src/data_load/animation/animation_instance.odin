package animation

import os "core:os"
import log "core:log"
import json "core:encoding/json"

Animation_Instance :: struct {
    source_img_tag, file_path: string,
    animations: map[string]Animation_Data,
}

@(private)
animation_instance_get :: proc(tag: string) -> (instance: ^Animation_Instance, ok: bool){
    instance, ok = &global_manager[tag]

    if !ok {
        log.errorf("Tried to get non-existent animation instance with tag %v", tag)
        return nil, false
    }

    return
}

@(private)
animation_instance_load :: proc(instance: ^Animation_Instance) {
    data, err := os.read_entire_file(instance.file_path, context.allocator)
	if err != os.General_Error.None {
        log.errorf("Failed to read animation file %v: %v", instance.file_path, err)
        return
    }
	defer delete(data)

	json_err := json.unmarshal(data, instance, spec = .MJSON)
	if json_err != nil {
		log.errorf("Failed to parse animation json file %v: %v", instance.file_path, json_err)
		return
	}
}

@(private)
animation_instance_destroy :: proc(tag: string) {
    instance, ok := animation_instance_get(tag)
    if !ok do return

    delete(instance.source_img_tag)
    delete(instance.file_path)

    for anim, &data in instance.animations {
        defer delete(anim)
        animation_data_destroy(&data)
    }

    delete(instance.animations)
}