# pebble

developed using odin and sdl3

## setup

get odin and sdl3

git clone

then

git submodule update --init

**run**
make run

## weapons

weapons:

- number key to switch class
- scroll to switch weapon

1. manual (bit pistol, scope)
2. hold (bus, trace)
3. auto (ping, daemon)

## modifiable data

- data/weapons.yaml - base stats for each weapon
- data/programs.yaml - powerup definitions (stat multipliers, effects etc.)
- data/levels.yaml - per-level scaling (damage, hp, program slots)
- data/enemies.yaml - enemy stats