package assets

import sdl "vendor:sdl3"

import strings "core:strings"
import log "core:log"
import fmt "core:fmt"

Data_Tag :: distinct string

// Given a unqiue path in the assets folder, and a desired extension,
// compiles a list of filenames that are to be turned into data tags
data_tag_resursive_grab_and_process_precursors :: proc(unique_path: string, extension: cstring, tags: ^[dynamic]string) {
    // TODO: just adding the default asset folder is lazy, because if we want to load assets from other folders,
    // like mods or even an act-folder-structure like deltarune uses, this is just not the way to do it
    // default value maybe?
    total_path := fmt.caprint(DATA_TAG_DEFAULT_ASSET_FOLDER, unique_path, sep = "")
    defer delete(total_path)

    flags := sdl.GlobFlags{ .CASEINSENSITIVE }

    // Set up the recusrive nature of this proc.
    // We use sdl.globdir to find files in the folder.
    // This method does not search recursively.
    // We must instead check each file in the directory and check if its a directory.
    // While we could save this list of every file in the directory and reuse it by just checking for extensions later,
    // Honestly, thats a huge pain in the ass. I'd have to check for the extension, allocate some space for another
    // list of filenames entirely, os instead, reorganize my whole processing system...
    // I dont want to do that, and instead, all files with matching extensions will be checked twice. :p
    defer {
        num_files: i32
        all_files := sdl.GlobDirectory(total_path, nil, flags, &num_files)
        defer sdl.free(all_files)

        inner_strings := all_files[:num_files]

        for data in inner_strings {
            file_name := cstring(data)
            file_name_str := string(file_name)

            // Skip nested entries — only handle immediate children here
            if strings.contains(file_name_str, "/") {
                continue
            }
                        
            // Here we look for full path strings of subfolders in our original folder.
            // We want these as cstrings (for the get path info SDL function),
            full_path := fmt.caprint(total_path, file_name, sep = "")
            defer delete(full_path)

            // But also as a string, to recursively pass.
            // Small note that, we dont actually want full path, which is why we dont use total path
            // For file access: we want the master folder name (i.e. assets)
            // For recursively creating data tags: we dont want the master folder name
            recursed_path := fmt.aprint(unique_path, file_name, "/", sep = "")
            defer delete(recursed_path)

            info: sdl.PathInfo
            if sdl.GetPathInfo(full_path, &info) && info.type == sdl.PathType.DIRECTORY {
                log.debugf("Found subdirectory in %v: %v", unique_path, recursed_path)
                data_tag_resursive_grab_and_process_precursors(recursed_path, extension, tags)
            }
        }
    }

    data_tag_precursors: [^][^]u8
    num_precursors: i32

    // Grab all matching files
    data_tag_precursors = sdl.GlobDirectory(total_path, extension, flags, &num_precursors)
    defer sdl.free(data_tag_precursors)


    inner_strings_test := data_tag_precursors[:num_precursors]

    // Process precursors into data tags
    data_tag_process_precursors(&data_tag_precursors, num_precursors, unique_path, tags)

    return 
}

// Takes a globbed array of matching asset filenames in a specified subdirectory from sdl.GlobDirectory
// Processes these filenames by adding an identifying prefix, and appends them to a provided tags dynamic array
@(private)
data_tag_process_precursors :: proc(precursors: ^[^][^]u8, num_precursors: i32, tag_path_prefix: string, tags: ^[dynamic]string) {
    inner_strings := precursors[:num_precursors]

    for data in inner_strings {
        cstr := cstring(data)
        // This isnt a clone, but a view into the raw cstring data
        str := string(cstr)

        // This IS a clone, aka allocates new_tag, which means it must be freed eventually.
        new_tag := fmt.aprint(tag_path_prefix, str, sep = "")

        append(tags, new_tag)
    }

    return
}