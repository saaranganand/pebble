// loads yamls into game_config at startup

package main

import yaml "../libs/odin-yaml"
import fmt "core:fmt"
import mem "core:mem"
import strings "core:strings"

//import horde "src:entity/entity_horde"


// Weapon

BitPistolConfig :: struct {
    damage: f32,
    fire_rate: f32, // shots per s
    miss_chance: f32, // P(bullet does 0 dmg)
    bullet_speed: f32, // pixels/s
    bullet_size: f32, // pixels
}

ScopeConfig :: struct {
    damage: f32,
    max_charge: f32, // how many s for scope to max charge
}

BusConfig :: struct {
    damage: f32, // per s, normalized by dt since its a beam
    max_heat: f32, // s to overheat
}

TraceConfig :: struct {
    damage: f32,
    cooldown: f32, // s b/w missiles
    turn_speed: f32, // rad/s
    bullet_speed: f32, // pixels/s
    bullet_size: f32, // pixels
}

PingConfig :: struct {
    damage: f32,
    max_radius: f32, // how far a ping wave extends
    expand_speed: f32, // how fast a ping wave extends (pixels/s)
    duration: f32, // s
}

DaemonConfig :: struct {
    damage: f32,
    fire_rate: f32, // shots per s
    orbit_radius: f32, // how far from the player daemon orbits (pixels)
    orbit_speed: f32, // how fast daemon orbits player (rad/s)
    duration: f32, // s
    cone_angle: f32, // arc its allowed to fire in the direction its facing
}

WeaponConfig :: struct {
    bitpistol: BitPistolConfig,
    scope: ScopeConfig,
    bus: BusConfig,
    trace: TraceConfig,
    ping: PingConfig,
    daemon: DaemonConfig,
}

// Enemy

EnemyConfig :: struct {
    spawn_rate: f32, // s b/w spawns
    spawn_dist: f32, // pixels from player
    //horde: horde.Config, // leader/follower stuff, passed to horde.create
}

// Player

PlayerConfig :: struct {
    max_hp: f32,
    speed: f32, // pixels/s
    size: f32, // pixels, hitbox
}

LevelConfig :: struct {
    damage_per_level: f32, // percent multiplier added per level
    hp_per_level: f32, // additional max HP
    slots_per_level: int, // extra program slots per level
}

// Programs

// one stat multiplier
StatBuff :: struct {
    stat: string,
    multiplier: f32,
}

// one status effect this program makes your hits apply
// effect is a tag matching an effect definition ("burn", "frost_slow", ...)
EffectApplication :: struct {
    effect: string,
    damage: f32,
    duration: f32,
}

ProgramDef :: struct {
    id: string,
    buffs: [dynamic]StatBuff,
    applies: [dynamic]EffectApplication,
}

// ---

// top level config used at startup
GameConfig :: struct {
    player: PlayerConfig,
    weapons: WeaponConfig,
    enemies: EnemyConfig,
    programs: [dynamic]ProgramDef,
    levels: LevelConfig,
}

game_config: GameConfig

// yaml value to f32
@(private)
yf :: proc(m: yaml.Mapping, key: string) -> f32 {
    v, ok := m[key]
    if !ok {
        return 0
    }
    #partial switch x in v {
    case f64:
        return f32(x)
    case i64:
        return f32(x)
    }
    return 0
}

// call before game loop
load_configs :: proc() -> bool {
    // trying out arena allocation for config
    arena_memory := make([]byte, 1*mem.Megabyte)
    defer delete(arena_memory)

    config_arena: mem.Arena
    mem.arena_init(&config_arena, arena_memory)
    arena_alloc := mem.arena_allocator(&config_arena)

    //!load_enemies(arena_alloc) || 
    if !load_player(arena_alloc) || !load_weapons(arena_alloc) || !load_programs(arena_alloc) || !load_levels(arena_alloc) {
        return false
    }
    return true
}

// --------------------------------

// LOAD PROCS

@(private)
load_player :: proc(allocator: mem.Allocator) -> bool {
    doc, err := yaml.decode_from_file("data/player.yaml", allocator)
    if err != nil {
        fmt.eprintln("config: failed to load data/player.yaml")
        return false
    }
    m, ok := doc.(yaml.Mapping)
    if !ok { return true }
    game_config.player = {
        max_hp = yf(m, "max_hp"),
        speed = yf(m, "speed"),
        size = yf(m, "size"),
    }
    return true
}

