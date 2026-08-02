package animation

import util "../../util"

import strings "core:strings"
import log "core:log"
import filepath "core:path/filepath"

Animation_Manager :: map[string]Animation_Instance
global_manager: Animation_Manager


animation_master_create :: proc() {
    log.infof("Creating animation manager")
    global_manager = make(Animation_Manager)

    animation_master_load_data("assets/")
}

animation_master_destroy :: proc() {
    log.infof("Destroying animation manager")

    for tag, instance in global_manager {
        defer delete(tag)

        animation_instance_destroy(tag)
    }

    delete(global_manager)
}

ANIMATION_DATA_EXTENSION :: ".animation.json"
@(private)
animation_master_load_data :: proc(master_folder: string) {
    log.infof("Loading animations")

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(master_folder, ANIMATION_DATA_EXTENSION, &results)
    
    for path in results {
        tag := strings.clone(filepath.stem(path))

        global_manager[tag] = {}
        instance := &global_manager[tag]
        instance.file_path = strings.clone(path)

        animation_instance_load(instance)
    }
}