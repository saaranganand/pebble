# Enemy Types

## The wave / The horde
Picayune dreams-type enemies. A large hordes of slow-moving, non-complex enemies. They gradually move towards the player. May have some basic features like projectiles or teleportation, but otherwise, are very simple.

This (typically) only works for large open maps, without any obstacles -- this avoids having to pathfind for every enemy in the wave.

This enemy is interesting simply because big number. Being able to mow down thousands of enemies, and collecting the drops, if any, from them all, can be stimulating.

This enemy could become more unique if we implemented horde mechanics. I said earlier that obstacles don't work with this enemy, because then each would need to pathfind, and due to the fact that this enemy is essentially a large amount of enemies, it would quickly become too much to compute.

### Horde leaders
However, an idea is that the wave could be replaced by "the horde". The horde would be viable for a map with obstacles, and in fact would be much more interesting in such a map. The idea is that instead of spawning thousands of enemies, the horde spawns dozens of horde leaders. These horde leaders have pathfinding, and possibly much more complex AIs. The horde leaders would each spawn some number of horde followers, ranging from dozens to hundreds.

### Horde followers
Horde followers have no pathfinding, and instead simply mofve towards their horde leader. Horde followers could possibly switch to tracking the player instead once close enough, but I think the idea of mindless enemies following their leader is more interesting. It would also make dodging more interesting -- you need to avoid the leaders of course, but the leaders will have an amorphous blob, almost like a trail of danger behind them. If you added a few mechanics to make the horde followers slightly unpredictable in their movement, then it would make them more involved in the dodging process. Horde followers could either track the player after their leader dies, or move randomly.