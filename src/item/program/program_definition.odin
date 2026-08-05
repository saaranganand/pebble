package program

import effect "src:entity/entity_effect"
import weapon "src:item/weapon"
import entity "src:entity"
import img "src:data_load/img"

import json "core:encoding/json"
import strings "core:strings"
import log "core:log"
import os "core:os"

Program_Definition_Tag :: string
Program_Definition_ID :: uint

// weapon buff
Stat_Buff :: struct {
    stat: weapon.Weapon_Stat,
    multiplier: f32,

    weapon_tag: string,
    weapon_id: Maybe(weapon.Weapon_Definition_ID), // nil = every weapon
}

Entity_Stat_Buff :: struct {
    stat: entity.Entity_Stat,
    multiplier: f32,
}

// effect instance applied to wielder
Self_Effect :: struct {
    instance_id: effect.Effect_Instance_ID,
    definition_id: effect.Effect_Definition_ID,
}

// --- PROGRAMS ---
// 3 types: buffs (weapons), self effects (applied to player), hit effects (applied to whatever projectile hits)
// All references are resolved to IDs here at load time, so bad names fail loudly at boot, not during play.
Program_Definition :: struct {
    unique_tag: Program_Definition_Tag,
    unique_id: Program_Definition_ID,
    sprite: string,

    buffs: []Stat_Buff,
    entity_buffs: []Entity_Stat_Buff,

    self_effect_tags: []string,
    hit_effect_tags: []string,

    self_effects: []Self_Effect,
    hit_effects: []effect.Effect_Instance_ID,
}

@(private)
PROGRAM_DEFAULT_SPRITE :: "program"

@(private)
PROGRAM_TAG_SUFFIX :: ".program"

program_definition_display_name :: proc(definition: ^Program_Definition) -> string {
    return strings.trim_suffix(definition.unique_tag, PROGRAM_TAG_SUFFIX)
}

@(private)
program_definition_load :: proc(definition: ^Program_Definition, path: string) {
    data, err := os.read_entire_file(path, context.allocator)
	if err != os.General_Error.None {
        log.errorf("Failed to read program file %v: %v", path, err)
        return
    }
	defer delete(data)

	json_err := json.unmarshal(data, definition, spec = .MJSON)
	if json_err != nil {
		log.errorf("Failed to parse program json file %v: %v", path, json_err)
		return
	}
}

@(private)
program_definition_resolve :: proc(definition: ^Program_Definition) {
    // SPRITE --------------------------------------------
    if definition.sprite == "" do definition.sprite = strings.clone(PROGRAM_DEFAULT_SPRITE)
    img.img_load(definition.sprite)

    // BUFFS ---------------------------------------------
    for &buff in definition.buffs {
        if buff.weapon_tag == "" do continue

        weapon_id, weapon_ok := weapon.weapon_manager_get_definition_id(buff.weapon_tag)
        if !weapon_ok do log.panicf("Program %v buff targets unknown weapon %v", definition.unique_tag, buff.weapon_tag)
        buff.weapon_id = weapon_id
    }

    // SELF EFFECTS
    definition.self_effects = make([]Self_Effect, len(definition.self_effect_tags))
    for instance_tag, i in definition.self_effect_tags {
        instance_id, instance_ok := effect.effect_manager_get_instance_id(instance_tag)
        if !instance_ok do log.panicf("Program %v self_effect references unknown effect instance %v", definition.unique_tag, instance_tag)

        definition.self_effects[i] = Self_Effect{
            instance_id = instance_id,
            definition_id = effect.effect_manager_get_instance(instance_id).definition.unique_id,
        }
    }

    // HIT EFFECTS
    definition.hit_effects = make([]effect.Effect_Instance_ID, len(definition.hit_effect_tags))
    for instance_tag, i in definition.hit_effect_tags {
        instance_id, instance_ok := effect.effect_manager_get_instance_id(instance_tag)
        if !instance_ok do log.panicf("Program %v hit_effect references unknown effect instance %v", definition.unique_tag, instance_tag)

        definition.hit_effects[i] = instance_id
    }
}

program_definition_unload :: proc(definition: ^Program_Definition) {
    delete(definition.unique_tag)
    delete(definition.sprite)

    for buff in definition.buffs do delete(buff.weapon_tag)
    delete(definition.buffs)
    delete(definition.entity_buffs)

    for tag in definition.self_effect_tags do delete(tag)
    delete(definition.self_effect_tags)
    for tag in definition.hit_effect_tags do delete(tag)
    delete(definition.hit_effect_tags)

    delete(definition.self_effects)
    delete(definition.hit_effects)
}
