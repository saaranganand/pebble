package projectile

init_proc :: proc(state: ^State, shell: Shell)

@(rodata)
init_procs := #partial [Category]init_proc{
    .BULLET         = circle_init,
    .RAY            = ray_init,
	.AOE            = circle_init,
	.RADIAL         = circle_init,
	.LINE           = line_init
}

circle_init :: proc(state: ^State, shell: Shell) {
    state.shape = Circle{ radius = shell.shape_radius }
}

ray_init :: proc(state: ^State, shell: Shell) {
    state.shape = Ray{}
}

line_init :: proc(state: ^State, shell: Shell) {
    state.shape = Line{ length = shell.shape_length }
}
