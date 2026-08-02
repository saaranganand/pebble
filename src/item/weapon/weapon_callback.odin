package weapon

import handle "src:handle"

import log "core:log"

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