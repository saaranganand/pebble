package weapon

import animation "src:data_load/animation"
import effect "src:entity/effect"
import projectile "src:geometry/projectile"
import color "src:util/color"

import json "core:encoding/json"
import log "core:log"
import os "core:os"

Weapon_Definition_Tag :: string
Weapon_Definition_ID :: uint

// a held beam rather than a fired projectile. length > 0 is what marks a weapon as a beam
// damage is per second, since the beam ticks every frame it is held
Beam :: struct {
    length: f32,
    thickness: f32,
    beam_color: color.Default_Palette_Color,
    damage_per_second: f32,
}

// heat builds while a beam is held and cools when it isnt
// past max the weapon overheats and refuses to fire until it has cooled all the way back to 0
Heat :: struct {
    max: f32,
    build_rate: f32,
    cool_rate: f32,
    overheat_cool_rate: f32,
}

Weapon_Definition :: struct {
    tag: Weapon_Definition_Tag,
    id: Weapon_Definition_ID,
    category: Category,

    // names of behaviours in weapon_callback.odin, resolved to the procs below once at load
    shoot_callback: string,
    charge_callback: string,
    shoot_callback_proc: Shoot_Callback,
    charge_callback_proc: Charge_Callback,

    // how much the wielder's move speed is scaled while charging. 0 = no penalty
    charge_move_speed_mult: f32,

    projectile_shell: projectile.Shell,

    gcd_interval: f32,
    cooldown: f32,
    uses_before_cooldown: uint,
    damage: f32,

    // chance a fired round is a dud and lands for nothing. 0 = always hits.
    // the bit weapons are unreliable by design; programs can buff this down
    miss_chance: f32,

    // skip spawning projectiles entirely - the shoot callback is the whole shot
    no_projectile: bool,

    // img tag to use as the mouse cursor while this weapon is selected. "" = system default
    cursor: string,

    max_charge_time: f32,

    beam: Beam,
    heat: Heat,

    sounds: Sound_Set,
    animation_source: string,
    animation_default_angle: f32,
}

// same as the definition fields above that a program is allowed to buff
Weapon_Stat :: enum {
    DAMAGE,
    GCD_INTERVAL,
    COOLDOWN,
    PROJECTILE_SPEED,
    MISS_CHANCE,
}

Stat_Mults :: [Weapon_Stat]f32

// apply it here - not on the definition - because definitions are shared by every wielder of that weapon not just player picking up the program
Stat_Mult_Table :: []Stat_Mults

// base stats come from the weapon's json
STAT_MULTS_IDENTITY :: Stat_Mults{
    .DAMAGE = 1.0,
    .GCD_INTERVAL = 1.0,
    .COOLDOWN = 1.0,
    .PROJECTILE_SPEED = 1.0,
    .MISS_CHANCE = 1.0,
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
    case "MISS_CHANCE":
        stat = .MISS_CHANCE
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

// resolves the callback names a weapon asked for into actual procs.
// done at load so a typo fails loudly at boot rather than the first time you fire
@(private)
weapon_definition_resolve_callbacks :: proc(definition: ^Weapon_Definition) {
    if definition.shoot_callback != "" {
        definition.shoot_callback_proc = weapon_shoot_callback_get(definition.shoot_callback)
    }
    if definition.charge_callback != "" {
        definition.charge_callback_proc = weapon_charge_callback_get(definition.charge_callback)
    }
}

weapon_definition_unload :: proc(definition: ^Weapon_Definition) {
    delete(definition.tag)
    delete(definition.animation_source)
    delete(definition.shoot_callback)
    delete(definition.charge_callback)
    delete(definition.cursor)
    delete(definition.projectile_shell.animation_source)
    if tag, ok := definition.projectile_shell.apply_effect.(string); ok do delete(tag)
    sound_set_destroy(&definition.sounds)
}