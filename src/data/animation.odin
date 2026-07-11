package data

import sdl "vendor:sdl3"
import yaml "../../libs/odin-yaml"

import primatives "../sdl_primatives"
import yaml_parse "yaml_parse"

import strings "core:strings"
import math "core:math"
import log "core:log"
import fmt "core:fmt"
import mem "core:mem"

Animation_Tag :: distinct string

Animation_Master :: map[Data_Tag]Animation_Instance

@(private)
animation_master_create :: proc(master: ^Animation_Master) {
    log.infof("Creating animation data master")
    master^ = make(map[Data_Tag]Animation_Instance)
}

@(private)
animation_master_destroy :: proc(master: ^Animation_Master) {
    log.infof("Destroying animation data master")

    for tag, instance in master {
        defer delete(cast(string) tag)

        if instance.state != .LOADED do continue

        animation_instance_destroy(tag)
    }

    delete(master^)
}

// TODO: find some way to get multiple basic paths in here, to allow for mods to add their own asset folders to the load path
@(private)
animation_master_scrape_data :: proc(master: ^Animation_Master) {
    log.infof("Creating data tags for animations")

    tags := make([dynamic]string)
    defer delete(tags)
    data_tag_resursive_grab_and_process_precursors("animations/", "*.yaml", &tags)
    animation_master_create_instances_from_scraped_tags(master, tags)
}

@(private)
animation_master_create_instances_from_scraped_tags :: proc(master: ^Animation_Master, tags: [dynamic]string) {
    for tag in tags {
        defer delete(tag)
        copied_tag := strings.clone(tag)
        
        master[cast(Data_Tag) copied_tag] = {}
        instance := &master[cast(Data_Tag) copied_tag]

        // TODO: use an actual path prefix instead of the default one
        instance.path_prefix = DATA_TAG_DEFAULT_ASSET_FOLDER
        instance.state = .UNLOADED
        instance.animations = make(map[Animation_Tag]Animation_Data)
    }
}

Animation_Instance :: struct {
    source_img_tag: Data_Tag,
    path_prefix: string,
    state: Data_Load_State,
    animations: map[Animation_Tag]Animation_Data,
}

animation_instance_get :: proc(tag: Data_Tag) -> (instance: ^Animation_Instance, ok: bool){
    instance, ok = &global_manager.animation_master[tag]

    if !ok {
        log.errorf("Tried to get non-existent animation instance with tag %v.", tag)
        return nil, false
    }

    if instance.state != .LOADED {
        log.errorf("Tried to get unloaded animation instance with tag %v.", tag)
        return nil, false
    }

    return
}

animation_instance_destroy :: proc(tag: Data_Tag) {
    instance, ok := animation_instance_get(tag)
    if !ok do return

    log.infof("Destroying animation instance with tag %v", tag)

    delete(cast(string) instance.source_img_tag)

    for anim, &data in instance.animations {
        defer delete(cast(string) anim)

        log.debugf("Destroying animation %v of instance %v", anim, tag)
        animation_data_destroy(&data)
    }

    delete(instance.animations)
}

// TODO: so, the way this works is that we create our memory arena and load the actual yaml file.
// I think it would be reasonable to always load text data (yaml files) -- as in,
// while we can choose to strategically load and unload, for example, image data for when its needed
// text data could be reasonably loaded in 24/7.
// If this is the case, then we can do a great optimization: instead of creating an arena for each and every
// time we want to load a yaml file, we just load them all permanently with a single arena all at once.
animation_instance_load :: proc(tag: Data_Tag) {
    instance, ok := &global_manager.animation_master[tag]

    if !ok {
        log.errorf("Tried to load non-existent animation instance with tag %v.", tag)
        return
    }

    if instance.state == .LOADED {
        log.errorf("Tried to load already loaded animation instance with tag %v.", tag)
        return 
    }

    // Lib yaml binding requires use of arena allocator (good one)
    arena_memory := make([]byte, 1*mem.Megabyte)
    defer delete(arena_memory)

    // To be clear, only when explicitly using this new allocator is it used.
    // It is not replacing the context allocator for this scope, since we need to allocate things here
    // that will last until possibly shutdown.
    config_arena: mem.Arena
    mem.arena_init(&config_arena, arena_memory)
    arena_alloc := mem.arena_allocator(&config_arena)

    file_path := fmt.aprint(instance.path_prefix, tag, sep = "")
    defer delete(file_path)

    data, err := yaml.decode_from_file(file_path, arena_alloc)
    if err != nil {
        log.errorf("yaml parser error in loading animation data with tag %v", tag)
        return
    }

    data_map, map_ok := data.(yaml.Mapping)
    if !map_ok {
        log.errorf("Error in casting animation data of tag %v to a yaml map.", tag)
        return
    }

    instance.state = .LOADED

    read_ok: bool
    read_value: yaml.Value

    read_value, read_ok = data_map["img_tag"]

    instance.source_img_tag = cast(Data_Tag) strings.clone(yaml_parse.read_value_from_map(data_map, "img_tag", string, default = ""))

    instance.animations = make(map[Animation_Tag]Animation_Data)

    animation_list := yaml_parse.read_value_from_map(data_map, "animations", yaml.Mapping, default = nil)
    for name, _ in animation_list {
        tag := cast(Animation_Tag) strings.clone(name)
        animation_data := yaml_parse.read_value_from_map(animation_list, name, yaml.Mapping, default = nil)

        read_fps := yaml_parse.read_value_from_map(animation_data, "fps", f64, default = 1)
        read_looping := yaml_parse.read_value_from_map(animation_data, "looping", bool, default = false)
        read_scale := yaml_parse.read_value_from_map(animation_data, "scale", f64, default = 1)
        read_frame_data := yaml_parse.read_value_from_map(animation_data, "frames", yaml.Sequence, default = nil)

        instance.animations[tag] = animation_data_create(cast(f32) read_fps, read_looping, cast(f32) read_scale, read_frame_data)
    }
}