@(private)
load_weapons :: proc(allocator: mem.Allocator) -> bool {
    doc, err := yaml.decode_from_file("data/weapons.yaml", allocator)
    
    if err != nil {
        fmt.eprintln("config: failed to load data/weapons.yaml")
        return false
    }
    m, ok := doc.(yaml.Mapping)
    if !ok {
        return true
    }

    bp := m["bitpistol"].(yaml.Mapping)
    game_config.weapons.bitpistol = {
        damage = yf(bp, "damage"),
        fire_rate = yf(bp, "fire_rate"),
        miss_chance = yf(bp, "miss_chance"),
        bullet_speed = yf(bp, "bullet_speed"),
        bullet_size = yf(bp, "bullet_size"),
    }

    sc := m["scope"].(yaml.Mapping)
    game_config.weapons.scope = {
        damage = yf(sc, "damage"),
        max_charge = yf(sc, "max_charge"),
    }

    bu := m["bus"].(yaml.Mapping)
    game_config.weapons.bus = {
        damage = yf(bu, "damage"),
        max_heat = yf(bu, "max_heat"),
    }

    tr := m["trace"].(yaml.Mapping)
    game_config.weapons.trace = {
        damage = yf(tr, "damage"),
        cooldown = yf(tr, "cooldown"),
        turn_speed = yf(tr, "turn_speed"),
        bullet_speed = yf(tr, "bullet_speed"),
        bullet_size = yf(tr, "bullet_size"),
    }

    pg := m["ping"].(yaml.Mapping)
    game_config.weapons.ping = {
        damage = yf(pg, "damage"),
        max_radius = yf(pg, "max_radius"),
        expand_speed = yf(pg, "expand_speed"),
        duration = yf(pg, "duration"),
    }

    dm := m["daemon"].(yaml.Mapping)
    game_config.weapons.daemon = {
        damage = yf(dm, "damage"),
        fire_rate = yf(dm, "fire_rate"),
        orbit_radius = yf(dm, "orbit_radius"),
        orbit_speed  = yf(dm, "orbit_speed"),
        duration = yf(dm, "duration"),
        cone_angle = yf(dm, "cone_angle"),
    }
    return true
}
/*
@(private)
load_horde_entity :: proc(m: yaml.Mapping, key: string) -> horde.Entity_Config {
    em, ok := m[key].(yaml.Mapping)
    if !ok { return {} }
    return {
        health = yf(em, "health"),
        speed = yf(em, "speed"),
        size = yf(em, "size"),
    }
}

@(private)
load_enemies :: proc(allocator: mem.Allocator) -> bool {
    doc, err := yaml.decode_from_file("data/enemies.yaml", allocator)
    if err != nil {
        fmt.eprintln("config: failed to load data/enemies.yaml")
        return false
    }
    m, ok := doc.(yaml.Mapping)
    if !ok { return true }

    game_config.enemies = {
        spawn_rate = yf(m, "spawn_rate"),
        spawn_dist = yf(m, "spawn_dist"),
        horde = {
            leader = load_horde_entity(m, "leader"),
            follower = load_horde_entity(m, "follower"),
            followers_per_leader = int(yf(m, "followers_per_leader")),
        },
    }
    

    return true
}*/

@(private)
load_programs :: proc(allocator: mem.Allocator) -> bool {
    doc, err := yaml.decode_from_file("data/programs.yaml", allocator)
    
    if err != nil {
        fmt.eprintln("config: failed to load data/programs.yaml")
        return false
    }
    seq, ok := doc.(yaml.Sequence)
    if !ok {
        return true
    }

    for item in seq {
        pm := item.(yaml.Mapping)
        def: ProgramDef
        // yaml doc lives in a temp arena, so clone strings we keep
        def.id = strings.clone(pm["id"].(string))

        // optional stat buffs
        if buffs_val, has_buffs := pm["buffs"]; has_buffs {
            if buffs_seq, is_seq := buffs_val.(yaml.Sequence); is_seq {
                for b in buffs_seq {
                    bm := b.(yaml.Mapping)
                    append(&def.buffs, StatBuff{
                        stat = strings.clone(bm["stat"].(string)),
                        multiplier = yf(bm, "multiplier"),
                    })
                }
            }
        }

        // optional effect applications
        if applies_val, has_applies := pm["applies"]; has_applies {
            if applies_seq, is_seq := applies_val.(yaml.Sequence); is_seq {
                for a in applies_seq {
                    am := a.(yaml.Mapping)
                    append(&def.applies, EffectApplication{
                        effect = strings.clone(am["effect"].(string)),
                        damage = yf(am, "damage"),
                        duration = yf(am, "duration"),
                    })
                }
            }
        }

        append(&game_config.programs, def)
    }

    return true
}

@(private)
load_levels :: proc(allocator: mem.Allocator) -> bool {
    doc, err := yaml.decode_from_file("data/levels.yaml", allocator)

    if err != nil {
        fmt.eprintln("config: failed to load data/levels.yaml")
        return false
    }
    m, ok := doc.(yaml.Mapping)
    if !ok { 
        return true 
    }

    game_config.levels = {
        damage_per_level = yf(m, "damage_per_level"),
        hp_per_level = yf(m, "hp_per_level"),
        slots_per_level = int(yf(m, "slots_per_level")),
    }
    

    return true
}
