package weapon

import sdl "vendor:sdl3"
import yaml "../../libs/odin-yaml"

import effect "../entity_effect"
import projectile "../projectile"
import assets "../assets"
import handle "../handle"
import yaml_parse "../assets/yaml_parse"

import runtime "base:runtime"
import strings "core:strings"
import math "core:math"
import log "core:log"
import fmt "core:fmt"
import mem "core:mem"

Shoot_Callback :: proc(weapon: ^Weapon_State, owner: handle.Entity_Handle)
Start_Charge_Callback :: proc(weapon: ^Weapon_State, owner: handle.Entity_Handle)

Weapon_Definition_Tag :: string
Weapon_Definition_ID :: u32

Weapon_Definition :: struct {
    unique_tag: Weapon_Definition_Tag,
    unique_id: Weapon_Definition_ID,
    category: Category,

    //shoot_callback: Shoot_Callback,
    start_charge_callback: Start_Charge_Callback,
    
    projectile_shell: projectile.Projectile_State,

    gcd_interval: f32,
    cooldown: f32,
    uses_before_cooldown: int,
    damage: f32,

    max_charge_time: f32,

    sounds: Sound_Set,
    animation_source: assets.Data_Tag,
    animation_default_angle: f32,
}

// same  as the definition fields above that a program is allowed to buff
// Allows a program's yaml say which one to multiply ("DAMAGE") and lets multiplier table below be indexed by that
Weapon_Stat :: enum {
    DAMAGE,
    GCD_INTERVAL,
    COOLDOWN,
    PROJECTILE_SPEED,
}

Stat_Mults :: [Weapon_Stat]f32

// Apply it here - not on the definition-  because definitions are shared by every wielder of that weapon (not just player picking up the program)
Stat_Mult_Table :: []Stat_Mults

// Base stats come from the weapon's yaml
// multiply by 1.0 means unchanged
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

weapon_definition_load :: proc(
    pre_path, file_path: string, counter: ^Weapon_Definition_ID, arena_allocator: runtime.Allocator
) {
    defer counter^ += 1

    full_path := strings.clone(file_path)
    defer delete(full_path)
    data_map, map_ok := yaml_parse.get_yaml_mapping(full_path, arena_allocator)
    if !map_ok {
        log.errorf("Failed in loading weapon definition from path %v", file_path)
        return
    }

    log.debugf("Loading weapon definition %v", file_path)

    new_definition: Weapon_Definition
    defer global_weapon_manager.weapons[counter^] = new_definition

    new_definition.unique_id = counter^

    new_definition.unique_tag = strings.clone(strings.trim_prefix(strings.trim_suffix(file_path, ".yaml"), pre_path))

    new_category := yaml_parse.read_value_from_map(data_map, "category", string, default = "")
    new_definition.category = weapon_category_from_string(new_category)


    // TODO determine callbacks from weapon/projectile category

    // PROJECTILE INFO -----------------------------------
    projectile_map := yaml_parse.read_value_from_map(data_map, "projectile_data", yaml.Mapping, default = nil)

    new_projectile_category := yaml_parse.read_value_from_map(projectile_map, "category", string, default = "")
    new_definition.projectile_shell.category = projectile.projectile_category_from_string(new_projectile_category)
    new_definition.projectile_shell.piercing = cast(int) yaml_parse.read_value_from_map(projectile_map, "piercing", i64, default = 0)

    new_apply_effect := yaml_parse.read_value_from_map(projectile_map, "apply_effect", string, default = "")
    if new_apply_effect != "" do new_definition.projectile_shell.apply_effect = strings.clone(new_apply_effect)

    new_definition.projectile_shell.speed = cast(f32) yaml_parse.read_value_from_map(projectile_map, "speed", f64, default = 0)
    new_definition.projectile_shell.lifetime = cast(f32) yaml_parse.read_value_from_map(projectile_map, "lifetime", f64, default = 0)
    new_definition.projectile_shell.animation_controller.data_tag = cast(assets.Data_Tag) strings.clone(
        yaml_parse.read_value_from_map(projectile_map, "animation_source", string, default = "")
    )
    new_definition.projectile_shell.shape = projectile.projectile_shape_from_category(new_definition.projectile_shell.category, projectile_map)
    // PROJECTILE INFO -----------------------------------

    new_definition.gcd_interval = cast(f32) yaml_parse.read_value_from_map(data_map, "gcd_interval", f64, default = 0)
    new_definition.cooldown =     cast(f32) yaml_parse.read_value_from_map(data_map, "cooldown", f64, default = 0)

    new_definition.uses_before_cooldown = cast(int) yaml_parse.read_value_from_map(data_map, "uses_before_cooldown", i64, default = 0)
    new_definition.max_charge_time =      cast(f32) yaml_parse.read_value_from_map(data_map, "max_charge_time", f64, default = 0)
    new_definition.damage = cast(f32) yaml_parse.read_value_from_map(data_map, "damage", f64, default = 0)

    new_definition.animation_source = cast(assets.Data_Tag) strings.clone(
        yaml_parse.read_value_from_map(data_map, "animation_source", string, default = "")
    )
    
    new_animation_default_angle_deg := cast(f32) yaml_parse.read_value_from_map(data_map, "animation_default_angle_deg", f64, default = 0)
    new_definition.animation_default_angle = math.RAD_PER_DEG * new_animation_default_angle_deg

    sounds_map := yaml_parse.read_value_from_map(data_map, "sounds", yaml.Mapping, default = nil)
    sound_set_load(&new_definition.sounds, sounds_map)

    global_weapon_manager.definition_tag_to_id[new_definition.unique_tag] = new_definition.unique_id

    log.debugf("Loaded weapon definition %v", file_path)
}

weapon_definition_unload :: proc(definition: ^Weapon_Definition) {
    delete(definition.unique_tag)
    delete(cast(string) definition.animation_source)
    delete(cast(string) definition.projectile_shell.animation_controller.data_tag)
    if tag, ok := definition.projectile_shell.apply_effect.(effect.Effect_Instance_Tag); ok do delete(tag)
    sound_set_destroy(&definition.sounds)
}