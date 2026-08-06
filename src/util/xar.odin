package util

import intrinsics "base:intrinsics"
import xar "core:container/xar"
import log "core:log"

@(require_results)
array_linear_search :: proc(x: ^$X/xar.Array($T, $SHIFT), elem: T) -> (index: int, found: bool) where intrinsics.type_is_comparable(T) {
	it := xar.array_iterator(x)
	for val, i in xar.array_iterate_by_val(&it) {
		if val == elem {
			return i, true
		}
	}
	return -1, false
}