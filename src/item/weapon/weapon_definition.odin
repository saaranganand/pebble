package weapon

import animation "src:data_load/animation"
import effect "src:entity/entity_effect"
import projectile "src:geometry/projectile"

import json "core:encoding/json"
import log "core:log"
import os "core:os"

Weapon_Definition_Tag :: string
Weapon_Definition_ID :: uint

Weapon_Definition :: struct {
    unique_tag: Weapon_Definition_Tag,
    unique_id: Weapon_Definition_ID,
    category: Category,

    shoot_callback: string,
    charge_callback: string,
    
    projectile_shell: projectile.Projectile_Shell,

    gcd_interval: f32,
    cooldown: f32,
    uses_before_cooldown: uint,
    damage: f32,

    max_charge_time: f32,

    sounds: Sound_Set,
    animation_source: string,
    animation_default_angle: f32,
}

// Same as the definition fields above that a program is allowed to buff.
// Lets a program's data say which one to multiply ("DAMAGE"), and lets the multiplier
// table below be indexed by that.
Weapon_Stat :: enum {
    DAMAGE,
    GCD_INTERVAL,
    COOLDOWN,
    PROJECTILE_SPEED,
}

Stat_Mults :: [Weapon_Stat]f32

// Applied here - not on the definition - because definitions are shared by every
// wielder of that weapon, not just the player who picked up the program.
Stat_Mult_Table :: []Stat_Mults

// Base stats come from the weapon's data file; a multiplier of 1.0 means unchanged.
STAT_MULTS_IDENTITY :: Stat_Mults{
    .DAMAGE = 1.0,
    .GCD_INTERVAL = 1.0,
    .COOLDOWN = 1.0,
    .PROJECTILE_SPEED = 1.0,
}

weapon_stat_from_string :: proc(stat_string: string) -> (stat: Weapon_Stat) {
    switch stat_string {
    case "DAMAGE":
        stat = .DAMAGE
    case "GCD_INTERVAL":
        stat = .GCD_INTERVAL
    case "COOLDOWN":
        stat = .COOLDOWN
    case "PROJECTILE_SPEED":
        stat = .PROJECTILE_SPEED
    case:
        log.panicf("No weapon stat parsable from string %v", stat_string)
    }
    return
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
    delete(definition.unique_tag)
    delete(definition.animation_source)
    delete(definition.shoot_callback)
    delete(definition.charge_callback)
    delete(definition.projectile_shell.animation_source)
    if tag, ok := definition.projectile_shell.apply_effect.(string); ok do delete(tag)
    sound_set_destroy(&definition.sounds)
}