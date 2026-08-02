package reaction

import sdl "vendor:sdl3"
import yaml "../../libs/odin-yaml"

import yaml_parse "../data_load/yaml_parse"
import color "../color"
import data_load "../data_load"
import handle "../handle"
import entity "../entity"
import effect "../entity_effect"

import runtime "base:runtime"
import strings "core:strings"
import log "core:log"
import fmt "core:fmt"
import mem "core:mem"

// For example, if an entity with an active burn effect should draw an animation of flames around them,
// said animation will be accessed from this data source.
REACTION_ANIMATION_SOURCE: string: "reactions.animation"


Reaction_Data_Tag :: string

reaction_data_tag_create :: proc(team: entity.Team, category: entity.Category) -> (tag: Reaction_Data_Tag) {
    return fmt.aprint(team, category, sep = ",")
}

reaction_data_tag_destroy :: proc(tag: Reaction_Data_Tag) {
    delete(tag)
}

// Reaction data contains a collection of data related to possible reaction outcomes.
// Some effects might play a sound on their trigger, while some may display an animation while active.
// Some may do both.
// Reaction sets are children to effect definitions, and there is the potential for one for each combination of entity team and category.
// For example: a burn effect show a burning animation around the entity, and might play a sound every time it ticks.
// However, we only want to play the sound for allied members in combat: not allied NPCs/bullets, and not enemies.
// So, the allied player reaction set would contain a sound_on_trigger, and a external_animation_tag,
// while the default reaction set would contain just an external_animation_tag.
Reaction_Data :: struct {
    apply_sound:  Maybe(string),
    trigger_sound:   Maybe(string),
    remove_sound: Maybe(string),

    flash_color:    Maybe(color.Default_Palette_Color),
    flash_duration: f32,

    entity_animation_tag:   Maybe(string),
    external_animation_tag: Maybe(string),

    screen_shake_magnitude: f32,

    show_damage_number: bool,
    show_damage_number_color: Maybe(color.Default_Palette_Color)
}

reaction_data_empty_struct :: proc() -> (data: Reaction_Data) {
    data.apply_sound = nil
    data.trigger_sound = nil
    data.remove_sound = nil

    data.flash_color = nil
    data.flash_duration = 0.0

    data.entity_animation_tag = nil
    data.external_animation_tag = nil

    data.screen_shake_magnitude = 0.0

    data.show_damage_number = false
    data.show_damage_number_color = nil

    return
}

reaction_data_destroy :: proc(data: ^Reaction_Data) {
    apply_sound, has_apply_sound := data.apply_sound.(string)
    if has_apply_sound do delete(cast(string) apply_sound)

    trigger_sound, has_trigger_sound := data.trigger_sound.(string)
    if has_trigger_sound do delete(cast(string) trigger_sound)

    remove_sound, has_remove_sound := data.remove_sound.(string)
    if has_remove_sound do delete(cast(string) remove_sound)

    entity_animation_tag, has_entity_animation_tag := data.entity_animation_tag.(string)
    if has_entity_animation_tag do delete(cast(string) entity_animation_tag)

    external_animation_tag, has_external_animation_tag := data.external_animation_tag.(string)
    if has_external_animation_tag do delete(cast(string) external_animation_tag)
}

// All reaction sets have at least a default data object.
// For each necessary combination of team and category, a tag is created through the enum names in a comma seperated string
Reaction_Set :: struct {
    default_reaction_data: Maybe(Reaction_Data),
    reaction_data_map: map[Reaction_Data_Tag]Reaction_Data,
}

reaction_set_create :: proc(set: ^Reaction_Set, default_data: Maybe(Reaction_Data) = nil) {
    set.default_reaction_data = default_data

    set.reaction_data_map = make(map[Reaction_Data_Tag]Reaction_Data)
}

reaction_set_destroy :: proc(set: ^Reaction_Set) {
    for key, &data in set.reaction_data_map {
        delete(key)
        reaction_data_destroy(&data)
    }

    default_reaction_data, ok := &set.default_reaction_data.(Reaction_Data)
    if ok do reaction_data_destroy(default_reaction_data)

    delete(set.reaction_data_map)
}

