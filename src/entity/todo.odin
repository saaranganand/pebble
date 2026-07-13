package entity

import handle "../handle"
import geo "../geometry"

// TODO: implement these procs
query_entities_in_radius :: proc(geo.Circle) -> []Entity_Handle
apply_effect_to_entity :: proc(target: Entity_Handle, def: ^Effect_Definition, source: Entity_Handle)
