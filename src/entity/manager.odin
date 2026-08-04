package entity

import sdl "vendor:sdl3"

import handle "src:handle"
import util "src:util"

import hm "core:container/handle_map"
import xar "core:container/xar"
import slice "core:slice"
import rand "core:math/rand"
import log "core:log"

@(private)
global_manager: Entity_Manager

Entity_Manager :: struct {
    entities: [Team]hm.Dynamic_Handle_Map(Entity, util.Handle)
    //pools: [Team]handle.Pool(handle.Entity_Tag, Entity)
}

entity_manager_create :: proc() -> (entity_manager: ^Entity_Manager){
    log.infof("Creating entity manager")

    for team in Team {
        hm.dynamic_init(&global_manager.entities[team], context.allocator)
    }
    
    entity_manager = &global_manager
    return
}

entity_manager_destroy :: proc() {
    log.infof("Destroying entity manager")

    for team in Team {
        pool := &global_manager.entities[team]
        it := hm.iterator_make(pool)
        for e, h in hm.iterate(&it) {
            entity_destroy(e)
        }

        hm.dynamic_destroy(pool)
    }
}

entity_get :: proc(handle: util.Handle, team: Team) -> (entity: ^Entity, ok: bool) {
    entity, ok = hm.get(&global_manager.entities[team], handle)
    
    return 
}

entity_manager_get_random_handle :: proc(team: Team) -> (handle: util.Handle, success: bool) {
    pool_items := &global_manager.entities[team].items
    unused_items := &global_manager.entities[team].unused_items

    if xar.len(pool_items^) <= 0 || xar.len(pool_items^) == xar.len(unused_items^) do return util.Handle{0,0}, false

    option := rand.int32_range(0, cast(i32) xar.len(pool_items^))

    _, found := util.array_linear_search(unused_items, cast(u32) option)
    for found {
        option = rand.int32_range(0, cast(i32) xar.len(pool_items^))
        _, found = util.array_linear_search(unused_items, cast(u32) option)
    }

    return xar.get(pool_items, option).handle, true
}

entity_manager_add_entity :: proc(data: Entity) -> (handle: util.Handle) {
    new_entity := data
    entity_create(&new_entity)

    new_handle, err := hm.add(&global_manager.entities[data.team], new_entity)
    if err != .None {
        log.errorf("Failed adding entity to handle map")
        return
    }

    // TODO -- give entity its own handle
    return new_handle
}

entity_manager_remove_entity :: proc(to_remove: util.Handle, team: Team) {
    e, ok := hm.get(&global_manager.entities[team], to_remove)
    if !ok do return
    
    entity_destroy(e)

    hm.remove(&global_manager.entities[team], to_remove)
}

entity_manager_update :: proc() {
    
    for team in Team {
        pool := &global_manager.entities[team]
        it := hm.iterator_make(pool)
        for e, h in hm.iterate(&it) {
            entity_update(e)
        }
    }
}

entity_manager_draw :: proc() {
    pool := &global_manager.entities[.ENEMY]
    it := hm.iterator_make(pool)
    for e, h in hm.iterate(&it) {
        entity_draw(e)
    }

    pool = &global_manager.entities[.NEUTRAL]
    it = hm.iterator_make(pool)
    for e, h in hm.iterate(&it) {
        entity_draw(e)
    }

    pool = &global_manager.entities[.ALLY]
    it = hm.iterator_make(pool)
    for e, h in hm.iterate(&it) {
        entity_draw(e)
    }
}