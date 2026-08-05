package item_api

import log "core:log"

Item_API_Tag :: string

API_Item :: struct {
    api_id: uint,
    api_tag: Item_API_Tag,
    api_category: string,
    stack_limit: uint,
}

@(private)
api_item_destroy :: proc(item: ^API_Item) {
    delete(item.api_tag)
    delete(item.api_category)
}

@(private)
api_item_get :: proc(tag: Item_API_Tag) -> (item: ^API_Item, success: bool) {
    item_id, ok := manager.item_tag_to_id_map[tag]
    if !ok {
        log.errorf("Failed to get api item %v: tag does not match to an ID", tag)
        return nil, false
    }
    return &manager.master_items[item_id], true
}