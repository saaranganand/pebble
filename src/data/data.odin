package data

import sdl "vendor:sdl3"
import ma "vendor:miniaudio"

import strings "core:strings"
import log "core:log"
import fmt "core:fmt"

// Here is the way we load data in our game:
// The asset folder is scraped for all files recursively, with files being categorized by folder.
// For each file spotted, a tag is generated. This tag is a string, and is the name of the file, plus the folder it is in.
// For example, all files in the "img" folder are flagged as image files to load. The file "test.png" is captured, and the tag
// "img/test.png" is generated for the file.
// The tag is stored in its file type's master list, where it is mapped to the type of the file it is for SDL (or other library)
// This works because SDL uses pointers to types. For example, when you load in a texture, it does not give you the texture data,
// but the pointer to the texture that is loaded in its backend.
// Thus, no space is being wasted here. The pointers all start empty, but then the program eventually loads in the file using the tag.
//

Data_Tag :: distinct string

global_manager: ^Data_Manager

Data_Manager :: struct {
    audio_master: Audio_Master,

    img_master: map[Data_Tag]^sdl.Texture,
}

global_manager_create :: proc() {
    log.infof("Creating data manager")
    global_manager = new(Data_Manager)

    audio_create(&global_manager.audio_master)
    //img_create()
    //font_create()
    //data_create()

    audio_scrape_audio_entries()

    return
}

global_manager_destroy :: proc() {
    log.infof("Destroying data manager")

    audio_destroy(&global_manager.audio_master)
    //img_destroy()
    //font_destroy()
    //data_destroy()

    free(global_manager)
}