Animation_Data :: struct {
    fps: f32,
    looping: bool,
    scale: f32,
    frames: []Animation_Frame,
}

animation_data_create :: proc(fps: f32, looping: bool, scale: f32, frame_data: yaml.Sequence) -> (data: Animation_Data) {
    data.fps = fps
    data.looping = looping
    data.scale = scale

    num_frames := len(frame_data)

    data.frames = make([]Animation_Frame, num_frames)
    for i in 0..<num_frames {
        // read source, hang frames, and dest scale here to pass through
        frame_map := frame_data[i].(yaml.Mapping)
        data.frames[i] = animation_frame_create(frame_map)
    }

    return
}

animation_data_destroy :: proc(data: ^Animation_Data) {
    delete(data.frames)
}

Animation_Frame :: struct {
    source: sdl.FRect,
    hang_frames: int,
    dest_scale: [2]f32,
}

animation_frame_create :: proc(frame_map: yaml.Mapping) -> (frame: Animation_Frame) {
    source_map := yaml_parse.read_value_from_map(frame_map, "source", yaml.Mapping, default = nil)
    frame.source = sdl.FRect{
        x = cast(f32) yaml_parse.read_value_from_map(source_map, "x", f64, default = 0.0),
        y = cast(f32) yaml_parse.read_value_from_map(source_map, "y", f64, default = 0.0),
        w = cast(f32) yaml_parse.read_value_from_map(source_map, "w", f64, default = 0.0),
        h = cast(f32) yaml_parse.read_value_from_map(source_map, "h", f64, default = 0.0),
    }

    frame.hang_frames = cast(int) yaml_parse.read_value_from_map(frame_map, "hang_frames", i64, 1)

    scale_sequence := yaml_parse.read_value_from_map(frame_map, "dest_scale", yaml.Sequence, default = nil)
    if scale_sequence == nil {
        frame.dest_scale = {1,1}
    } else {
        frame.dest_scale = [2]f32{
            cast(f32) scale_sequence[0].(f64),
            cast(f32) scale_sequence[1].(f64),
        }
    }
    

    return
}

animation_draw :: proc(
    data_tag: Data_Tag,
    animation_tag: Animation_Tag,
    frame_count: ^f32,
    dest_center: sdl.FPoint
) {
    instance, ok := animation_instance_get(data_tag)
    if !ok do return

    anim, anim_ok := &instance.animations[animation_tag]
    if !anim_ok {
        log.errorf("Tried to get non-existent animation %v in %v.", animation_tag, data_tag)
        return
    }

    total_ticks := 0
    for frame in anim.frames {
        total_ticks += frame.hang_frames
    }
    if total_ticks == 0 do return

    elapsed_ticks := frame_count^ * anim.fps

    frame_index := len(anim.frames) - 1
    tick_accum := 0

    if anim.looping {
        wrapped_ticks := math.mod(elapsed_ticks, f32(total_ticks))
        for frame, i in anim.frames {
            tick_accum += frame.hang_frames
            if wrapped_ticks < f32(tick_accum) {
                frame_index = i
                break
            }
        }
    } else if elapsed_ticks < f32(total_ticks) {
        for frame, i in anim.frames {
            tick_accum += frame.hang_frames
            if elapsed_ticks < f32(tick_accum) {
                frame_index = i
                break
            }
        }
    }

    frame := anim.frames[frame_index]

    dest_w := frame.source.w * anim.scale * frame.dest_scale.x
    dest_h := frame.source.h * anim.scale * frame.dest_scale.y

    dest := sdl.FRect{
        x = dest_center.x - dest_w * 0.5,
        y = dest_center.y - dest_h * 0.5,
        w = dest_w,
        h = dest_h,
    }

    src := frame.source
    img_draw(instance.source_img_tag, &dest, &src)

    frame_count^ += primatives.dt

    if !anim.looping {
        max_time := f32(total_ticks) / anim.fps
        if frame_count^ > max_time {
            frame_count^ = max_time // freeze on last frame
        }
    }
}