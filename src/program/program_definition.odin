package program

import yaml "../../libs/odin-yaml"

import yaml_parse "../assets/yaml_parse"
import entity "../entity"
import effect "../entity_effect"
import weapon "../weapon"

import runtime "base:runtime"
import strings "core:strings"
import log "core:log"

Program_Definition_Tag :: string
Program_Definition_ID :: u32

// weapon buff
Stat_Buff :: struct {
    stat: weapon.Weapon_Stat,
    weapon_id: Maybe(weapon.Weapon_Definition_ID), // nil = every weapon
    multiplier: f32,
}

Entity_Stat_Buff :: struct {
    stat: entity.Entity_Stat,
    multiplier: f32
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

    buffs: []Stat_Buff,
    entity_buffs: []Entity_Stat_Buff,
    self_effects: []Self_Effect,
    hit_effects: []effect.Effect_Instance_ID,
}

program_definition_load :: proc(
    pre_path, file_path: string, counter: ^Program_Definition_ID, arena_allocator: runtime.Allocator
) {
    defer counter^ += 1

    full_path := strings.clone(file_path)
    defer delete(full_path)
    data_map, map_ok := yaml_parse.get_yaml_mapping(full_path, arena_allocator)
    if !map_ok {
        log.errorf("Failed in loading program definition from path %v", file_path)
        return
    }

    log.debugf("Loading program definition %v", file_path)

    new_definition: Program_Definition
    defer global_program_manager.programs[counter^] = new_definition

    new_definition.unique_id = counter^
    new_definition.unique_tag = strings.clone(strings.trim_prefix(strings.trim_suffix(file_path, ".yaml"), pre_path))

    // BUFFS ---------------------------------------------
    buffs_seq := yaml_parse.read_value_from_map(data_map, "buffs", yaml.Sequence, default = nil)
    new_definition.buffs = make([]Stat_Buff, len(buffs_seq))
    for item, i in buffs_seq {
        buff_map, buff_ok := item.(yaml.Mapping)
        if !buff_ok {
            log.errorf("Program %v buff %v is not a mapping", new_definition.unique_tag, i)
            continue
        }

        new_buff: Stat_Buff
        new_buff.stat = weapon.weapon_stat_from_string(yaml_parse.read_value_from_map(buff_map, "stat", string, default = ""))
        new_buff.multiplier = cast(f32) yaml_parse.read_value_from_map(buff_map, "multiplier", f64, default = 1)

        weapon_tag := yaml_parse.read_value_from_map(buff_map, "weapon", string, default = "")
        if weapon_tag != "" {
            weapon_id, weapon_ok := weapon.weapon_manager_get_definition_id(weapon_tag)
            if !weapon_ok do log.panicf("Program %v buff targets unknown weapon %v", new_definition.unique_tag, weapon_tag)
            new_buff.weapon_id = weapon_id
        }

        new_definition.buffs[i] = new_buff
    }

    // ENTITY BUFFS ---------------------------------------------
    entity_buffs_seq := yaml_parse.read_value_from_map(data_map, "entity_buffs", yaml.Sequence, default = nil)
    new_definition.entity_buffs = make([]Entity_Stat_Buff, len(entity_buffs_seq))
    for item, i in entity_buffs_seq {
        buff_map, buff_ok := item.(yaml.Mapping)
        if !buff_ok {
            log.errorf("Program %v entity_buff %v is not a mapping", new_definition.unique_tag, i)
            continue
        }

        new_buff: Entity_Stat_Buff
        new_buff.stat = entity.entity_stat_from_string(yaml_parse.read_value_from_map(buff_map, "stat", string, default = ""))
        new_buff.multiplier = cast(f32) yaml_parse.read_value_from_map(buff_map, "multiplier", f64, default = 1)

        new_definition.entity_buffs[i] = new_buff
    }


    // SELF EFFECTS
    self_seq := yaml_parse.read_value_from_map(data_map, "self_effects", yaml.Sequence, default = nil)
    new_definition.self_effects = make([]Self_Effect, len(self_seq))
    for item, i in self_seq {
        instance_tag, tag_ok := item.(string)
        if !tag_ok {
            log.errorf("Program %v self_effect %v is not a string", new_definition.unique_tag, i)
            continue
        }

        instance_id, instance_ok := effect.effect_manager_get_instance_id(instance_tag)
        if !instance_ok do log.panicf("Program %v self_effect references unknown effect instance %v", new_definition.unique_tag, instance_tag)

        new_definition.self_effects[i] = Self_Effect{
            instance_id = instance_id,
            definition_id = effect.effect_manager_get_instance(instance_id).definition.unique_id,
        }
    }

    // HIT EFFECTS
    hit_seq := yaml_parse.read_value_from_map(data_map, "hit_effects", yaml.Sequence, default = nil)
    new_definition.hit_effects = make([]effect.Effect_Instance_ID, len(hit_seq))
    for item, i in hit_seq {
        instance_tag, tag_ok := item.(string)
        if !tag_ok {
            log.errorf("Program %v hit_effect %v is not a string", new_definition.unique_tag, i)
            continue
        }

        instance_id, instance_ok := effect.effect_manager_get_instance_id(instance_tag)
        if !instance_ok do log.panicf("Program %v hit_effect references unknown effect instance %v", new_definition.unique_tag, instance_tag)

        new_definition.hit_effects[i] = instance_id
    }

    global_program_manager.definition_tag_to_id[new_definition.unique_tag] = new_definition.unique_id

    log.debugf("Loaded program definition %v", file_path)
}

program_definition_unload :: proc(definition: ^Program_Definition) {
    delete(definition.unique_tag)
    delete(definition.buffs)
    delete(definition.self_effects)
    delete(definition.hit_effects)
    delete(definition.entity_buffs)
}
