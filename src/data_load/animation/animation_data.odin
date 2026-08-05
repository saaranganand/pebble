package animation

Animation_Data :: struct {
    fps, scale: f32,
    looping: bool,
    frames: []Animation_Frame,
}

animation_data_destroy :: proc(data: ^Animation_Data) {
    delete(data.frames)
}