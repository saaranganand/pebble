package animation

import sdl "vendor:sdl3"

import primatives "src:sdl_primatives"
import img "../img"

import log "core:log"
import math "core:math"

Animation_Controller :: struct {
    data_tag: string,
    current_animation: string,
    frame_count, scale: f32,
}

animation_controller_create :: proc(data_tag: string, scale: f32 = 1.0) -> (controller: Animation_Controller) {
    controller.data_tag = data_tag
    controller.current_animation = "idle"
    controller.frame_count = 0
    controller.scale = scale

    return
}

animation_draw :: proc(
    controller: ^Animation_Controller,
    dest_center: sdl.FPoint,
    angle: f64 = 0, flip_mode: sdl.FlipMode = .NONE, center: ^sdl.FPoint = nil
) {
    instance, ok := animation_instance_get(controller.data_tag)
    if !ok do return

    anim, anim_ok := &instance.animations[controller.current_animation]
    if !anim_ok {
        log.errorf("Tried to get non-existent animation %v in %v.", controller.current_animation, controller.data_tag)
        return
    }

    total_ticks: uint = 0
    for frame in anim.frames {
        total_ticks += frame.hang_frames
    }
    if total_ticks == 0 do return

    elapsed_ticks := controller.frame_count * anim.fps

    frame_index := len(anim.frames) - 1
    tick_accum: uint = 0

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

    dest_w := frame.source.w * anim.scale * frame.dest_scale.x * controller.scale
    dest_h := frame.source.h * anim.scale * frame.dest_scale.y * controller.scale

    dest := sdl.FRect{
        x = dest_center.x - dest_w * 0.5,
        y = dest_center.y - dest_h * 0.5,
        w = dest_w,
        h = dest_h,
    }

    src := frame.source
    img.img_draw(instance.source_img_tag, &dest, &src, angle, flip_mode, center)

    controller.frame_count += primatives.dt

    if !anim.looping {
        max_time := f32(total_ticks) / anim.fps
        if controller.frame_count > max_time {
            controller.frame_count = max_time // freeze on last frame
        }
    }
}