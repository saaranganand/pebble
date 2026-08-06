package horde

import sdl "vendor:sdl3"

import entity "src:entity"
import handle "src:handle"
import util "src:util"

import math "core:math"
import log "core:log"

Grid_Cell :: [dynamic]util.Handle

FOLLOWER_NEIGHBOUR_SEARCH_RADIUS :: 70
SPATIAL_GRID_CELL_SIZE :: FOLLOWER_NEIGHBOUR_SEARCH_RADIUS

Spatial_Grid :: struct {
    cells: map[sdl.Point]Grid_Cell,
    grid_neighbours: [dynamic]util.Handle,
}

spatial_grid_create :: proc(grid: ^Spatial_Grid) {
    grid.cells = make(map[sdl.Point]Grid_Cell)
}

spatial_grid_destroy :: proc(grid: ^Spatial_Grid) {
    for key, cell in grid.cells {
        delete(cell)
    }
    delete(grid.cells)
    delete(grid.grid_neighbours)
}

spatial_grid_get_cell_pos :: proc(world_pos: sdl.FPoint) -> (pos: sdl.Point) {
    pos = { cast(i32) world_pos.x / SPATIAL_GRID_CELL_SIZE, cast(i32) world_pos.y / SPATIAL_GRID_CELL_SIZE }
    return
}

spatial_grid_build :: proc(grid: ^Spatial_Grid) {
    for key, cell in grid.cells {
        delete(cell)
    }
    clear(&grid.cells)

    grid_followers := &global_horde_manager.grid_followers

    i := 0
    for key, horde_followers in grid_followers {
        for &follower in horde_followers {
            defer i += 1
            follower_entity, ok := entity.entity_get(follower, HORDE_TEAM)
            if !ok do continue
            if !follower_entity.active do continue

            cell_pos := spatial_grid_get_cell_pos(follower_entity.collision.position)
            if cell_pos not_in grid.cells {
                grid.cells[cell_pos] = make(Grid_Cell)
            }

            append(&grid.cells[cell_pos], follower)
        }
    }
}

spatial_grid_get_nearby_followers :: proc(grid: ^Spatial_Grid, searcher: util.Handle, position: sdl.FPoint) {
    radius: f32 = FOLLOWER_NEIGHBOUR_SEARCH_RADIUS

    clear(&grid.grid_neighbours)
    center_cell := spatial_grid_get_cell_pos(position)
    radius_squared := radius * radius

    for dx in -1..=1 {
        for dy in -1..=1 {
            cell := center_cell + { i32(dx), i32(dy) }
            if cell not_in grid.cells do continue

            for neighbour_handle in grid.cells[cell] {
                if neighbour_handle == searcher do continue

                neighbour, ok := entity.entity_get(neighbour_handle, HORDE_TEAM)
                if !ok do continue
                if !neighbour.active do continue

                distance := neighbour.collision.position - position
                distance_squared := math.pow(distance.x, 2) + math.pow(distance.y, 2)
                if distance_squared < radius_squared do append(&grid.grid_neighbours, neighbour_handle)
            }
        }
    }
}
