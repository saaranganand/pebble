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
Charge_Callback :: proc(weapon: ^Weapon_State, owner: handle.Entity_Handle)

weapon_charge_callback_get :: proc(name: string) -> Charge_Callback {
    switch name {
    case "energy_charge":
        return energy_charge_callback
    }

    log.errorf("Tried to load in custom charge callback %v but is not valid", name)
    return nil
}

energy_charge_callback :: proc(weapon: ^Weapon_State, owner: handle.Entity_Handle) {

}