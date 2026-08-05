package npc

import "src:sdl_primatives"
NPC_Manager :: struct {
    definitions: []NPC_Definition,
    num_definitions: uint,
    definition_id_map: map[string]uint,
}

@(private)
global_manager: NPC_Manager