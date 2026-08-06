// shared Lua VM
// Scripts in assets/scripts/*.lua
// effects/programs reference them via `callback: "LUA"` plus `lua_callback: "<function>"`.
package script

import lua "vendor:lua/5.4"

import entity "src:entity"
import util "src:util"

import runtime "base:runtime"
import c "core:c/libc"
import strings "core:strings"
import log "core:log"

@(private)
global_state: ^lua.State

script_create :: proc() {
    global_state = lua.L_newstate()
    lua.L_openlibs(global_state)
    script_register_bindings(global_state)
    log.infof("Created Lua scripting VM")
}

script_destroy :: proc() {
    if global_state != nil {
        lua.close(global_state)
        global_state = nil
    }
    log.infof("Destroyed Lua scripting VM")
}

SCRIPT_MASTER_FOLDER :: "assets/"
SCRIPT_EXTENSION :: ".lua"

// run every assets/**/*.lua to define globals
script_load :: proc() {
    file_paths := make([dynamic]string)
    defer delete(file_paths)

    util.scrape_files(SCRIPT_MASTER_FOLDER, SCRIPT_EXTENSION, &file_paths)

    for path in file_paths {
        defer delete(path)
        cpath := strings.clone_to_cstring(path)
        defer delete(cpath)

        if lua.L_dofile(global_state, cpath) != 0 {
            log.errorf("Lua error loading %v: %v", path, lua.tostring(global_state, -1))
            lua.pop(global_state, 1)
        } else {
            log.infof("Loaded script %v", path)
        }
    }
}

// calls global Lua function `name(target, params)`
script_run_effect_callback :: proc(name: string, target: ^entity.Entity, params: map[string]f32) {
    if global_state == nil do return

    cname := strings.clone_to_cstring(name)
    defer delete(cname)

    lua.getglobal(global_state, cname)
    if !lua.isfunction(global_state, -1) {
        log.errorf("Lua callback %v is not a defined function", name)
        lua.pop(global_state, 1)
        return
    }

    lua.pushlightuserdata(global_state, target)

    // params
    lua.newtable(global_state)
    for key, value in params {
        ckey := strings.clone_to_cstring(key)
        lua.pushnumber(global_state, lua.Number(value))
        lua.setfield(global_state, -2, ckey)
        delete(ckey)
    }

    if lua.pcall(global_state, 2, 0, 0) != 0 {
        log.errorf("Lua error in %v: %v", name, lua.tostring(global_state, -1))
        lua.pop(global_state, 1)
    }
}

// ---- GAME API ----
// add binding here, every script can use

@(private)
script_register_bindings :: proc(L: ^lua.State) {
    lua.register(L, "heal", binding_heal)
    lua.register(L, "get_position", binding_get_position)
    lua.register(L, "damage_area", binding_damage_area)
}

// heal(target, amount)
@(private)
binding_heal :: proc "c" (L: ^lua.State) -> c.int {
    context = runtime.default_context()

    target := cast(^entity.Entity) lua.touserdata(L, 1)
    amount := f32(lua.L_checknumber(L, 2))

    if target != nil do entity.entity_heal(target, amount)
    return 0
}

// get_position(target) -> x, y
@(private)
binding_get_position :: proc "c" (L: ^lua.State) -> c.int {
    context = runtime.default_context()

    target := cast(^entity.Entity) lua.touserdata(L, 1)
    if target == nil do return 0

    lua.pushnumber(L, lua.Number(target.collision.position.x))
    lua.pushnumber(L, lua.Number(target.collision.position.y))
    return 2
}

// damage_area(x, y, radius, amount) - damages every enemy within radius
@(private)
binding_damage_area :: proc "c" (L: ^lua.State) -> c.int {
    context = runtime.default_context()

    x      := f32(lua.L_checknumber(L, 1))
    y      := f32(lua.L_checknumber(L, 2))
    radius := f32(lua.L_checknumber(L, 3))
    amount := f32(lua.L_checknumber(L, 4))

    entity.entity_damage_in_radius({x, y}, radius, .ENEMY, amount)
    return 0
}
