package reaction


import color "src:util/color"
import entity "src:entity"

import filepath "core:path/filepath"
import json "core:encoding/json"
import strings "core:strings"
import os "core:os"
import log "core:log"
import fmt "core:fmt"

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
    definition_tag: string,
    default_reaction_data: Maybe(Reaction_Data),
    reaction_data_map: map[string]Reaction_Data,
}

reaction_set_create :: proc(set: ^Reaction_Set, default_data: Maybe(Reaction_Data) = nil) {
    set.default_reaction_data = default_data

    set.reaction_data_map = make(map[string]Reaction_Data)
}

reaction_set_destroy :: proc(set: ^Reaction_Set) {
    for key, &data in set.reaction_data_map {
        delete(key)
        reaction_data_destroy(&data)
    }

    default_reaction_data, ok := &set.default_reaction_data.(Reaction_Data)
    if ok do reaction_data_destroy(default_reaction_data)

    delete(set.reaction_data_map)
    delete(set.definition_tag)
}

effect_reaction_load :: proc(set: ^Reaction_Set, path: string) {
    data, err := os.read_entire_file(path, context.allocator)
	if err != os.General_Error.None {
        log.errorf("Failed to read effect reaction file %v: %v", path, err)
        return
    }
	defer delete(data)

	json_err := json.unmarshal(data, set, spec = .MJSON)
	if json_err != nil {
		log.errorf("Failed to parse effect reaction json file %v: %v", path, json_err)
		return
	}
}
