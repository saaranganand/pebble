package weapon

import animation "src:data_load/animation"
import effect "src:entity/effect"
import projectile "src:geometry/projectile"

import json "core:encoding/json"
import log "core:log"
import os "core:os"

Weapon_Definition :: struct {
    tag: string,
    id: uint,
    category: Category,

    shoot_callback: string,
    charge_callback: string,
    
    projectile_shell: projectile.Shell,

    gcd_interval: f32,
    cooldown: f32,
    uses_before_cooldown: uint,
    damage: f32,

    max_charge_time: f32,

    sounds: Sound_Set,
    animation_source: string,
    animation_default_angle: f32,
}

@(private)
weapon_definition_load :: proc(definition: ^Weapon_Definition, path: string) {
    data, err := os.read_entire_file(path, context.allocator)
	if err != os.General_Error.None {
        log.errorf("Failed to read weapon file %v: %v", path, err)
        return
    }
	defer delete(data)

	json_err := json.unmarshal(data, definition, spec = .MJSON)
	if json_err != nil {
		log.errorf("Failed to parse weapon json file %v: %v", path, json_err)
		return
	}
}

weapon_definition_unload :: proc(definition: ^Weapon_Definition) {
    delete(definition.tag)
    delete(definition.animation_source)
    delete(definition.shoot_callback)
    delete(definition.charge_callback)
    delete(definition.projectile_shell.animation_source)
    if tag, ok := definition.projectile_shell.apply_effect.(string); ok do delete(tag)
    sound_set_destroy(&definition.sounds)
}