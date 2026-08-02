package img

import util "../../util"

import filepath "core:path/filepath"
import strings "core:strings"
import log "core:log"

Img_Manager :: map[string]Img_Instance
global_img_manager: Img_Manager

img_master_create :: proc() {
    log.infof("Creating img manager")

    global_img_manager = make(Img_Manager)

    img_master_init_data("assets/")
}

img_master_destroy :: proc() {
    log.infof("Destroying img manager")

    for tag, instance in global_img_manager {
        if instance.state != .LOADED do continue
        img_unload(tag)

        delete(tag)
        delete(instance.path)
    }

    delete(global_img_manager)
}

// TODO: find some way to get multiple basic paths in here, to allow for mods to add their own asset folders to the load path
@(private)
img_master_init_data :: proc(master_folder: string) {
    log.infof("Initializing img data")

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(master_folder, ".png", &results)
    util.scrape_files(master_folder, ".jpg", &results)

    for path in results {
        //
        tag := strings.clone(filepath.stem(path))
        global_img_manager[tag] = {}
        instance := &global_img_manager[tag]
        
        instance.path = strings.clone(path)
        instance.state = .UNLOADED
    }
}