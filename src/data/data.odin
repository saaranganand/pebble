package data

import sdl "vendor:sdl3"

import strings "core:strings"
import log "core:log"
import fmt "core:fmt"

// Here is more or less the way we load data in our game:
// The asset folder is scraped for all files recursively, with files being categorized by folder.
// For each file spotted, a tag is generated. This tag is a string, and is the name of the file, plus the folder it is in.
// For example, all files in the "img" folder are flagged as image files to load. The file "test.png" is captured, and the tag
// "img/test.png" is generated for the file.
// The tag is stored in its file type's master list, where it is mapped to the type of the file it is for SDL (or other library)
// This works because SDL uses pointers to types. For example, when you load in a texture, it does not give you the texture data,
// but the pointer to the texture that is loaded in its backend.
// Thus, no space is being wasted here. The pointers all start empty, but then the program eventually loads in the file using the tag.
global_manager: ^Data_Manager

Data_Manager :: struct {
    audio_master: Audio_Master,
    font_master: Font_Master,
    img_master: Img_Master,
    animation_master: Animation_Master,
}

// TODO: Add loading state to allow loading daata asynchronously with threads
Data_Load_State :: enum {
    UNLOADED,
    LOADED,
    FAILED,
}

global_manager_create :: proc() {
    log.infof("Creating data manager")
    global_manager = new(Data_Manager)

    audio_master_create(&global_manager.audio_master)
    audio_master_scrape_data()

    font_master_create(&global_manager.font_master)
    font_master_scrape_data(&global_manager.font_master)

    img_master_create(&global_manager.img_master)
    img_master_scrape_data(&global_manager.img_master)

    animation_master_create(&global_manager.animation_master)
    animation_master_scrape_data(&global_manager.animation_master)

    //data_create()

    return
}

global_manager_destroy :: proc() {
    log.infof("Destroying data manager")

    audio_master_destroy(&global_manager.audio_master)
    font_master_destroy(&global_manager.font_master)
    img_master_destroy(&global_manager.img_master)
    animation_master_destroy(&global_manager.animation_master)
    //data_destroy()

    free(global_manager)
}