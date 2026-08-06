package weapon

import sdl "vendor:sdl3"

import util "src:util"

import filepath "core:path/filepath"
import runtime "base:runtime"
import strings "core:strings"
import log "core:log"

@(private)
global_weapon_manager: Weapon_Manager

Weapon_Manager :: struct {
    weapons: []Weapon_Definition,
    num_weapons: uint,
    definition_id_map: map[string]uint,
    num_definitions: uint,
}

weapon_manager_create :: proc() -> ^Weapon_Manager {
    log.infof("Creating weapon manager")
    global_weapon_manager.definition_id_map = make(map[string]uint)

    weapon_manager_load()

    return &global_weapon_manager
}

weapon_manager_destroy :: proc() {
    log.infof("Destroying weapon manager")

    for &weapon in global_weapon_manager.weapons {
        weapon_definition_unload(&weapon)
    }
    delete(global_weapon_manager.weapons)
    delete(global_weapon_manager.definition_id_map)
}

weapon_manager_num_definitions :: proc() -> Weapon_Definition_ID {
    return global_weapon_manager.num_definitions
}

weapon_manager_get_definition_id :: proc(definition_tag: Weapon_Definition_Tag) -> (id: Weapon_Definition_ID, ok: bool) {
    id, ok = global_weapon_manager.definition_id_map[definition_tag]
    return
}

weapon_manager_get_definition :: proc(definition_tag: string) -> ^Weapon_Definition {
    definition_ID, def_ok := global_weapon_manager.definition_id_map[definition_tag]
    if !def_ok {
        log.errorf("Attempted to get weapon definition ID from tag %v that does not have an ID mapping", definition_tag)
        return nil
    }

    return &global_weapon_manager.weapons[definition_ID]
}

@(private)
WEAPON_MASTER_FOLDER :: "assets/"
WEAPON_DATA_EXTENSION :: ".weapon.json"
weapon_manager_load :: proc() {
    log.infof("Loading weapon data")

    results := make([dynamic]string)
    defer {
        for result in results do delete(result)
        delete(results)
    }
    util.scrape_files(WEAPON_MASTER_FOLDER, WEAPON_DATA_EXTENSION, &results)

    num_definitions := len(results)
    global_weapon_manager.num_definitions = cast(uint) num_definitions
    global_weapon_manager.weapons = make([]Weapon_Definition, num_definitions)
    definition_id_counter: uint = 0

    for path in results {
        defer definition_id_counter += 1
        tag := strings.clone(filepath.stem(path))

        global_weapon_manager.weapons[definition_id_counter] = {}
        definition := &global_weapon_manager.weapons[definition_id_counter]
        global_weapon_manager.definition_id_map[tag] = definition_id_counter

        weapon_definition_load(definition, path)
        
        definition.tag = tag
        definition.id = definition_id_counter

        weapon_definition_resolve_callbacks(definition)
    }
}