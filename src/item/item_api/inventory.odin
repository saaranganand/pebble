package item_api

import log "core:log"

API_Inventory :: struct {
    inventory_id: uint,
    item_counts: map[uint]uint,
    api_categories: [dynamic]string,
}

@(private)
inventory_create :: proc(id: uint, categories: ..string) -> (inventory: API_Inventory) {
    log.infof("Creating new inventory with categories %v", categories)

    inventory.item_counts = make(map[uint]uint)
    inventory.api_categories = make([dynamic]string)
    inventory.inventory_id = id

    for cat in categories {
        append(&inventory.api_categories, cat)
    }
    return
}

@(private)
inventory_destroy :: proc(inventory: ^API_Inventory) {
    delete(inventory.item_counts)
    delete(inventory.api_categories)
}

@(private)
inventory_get :: proc(inventory_id: uint) -> (inventory: ^API_Inventory, success: bool) {
    if inventory_id >= len(manager.inventories) {
        log.errorf("Failed to get inventory %v: index exceeds bounds", inventory_id)
        return nil, false
    }
    return &manager.inventories[inventory_id], true
}

@(private)
inventory_check_category :: proc(inventory: API_Inventory, item: API_Item) -> (match: bool) {
    if len(inventory.api_categories) == 0 do return true
    for cat in inventory.api_categories {
        if cat == item.api_category do return true
    }

    log.errorf("Item %v failed to match category for inventory %v", item.api_tag, inventory.inventory_id)
    return false
}

@(private)
inventory_endpoint_setup :: proc(inventory_id: uint, api_tag: Item_API_Tag) -> (inventory: ^API_Inventory, item: ^API_Item, success: bool) {
    inventory, success = inventory_get(inventory_id)
    if !success do return nil, nil, false

    item, success = api_item_get(api_tag)
    if !success do return nil, nil, false

    success = inventory_check_category(inventory^, item^)
    if !success do return nil, nil, false

    return inventory, item, success
}

inventory_count_item :: proc(inventory_id: uint, api_tag: Item_API_Tag) -> uint {
    inventory, item, success := inventory_endpoint_setup(inventory_id, api_tag)
    if !success do return 0

    return inventory.item_counts[item.api_id]
}

inventory_count_remaining_item :: proc(inventory_id: uint, api_tag: Item_API_Tag) -> uint {
    inventory, item, success := inventory_endpoint_setup(inventory_id, api_tag)
    if !success do return 0

    count := inventory.item_counts[item.api_id]
    return item.stack_limit - count
}

inventory_add_item :: proc(inventory_id: uint, api_tag: Item_API_Tag, count: uint = 1) {
    inventory, item, success := inventory_endpoint_setup(inventory_id, api_tag)
    if !success do return

    if item.api_id not_in inventory.item_counts do inventory.item_counts[item.api_id] = 0
    inventory.item_counts[item.api_id] += count

    if inventory.item_counts[item.api_id] > item.stack_limit {
        inventory.item_counts[item.api_id] = item.stack_limit
        log.warnf(
            "Tried to add %v of item %v to inventory %v, but count was over the stack limit %v. Set count to stack limit.",
            count, api_tag, inventory_id, item.stack_limit
        )
    }
}

inventory_fill_item :: proc(inventory_id: uint, api_tag: Item_API_Tag) {
    inventory, item, success := inventory_endpoint_setup(inventory_id, api_tag)
    if !success do return

    if item.api_id not_in inventory.item_counts do inventory.item_counts[item.api_id] = 0
    inventory.item_counts[item.api_id] = item.stack_limit
}

inventory_remove_item :: proc(inventory_id: uint, api_tag: Item_API_Tag, count: uint = 1) {
    inventory, item, success := inventory_endpoint_setup(inventory_id, api_tag)
    if !success do return

    if item.api_id not_in inventory.item_counts do return

    if count > inventory.item_counts[item.api_id] {
        log.warnf(
            "Tried to remove %v of item %v to inventory %v, but count was over the current stack amount %v. Set count to 0.",
            count, api_tag, inventory_id, inventory.item_counts[item.api_id]
        )
        inventory.item_counts[item.api_id] = 0
        return
    }

    inventory.item_counts[item.api_id] -= count
}

inventory_remove_all_item :: proc(inventory_id: uint, api_tag: Item_API_Tag) {
    inventory, item, success := inventory_endpoint_setup(inventory_id, api_tag)
    if !success do return

    if item.api_id not_in inventory.item_counts do return

    inventory.item_counts[item.api_id] = 0
}

inventory_clear_items :: proc(inventory_id: uint) {
    inventory, success := inventory_get(inventory_id)
    if !success do return

    clear(&inventory.item_counts)
}
