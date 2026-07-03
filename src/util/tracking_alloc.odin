package util

import log "core:log"
import fmt "core:fmt"
import mem "core:mem"

GLOBAL_TRACKING_ALLOC: mem.Tracking_Allocator

allocate_tracking_alloc :: proc() {
	mem.tracking_allocator_init(&GLOBAL_TRACKING_ALLOC, context.allocator)
}

destroy_tracking_alloc :: proc() {
	mem.tracking_allocator_destroy(&GLOBAL_TRACKING_ALLOC)
}

check_tracking_alloc :: proc() {
	if len(GLOBAL_TRACKING_ALLOC.bad_free_array) == 0 do return
	
	for b in GLOBAL_TRACKING_ALLOC.bad_free_array {
		log.errorf("Bad free at: %v", b.location)
	}

	panic("Bad free detected!")
}

report_tracking_alloc :: proc() {
	defer mem.tracking_allocator_clear(&GLOBAL_TRACKING_ALLOC)

	if len(GLOBAL_TRACKING_ALLOC.allocation_map) == 0 {
		log.debug("No memory leaks =)")
		return
	}

	log.debug("\n\n\n")
	log.debug("== MEMORY LEAKS ==")
	for _, value in GLOBAL_TRACKING_ALLOC.allocation_map {
		log.errorf("%v: Leaked %v bytes", value.location, value.size)
	}
}