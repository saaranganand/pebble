// runtime programs state: equipping programs and applying their buffs

package main

import reflect "core:reflect"
import strings "core:strings"
import log "core:log"

// weapon stats before any program buffs
// captured at startup
@(private="file")
base_weapons: WeaponConfig

// programs currently equipped (in order)
equipped_programs: [dynamic]^ProgramDef

// every effect application provided by equipped programs
// these are forwarded to the effect system
active_applications: [dynamic]EffectApplication

program_system_create :: proc() {
    base_weapons = game_config.weapons
    equipped_programs = make([dynamic]^ProgramDef)
    active_applications = make([dynamic]EffectApplication)
}

program_system_destroy :: proc() {
    delete(equipped_programs)
    delete(active_applications)
}

// search + equip a loaded program
program_equip :: proc(id: string) -> bool {
    for &def in game_config.programs {
        if def.id == id {
            append(&equipped_programs, &def)
            program_recompute()
            log.infof("program: equipped '%v'", id)
            return true
        }
    }
    log.errorf("program: tried to equip unknown program '%v'", id)
    return false
}

program_unequip :: proc(id: string) -> bool {
    for def, i in equipped_programs {
        if def.id == id {
            ordered_remove(&equipped_programs, i)
            program_recompute()
            log.infof("program: unequipped '%v'", id)
            return true
        }
    }
    return false
}

// rebuilds weapon stats and active effect applications from scratch,
// starting from base stats and applying equipped programs (in order)
@(private="file")
program_recompute :: proc() {
    game_config.weapons = base_weapons
    clear(&active_applications)

    for def in equipped_programs {
        for buff in def.buffs {
            apply_stat_buff(&game_config.weapons, buff)
        }
        for app in def.applies {
            append(&active_applications, app)
        }
    }
}

// applies one stat buff
// can do "damage" or "<weapon>.damage"
apply_stat_buff :: proc(weapons: ^WeaponConfig, buff: StatBuff) {
    dot := strings.index_byte(buff.stat, '.')
    if dot >= 0 {
        if !buff_weapon_stat(weapons, buff.stat[:dot], buff.stat[dot+1:], buff.multiplier) {
            log.errorf("program: unknown stat '%v'", buff.stat)
        }
        return
    }

    // base stat
    // apply to every weapon that has a field with this name
    for field in reflect.struct_fields_zipped(WeaponConfig) {
        buff_weapon_stat(weapons, field.name, buff.stat, buff.multiplier)
    }
}

// multiplies weapons.<weapon_name>.<stat_name> (if it exists and is f32)
@(private="file")
buff_weapon_stat :: proc(weapons: ^WeaponConfig, weapon_name, stat_name: string, multiplier: f32) -> bool {
    weapon_field := reflect.struct_field_by_name(WeaponConfig, weapon_name)
    if weapon_field.name == "" do return false

    stat_field := reflect.struct_field_by_name(weapon_field.type.id, stat_name)
    if stat_field.name == "" || stat_field.type.id != f32 do return false

    stat := (^f32)(uintptr(weapons) + weapon_field.offset + stat_field.offset)
    stat^ *= multiplier
    return true
}
