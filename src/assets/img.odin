package assets

import ttf "vendor:sdl3/ttf"
import sdl "vendor:sdl3"
import img "vendor:sdl3/image"

import primatives "../sdl_primatives"

import strings "core:strings"
import math "core:math"
import log "core:log"
import fmt "core:fmt"

Img_Instance :: struct {
    texture: ^sdl.Texture,
    path_prefix: string,
    state: Data_Load_State,
}

Img_Master :: map[Data_Tag]Img_Instance

@(private)
img_master_create :: proc(master: ^Img_Master) {
    log.infof("Creating img data master")

    master^ = make(map[Data_Tag]Img_Instance)
}

@(private)
img_master_destroy :: proc(master: ^Img_Master) {
    for tag, instance in master {
        defer delete(cast(string) tag)

        if instance.state != .LOADED do continue

        img_unload(tag)
    }

    log.infof("Destroying img data master")
    delete(master^)
}

// TODO: find some way to get multiple basic paths in here, to allow for mods to add their own asset folders to the load path
@(private)
img_master_scrape_data :: proc(master: ^Img_Master) {
    log.infof("Creating data tags for imgs")

    tags := make([dynamic]string)
    defer delete(tags)
    data_tag_resursive_grab_and_process_precursors("img/", "*.png", &tags)
    data_tag_resursive_grab_and_process_precursors("img/", "*.jpg", &tags)
    img_master_create_instances_from_scraped_tags(master, tags)
}

@(private)
img_master_create_instances_from_scraped_tags :: proc(master: ^Img_Master, tags: [dynamic]string) {
    for tag in tags {
        defer delete(tag)
        copied_tag := strings.clone(tag)

        master[cast(Data_Tag) copied_tag] = {}
        instance := &master[cast(Data_Tag) copied_tag]

        instance.path_prefix = DATA_TAG_DEFAULT_ASSET_FOLDER
        instance.state = .UNLOADED        
    }
}

img_load :: proc(tag: Data_Tag) {
    instance, ok := &global_manager.img_master[tag]

    if !ok {
        log.errorf("Tried to load non-existent img with tag %v.", tag)
        return
    }

    if instance.state == .LOADED {
        log.errorf("Tried to load already loaded img with tag %v.", tag)
        return
    }

    file_path := fmt.caprint(instance.path_prefix, tag, sep = "")
    defer delete(file_path)

    instance.texture = img.LoadTexture(primatives.global_renderer, file_path)
    sdl.SetTextureBlendMode(instance.texture, {.BLEND})
    sdl.SetTextureScaleMode(instance.texture, .PIXELART)

    instance.state = .LOADED

    log.infof("Loaded img with tag %v.", tag)
}

img_unload :: proc(tag: Data_Tag) {
    instance, ok := img_get_instance(tag)
    if !ok do return

    sdl.DestroyTexture(instance.texture)
    instance.state = .UNLOADED

    log.infof("Destroyed texture with tag %v", tag)
}

@(private)
img_get_instance :: proc(tag: Data_Tag) -> (instance: ^Img_Instance, ok: bool) {
    instance, ok = &global_manager.img_master[tag]

    if !ok {
        log.errorf("Tried to get non-existent img with tag %v.", tag)
        return nil, false
    }

    if instance.state != .LOADED {
        log.errorf("Tried to get unloaded img with tag %v.", tag)
        return nil, false
    }

    return
}

img_draw :: proc(
    img_tag: Data_Tag, dest: ^sdl.FRect, src: ^sdl.FRect = nil, angle: f64 = 0, flip_mode: sdl.FlipMode = .NONE, center: ^sdl.FPoint = nil
) {
    instance, ok := img_get_instance(img_tag)
    if !ok do return

    sdl.RenderTextureRotated(primatives.global_renderer, instance.texture, src, dest, angle * math.DEG_PER_RAD, center, flip_mode)
}