reaction_data_load :: proc(
    pre_path, file_path: string, effect_definition_tag_to_id: effect.Effect_Definition_Tag_To_ID_Map,
    arena_allocator: runtime.Allocator
) {
    full_path := fmt.aprint(data_load.DATA_TAG_DEFAULT_ASSET_FOLDER, file_path, sep = "")
    defer delete(full_path)
    data_map, map_ok := yaml_parse.get_yaml_mapping(full_path, arena_allocator)
    if !map_ok {
        log.errorf("Failed in loading effect reaction from path %v", file_path)
        return
    }

    log.debugf("Loading effect reaction %v", file_path)

    definition_tag := yaml_parse.read_value_from_map(data_map, "definition", string, default = "")
    definition_id, id_ok := effect_definition_tag_to_id[definition_tag]
    if !id_ok {
        log.errorf("Effect reaction %v with definition %v could not resolve such definition", file_path, definition_tag)
    }

    default_data: Maybe(Reaction_Data) = nil
    default_data_map := yaml_parse.read_value_from_map(data_map, "default_reaction_data", yaml.Mapping, default = nil)
    if default_data_map != nil do default_data, _ = reaction_data_read_yaml_map(default_data_map)

    new_reaction_set: Reaction_Set
    reaction_set_create(&new_reaction_set, default_data)

    special_reaction_datas := yaml_parse.read_value_from_map(data_map, "reaction_data_list", yaml.Sequence, default = nil)
    if special_reaction_datas != nil {
        num_combos := len(special_reaction_datas)
        for i in 0..<num_combos {
            // read source, hang frames, and dest scale here to pass through
            combo_map := special_reaction_datas[i].(yaml.Mapping)
            combo_data, combo_tag := reaction_data_read_yaml_map(combo_map)
            if combo_tag != "" do new_reaction_set.reaction_data_map[combo_tag] = combo_data
        }
    }

    global_reaction_manager.table[definition_id] = new_reaction_set
}

reaction_data_read_yaml_map :: proc(yaml_map: yaml.Mapping) -> (data: Reaction_Data, combo_name: Reaction_Data_Tag) {
    data = reaction_data_empty_struct()
    combo_name = strings.clone(yaml_parse.read_value_from_map(yaml_map, "tag", string, default = ""))

    apply_sound := yaml_parse.read_value_from_map(yaml_map, "apply_sound", string, default = "")
    if apply_sound != "" do data.apply_sound = cast(string) strings.clone(apply_sound)

    trigger_sound := yaml_parse.read_value_from_map(yaml_map, "trigger_sound", string, default = "")
    if trigger_sound != "" do data.trigger_sound = cast(string) strings.clone(trigger_sound)

    remove_sound := yaml_parse.read_value_from_map(yaml_map, "remove_sound", string, default = "")
    if remove_sound != "" do data.remove_sound = cast(string) strings.clone(remove_sound)

    flash_color := yaml_parse.read_value_from_map(yaml_map, "flash_color", string, default = "")
    data.flash_color = color.default_palette_color_from_string(flash_color)
    data.flash_duration = cast(f32) yaml_parse.read_value_from_map(yaml_map, "flash_duration", f64, default = 0.0)

    entity_animation_tag := yaml_parse.read_value_from_map(yaml_map, "entity_animation_tag", string, default = "")
    if entity_animation_tag != "" do data.entity_animation_tag = strings.clone(entity_animation_tag)

    external_animation_tag := yaml_parse.read_value_from_map(yaml_map, "external_animation_tag", string, default = "")
    if external_animation_tag != "" do data.external_animation_tag = strings.clone(external_animation_tag)

    data.screen_shake_magnitude = cast(f32) yaml_parse.read_value_from_map(yaml_map, "screen_shake_magnitude", f64, default = 0.0)
    data.show_damage_number = yaml_parse.read_value_from_map(yaml_map, "show_damage_number", bool, default = false)

    show_damage_number_color := yaml_parse.read_value_from_map(yaml_map, "damage_number_color", string, default = "")
    data.show_damage_number_color = color.default_palette_color_from_string(show_damage_number_color)

    return
}