package handle

import fmt "core:fmt"

// The handle pool system is for cross-system communication.
// Accessing members of a dynamic array with a pointer does not work!
// Pointers are literal memory addresses, but dyanmic arrays can do all sorts of unreliable things,
// like swap entries, or literally move to an entirely new memory address.
// Even if we don't do any swap removes, and try to access by index, we run into a problem.
// Swap removing means that we dont "remove" at all, and the array will just keep growing.
// But, when lots of things are to be removed (this game), we need some way to recoup that effectively "lost" memory.
// Thus, we mark the items that are inactive, and thus should be removed, and instead write over their position in memory.
// This solves our data problem, but introduces a new one -- if we are storing references to a pool's items by index,
// then what happens to all the references to item A when item A is replaced by item B -- they cant tell A has been replaced!
// We use the very simple system of generation. Items A and B might have the same index, but B will have a generation of +1,
// since B occupied the index after A did: simple! Thus, instead of storing index as a reference, we store index+generation.
// Therefore, when A is replaced, and all of the owners of As references tries to access it, they also check generation,
// and when there is a mismatch, they know that A has been killed in action (RIP).
// This index/generation combination is thus known as a handle. Handles are used for reference to an item in a pool.

// Since we are using a generic handle system, we dont want, say, an entity handle accidentally used in an effect pool.
// Thus, we use this phantom type paramter. Any init of a variable of struct handle will require the user to give a type on top.
// Its not actually used for anything, and so doesn't actually do anything functional.
// What it will do is flag to the compiler that it is a distinct type from other handles with other phantom types.
// Since The same type Tag is required for the pool as well, It is enforced on any interaction with the pool.
Handle :: struct($Handle_Tag: typeid) {
    index: u32,
    generation: u32,
}

// Yes this is a little verbose and boiler-platey, but its needed for cross-communication.
// We need to avoid circular imports, but every package needing a pool will be importing this one,
// So this package cannot import any other package that might use it.
// Not only that, but systems like effect and entity, that share data back and forth, need to access each other's tags.
Effect_Tag :: struct {}
Entity_Tag :: struct {}

// Our generic pool struct does not include data on whether its data entries are "active" or not.
// We still for pool owners, say the effect manager, to be able to know when their data has "died", in order to skip on updates though!
// Thus, it is important that generation is NOT updated on replacement into the data array.
// Instead, generation is done on data "death". At the point where we add the data at index i
// to the free list, we also change generations at index i to be +1.
Pool :: struct($Tag: typeid, $T: typeid) {
    data: [dynamic]T,
    generations: [dynamic]u32,
    free_list: [dynamic]u32,
}

pool_create :: proc($Tag: typeid, $T: typeid) -> (pool: Pool(Tag, T)) {
    pool.data = make([dynamic]T)
    pool.generations = make([dynamic]u32)
    pool.free_list = make([dynamic]u32)
}

pool_destroy :: proc(pool: ^Pool($Tag, $T)) {
    delete(pool.data)
    delete(pool.generations)
    delete(pool.free_list)
}

pool_get :: proc(pool: ^Pool($Tag, $T), handle: Handle(Tag)) -> (^T, bool) {
    if handle.index >= u32(len(pool.generations)) do return nil, false

    if handle.generation != pool.generations[handle.index] do return nil, false

    return &pool.data[handle.index], true
}

pool_add :: proc(pool: ^Pool($Tag, $T), data: T) -> Handle(Tag) {    
    // If we have any free spots, use those first
    if len(pool.free_list) > 0 {
        insert := pop(&pool.free_list)
        pool.data[insert] = data

        return { insert, pool.generations[insert] }
    }

    append(&pool.data, data)
    append(&pool.generations, 0)

    return { insert, 0 }
}

// This here does what we talked about earlier -- when a pool is tasked with "removing" an entry,
// We have to update generation now! Not later.
pool_remove :: proc(pool: ^Pool($Tag, $T), handle: Handle(Tag)) -> bool {
    _, ok := pool_get(pool, handle)
    if !ok do return

    pool.free_list.append(handle.index)
    pool.generations[handle.index] += 1
}