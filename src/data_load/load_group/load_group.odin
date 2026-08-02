package load_group

Load_Group_Proc :: struct {
    load: proc(),
    unload: proc(),
}

Load_Group :: enum{ DEBUG_ALL }

@(rodata)
load_group_procs := [Load_Group]Load_Group_Proc{
    .DEBUG_ALL = { load = debug_all_load, unload = debug_all_unload }
}