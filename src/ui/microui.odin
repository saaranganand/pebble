package ui

import sdl_ttf "vendor:sdl3/ttf"
import mu "vendor:microui"
import sdl "vendor:sdl3"

import strings "core:strings"
import log "core:log"

mu_ctx_init :: proc(ctx: ^mu.Context, renderer: ^sdl.Renderer, atlas_tex: ^^sdl.Texture, font: ^sdl_ttf.Font = nil) {
    mu.init(ctx)

    ctx.style.font = transmute(mu.Font)font

    if font == nil {
        ctx.text_width = mu.default_atlas_text_width
        ctx.text_height = mu.default_atlas_text_height
    } else {
        // Provide measuring callbacks
        ctx.text_width = proc(font: mu.Font, text: string) -> i32 {
            f := transmute(^sdl_ttf.Font)font
            w, h: i32

            cstr_text := strings.clone_to_cstring(text)
            defer delete(cstr_text)
            sdl_ttf.GetStringSize(f, cstr_text, uint(len(text)), &w, &h)
            return w
        }

        ctx.text_height = proc(font: mu.Font) -> i32 {
            f := transmute(^sdl_ttf.Font)font
            return i32(sdl_ttf.GetFontHeight(f))
        }
    }    

    pixels := make([]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT * 4)
    for a, i in mu.default_atlas_alpha {
        pixels[i*4+0] = 255; pixels[i*4+1] = 255; pixels[i*4+2] = 255
        pixels[i*4+3] = a
    }
    defer delete(pixels)

    atlas_tex^ = sdl.CreateTexture(renderer, .RGBA32, .STATIC, mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT)
    sdl.UpdateTexture(atlas_tex^, nil, raw_data(pixels), mu.DEFAULT_ATLAS_WIDTH * 4)
    sdl.SetTextureBlendMode(atlas_tex^, sdl.BLENDMODE_BLEND)
}

mu_ctx_reset_mouse_left_after_dialog :: proc(ctx: ^mu.Context) {
    mouse_pos := sdl.FPoint{}
    buttons_state := sdl.GetMouseState(&mouse_pos.x, &mouse_pos.y)
    mu.input_mouse_up(ctx, cast(i32) mouse_pos.x, cast(i32) mouse_pos.y, .LEFT)
}

mu_ctx_read_input :: proc(ev: sdl.Event, ctx: ^mu.Context) {
    #partial switch ev.type {
    case .MOUSE_MOTION:
        mu.input_mouse_move(ctx, i32(ev.motion.x), i32(ev.motion.y))
    case .MOUSE_BUTTON_DOWN, .MOUSE_BUTTON_UP:     
        btn: mu.Mouse

        switch ev.button.button {
        case sdl.BUTTON_LEFT:   btn = .LEFT
        case sdl.BUTTON_RIGHT:  btn = .RIGHT
        case sdl.BUTTON_MIDDLE: btn = .MIDDLE
        }

        if ev.type == .MOUSE_BUTTON_DOWN do mu.input_mouse_down(ctx, i32(ev.button.x), i32(ev.button.y), btn)    
        else do mu.input_mouse_up(ctx, i32(ev.button.x), i32(ev.button.y), btn)

    case .MOUSE_WHEEL:
        mu.input_scroll(ctx, i32(ev.wheel.x) * -30, i32(ev.wheel.y) * -30)
    case .TEXT_INPUT:
        mu.input_text(ctx, string(ev.text.text))
    case .KEY_DOWN, .KEY_UP:
        key: mu.Key
        switch ev.key.key { 
        case sdl.K_LSHIFT, sdl.K_RSHIFT: key = .SHIFT
        case sdl.K_LCTRL, sdl.K_RCTRL:   key = .CTRL
        case sdl.K_LALT, sdl.K_RALT:     key = .ALT
        case sdl.K_BACKSPACE:            key = .BACKSPACE
        case sdl.K_DELETE:               key = .DELETE
        case sdl.K_RETURN:               key = .RETURN
        case sdl.K_LEFT:                 key = .LEFT
        case sdl.K_RIGHT:                key = .RIGHT
        case sdl.K_HOME:                 key = .HOME
        case sdl.K_END:                  key = .END
        case sdl.K_A:                    key = .A
        case sdl.K_X:                    key = .X
        case sdl.K_C:                    key = .C
        case sdl.K_V:                    key = .V
        case: return
        }
        if ev.type == .KEY_DOWN { mu.input_key_down(ctx, key) } else { mu.input_key_up(ctx, key) }
    }
}


mu_ctx_draw :: proc(ctx: ^mu.Context, renderer: ^sdl.Renderer, atlas_tex: ^sdl.Texture, text_cache: Maybe(MU_Text_Cache)) {
    cmd: ^mu.Command
    for variant in mu.next_command_iterator(ctx, &cmd) {
        switch v in variant {
        case ^mu.Command_Text:
            if v.str == "" do break

            if text_cache == nil {
                dst := sdl.FRect{f32(v.pos.x), f32(v.pos.y), 0, 0}
                sdl.SetTextureColorMod(atlas_tex, v.color.r, v.color.g, v.color.b)
                sdl.SetTextureAlphaMod(atlas_tex, v.color.a)
                x := v.pos.x
                for ch in v.str {
                    r := min(int(ch), 127)
                    src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
                    dst := sdl.FRect{f32(x), f32(v.pos.y), f32(src.w), f32(src.h)}
                    sdl.RenderTexture(renderer, atlas_tex, &sdl.FRect{f32(src.x), f32(src.y), f32(src.w), f32(src.h)}, &dst)
                    x += src.w
                }

                break
            }
            text_cache, _ := text_cache.(MU_Text_Cache) 

            draw_cache_text(text_cache, v.str, cast(f32) v.pos.x, cast(f32) v.pos.y)
            set_cache_color(text_cache, v.str, {v.color.r, v.color.g, v.color.b, v.color.a})
            
        case ^mu.Command_Rect:
            sdl.SetRenderDrawColor(renderer, v.color.r, v.color.g, v.color.b, v.color.a)
            sdl.RenderFillRect(renderer, &sdl.FRect{f32(v.rect.x), f32(v.rect.y), f32(v.rect.w), f32(v.rect.h)})

        case ^mu.Command_Icon:
            src := mu.default_atlas[v.id]
            x := v.rect.x + (v.rect.w - src.w)/2
            y := v.rect.y + (v.rect.h - src.h)/2
            sdl.SetTextureColorMod(atlas_tex, v.color.r, v.color.g, v.color.b)
            sdl.SetTextureAlphaMod(atlas_tex, v.color.a)
            dst := sdl.FRect{f32(x), f32(y), f32(src.w), f32(src.h)}
            sdl.RenderTexture(renderer, atlas_tex, &sdl.FRect{f32(src.x), f32(src.y), f32(src.w), f32(src.h)}, &dst)

        case ^mu.Command_Clip:
            sdl.SetRenderClipRect(renderer, &sdl.Rect{v.rect.x, v.rect.y, v.rect.w, v.rect.h})

        case ^mu.Command_Jump:
            // never reached — next_command already resolves jumps internally
        }
    }
    sdl.SetRenderClipRect(renderer, nil) // reset at end of frame
}
