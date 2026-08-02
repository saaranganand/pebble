package item_api

import log "core:log"

Manager :: struct {
    master_items: []API_Item,
    item_tag_to_id_map: map[Item_API_Tag]uint,
    master_categories: [dynamic]string,

    inventories: [dynamic]API_Inventory,
}

manager: Manager

manager_create :: proc(master_folder: string) {
    log.infof("Creating item API manager")

    manager.master_items, manager.item_tag_to_id_map = implementation_load(API_Item, master_folder, ".itemapi")
    for i in 0..<len(manager.master_items) do manager.master_items[i].api_id = uint(i)

    manager.master_categories = make([dynamic]string)
    manager_table_categories()

    manager.inventories = make([dynamic]API_Inventory)
}

manager_destroy :: proc() {
    log.infof("Destroying item API manager")

    // Keys are deleted by item owners
    delete(manager.item_tag_to_id_map)

    delete(manager.master_categories)

    for &item in manager.master_items {
        api_item_destroy(&item)
    }
    delete(manager.master_items)

    for &inventory in manager.inventories {
        inventory_destroy(&inventory)
    }
    delete(manager.inventories)
}

@(private)
manager_table_categories :: proc() {
    item_loop: for item in manager.master_items {
        for cat in manager.master_categories do if cat == item.api_category do continue item_loop
        append(&manager.master_categories, item.api_category)
    }
}

manager_add_inventory :: proc(valid_categories: ..string) -> (index: uint) {
    index = len(manager.inventories)

    new_inv := inventory_create(index, ..valid_categories)
    append(&manager.inventories, new_inv)

    return
}