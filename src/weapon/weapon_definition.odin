package weapon

import yaml "../../libs/odin-yaml"

import animation "../assets/animation"
import effect "../entity_effect"
import projectile "../projectile"
import assets "../assets"
import yaml_parse "../assets/yaml_parse"

import runtime "base:runtime"
import strings "core:strings"
import math "core:math"
import log "core:log"
import fmt "core:fmt"

Weapon_Definition_Tag :: string
Weapon_Definition_ID :: u32

Weapon_Definition :: struct {
    unique_tag: Weapon_Definition_Tag,
    unique_id: Weapon_Definition_ID,
    category: Category,

    //shoot_callback: Shoot_Callback,
    charge_callback: Charge_Callback,
    
    projectile_shell: projectile.Projectile_State,

    gcd_interval: f32,
    cooldown: f32,
    uses_before_cooldown: int,
    damage: f32,

    max_charge_time: f32,

    sounds: Sound_Set,
    animation_source: string,
    animation_default_angle: f32,
}

weapon_definition_load :: proc(
    pre_path, file_path: string, counter: ^Weapon_Definition_ID, arena_allocator: runtime.Allocator
) {
    defer counter^ += 1

    full_path := fmt.aprint(assets.DATA_TAG_DEFAULT_ASSET_FOLDER, file_path, sep = "")
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

    // PROJECTILE INFO -----------------------------------
    projectile_map := yaml_parse.read_value_from_map(data_map, "projectile_data", yaml.Mapping, default = nil)

    new_projectile_category := yaml_parse.read_value_from_map(projectile_map, "category", string, default = "")
    new_definition.projectile_shell.category = projectile.projectile_category_from_string(new_projectile_category)
    new_definition.projectile_shell.piercing = cast(int) yaml_parse.read_value_from_map(projectile_map, "piercing", i64, default = 0)

    new_definition.projectile_shell.shots = cast(int) yaml_parse.read_value_from_map(projectile_map, "shots", i64, default = 1)

    new_apply_effect := yaml_parse.read_value_from_map(projectile_map, "apply_effect", string, default = "")
    if new_apply_effect != "" do new_definition.projectile_shell.apply_effect = strings.clone(new_apply_effect)

    new_definition.projectile_shell.speed = cast(f32) yaml_parse.read_value_from_map(projectile_map, "speed", f64, default = 0)
    new_definition.projectile_shell.lifetime = cast(f32) yaml_parse.read_value_from_map(projectile_map, "lifetime", f64, default = 0)
    new_definition.projectile_shell.total_lifetime = new_definition.projectile_shell.lifetime
    
    new_data_tag := cast(assets.Data_Tag) strings.clone(
        yaml_parse.read_value_from_map(projectile_map, "animation_source", string, default = "")
    )
    new_definition.projectile_shell.animation_controller = animation.animation_controller_create(new_data_tag)
    new_definition.projectile_shell.shape = projectile.projectile_shape_from_category(new_definition.projectile_shell.category, new_definition.projectile_shell.team, projectile_map)
    // PROJECTILE INFO -----------------------------------

    new_definition.gcd_interval = cast(f32) yaml_parse.read_value_from_map(data_map, "gcd_interval", f64, default = 0)
    new_definition.cooldown =     cast(f32) yaml_parse.read_value_from_map(data_map, "cooldown", f64, default = 0)

    new_definition.uses_before_cooldown = cast(int) yaml_parse.read_value_from_map(data_map, "uses_before_cooldown", i64, default = 0)
    new_definition.max_charge_time =      cast(f32) yaml_parse.read_value_from_map(data_map, "max_charge_time", f64, default = 0)
    new_definition.damage = cast(f32) yaml_parse.read_value_from_map(data_map, "damage", f64, default = 0)

    // TODO determine callbacks from weapon/projectile category
    custom_charge_callback := yaml_parse.read_value_from_map(data_map, "custom_charge_callback", string, default = "")
    if custom_charge_callback != "" {
        new_definition.charge_callback = weapon_charge_callback_get(custom_charge_callback)
    }

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
    delete(definition.animation_source)
    delete(definition.projectile_shell.animation_controller.data_tag)
    if tag, ok := definition.projectile_shell.apply_effect.(effect.Effect_Instance_Tag); ok do delete(tag)
    sound_set_destroy(&definition.sounds)
}