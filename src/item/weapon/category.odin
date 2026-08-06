package weapon

import log "core:log"

Category :: enum { MELEE, RANGED, CHARGE, AUTO, AOE, ELEMENTAL }


weapon_category_from_string :: proc(cat_str: string) -> Category {
    switch cat_str {
    case "MELEE":
        return .MELEE
    case "RANGED":
        return .RANGED
    case "CHARGE":
        return .CHARGE
    case "AUTO":
        return .AUTO
    case "AOE":
        return .AOE
    case "ELEMENTAL":
        return.ELEMENTAL
    }

    log.errorf("Passed weapon category from string did not match any expected result for enum")
    log.panic("Please check assets/**/*.weapon.json for 'category' values")
}