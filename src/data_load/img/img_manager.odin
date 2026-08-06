package img

import util "src:util"

import filepath "core:path/filepath"
import strings "core:strings"
import log "core:log"

Img_Manager :: map[string]Img_Instance
global_img_manager: Img_Manager

img_manager_create :: proc() {
    log.infof("Creating img manager")

    global_img_manager = make(Img_Manager)

    img_manager_init_data()
}

img_manager_destroy :: proc() {
    log.infof("Destroying img manager")

    for tag, instance in global_img_manager {
        defer delete(tag)
        defer delete(instance.path)

        if instance.state != .LOADED do continue
        img_unload(tag)
    }

    delete(global_img_manager)
}

@(private)
IMG_MASTER_FOLDER :: "assets/"
img_manager_init_data :: proc() {
    log.infof("Initializing img data")

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(IMG_MASTER_FOLDER, ".png", &results)
    util.scrape_files(IMG_MASTER_FOLDER, ".jpg", &results)

    for path in results {
        tag := strings.clone(filepath.stem(path))
        global_img_manager[tag] = {}
        instance := &global_img_manager[tag]
        
        instance.path = strings.clone(path)
        instance.state = .UNLOADED
    }
}