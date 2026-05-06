/******************************************************************************
    Reign of the Undead, v2.x

    Copyright (c) 2010-2026 Reign of the Undead Team.
    See AUTHORS.txt for a listing.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal in the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    The contents of the end-game credits must be kept, and no modification of its
    appearance may have the effect of failing to give credit to the Reign of the
    Undead creators.

    Some assets in this mod are owned by Activision/Infinity Ward, so any use of
    Reign of the Undead must also comply with Activision/Infinity Ward's modtools
    EULA.
******************************************************************************/

#include scripts\include\utility;


/**
 * @brief Applies damage to an entity
 *
 * @param eInflictor entity The entity that causes the damage.(e.g. a turret)
 * @param eAttacker entity The entity that is attacking
 * @param iDamage integer The amount of damage done
 * @param sMeansOfDeath string The method of death
 * @param sWeapon string The weapon used to inflict the damage
 * @param damagepos vector The position the damage is from
 * @param damagedir vector The direction the damage is from
 *
 * @returns nothing
 */
damageEnt(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, damagepos, damagedir)
{
    log("trace", "msg|in entities::damageEnt()||");

    if (self.isPlayer) {
        self.damageOrigin = damagepos;
        self.entity thread [[level.callbackPlayerDamage]](
            eInflictor,     // eInflictor The entity that causes the damage.(e.g. a turret)
            eAttacker,      // eAttacker The entity that is attacking.
            iDamage,        // iDamage Integer specifying the amount of damage done
            0,              // iDFlags Integer specifying flags that are to be applied to the damage
            sMeansOfDeath,  // sMeansOfDeath Integer specifying the method of death
            sWeapon,        // sWeapon The weapon number of the weapon used to inflict the damage
            damagepos,      // vPoint The point the damage is from?
            damagedir,      // vDir The direction of the damage
            "none",         // sHitLoc The location of the hit
            0               // psOffsetTime The time offset for the damage
        );
    } else {
        // destructable walls and such can only be damaged in certain ways.
        if (self.isADestructable && (sWeapon == "artillery_mp" || sWeapon == "claymore_mp")) {
            return;
        }

        self.entity notify("damage", iDamage, eAttacker, (0,0,0), (0,0,0), "mod_explosive", "", "" );
    }
}


/**
 * @brief Finds the closest matching entity
 *
 * @param name string The target/class name to search for
 * @param type string The entity property to search, [default=targetname|classname]
 *
 * @returns entity The closest matching entity
 */
getClosestEntity(name, type)
{
    log("trace", "msg|in entities::getClosestEntity()||");

    if (!isdefined(type)) {type = "targetname";}

    ents = getentarray(name, type);
    nearestEnt = undefined;
    nearestDistance = level.MAX_INT; // 2147483647, 32-bit ints
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        distance = distanceSquared(self.origin, ent.origin);

        if(distance < nearestDistance) {
            nearestDistance = distance;
            nearestEnt = ent;
        }
    }
    return nearestEnt;
}


/**
 * @brief Finds the closest player
 *
 * @returns entity The closest matching entity
 */
getClosestPlayer()
{
    log("trace", "msg|in entities::getClosestPlayer()||");

    ents = level.players;
    nearestEnt = undefined;
    nearestDistance = level.MAX_INT; // 2147483647, 32-bit ints
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        distance = distanceSquared(self.origin, ent.origin);

        if(distance < nearestDistance) {
            nearestDistance = distance;
            nearestEnt = ent;
        }
    }
    return nearestEnt;
}


/**
 * @brief Finds the closest players
 *
 * @returns array A sorted array of the closest players; closest at nearPlayers[0]
 */
getClosestPlayerArray()
{
    log("trace", "msg|in entities::getClosestPlayerArray()||");

    playerCount = level.players.size;
    nearPlayers = [];
    distances = [];

    for (i=0; i<level.players.size; i++) {
        player = level.players[i];       
        if (!isDefined(player) || !player.isAlive || !player.isTargetable) {continue;}
            
        nearPlayers[nearPlayers.size] = player;
        distances[distances.size] = distanceSquared(self.origin, player.origin);
    }

    for (i=0; i<nearPlayers.size; i++) {
        for (j=i+1; j<nearPlayers.size; j++) {
            if (distances[j] < distances[i]) {
                // swap distances
                tempDist = distances[i];
                distances[i] = distances[j];
                distances[j] = tempDist;

                // swap players
                tempPlayer = nearPlayers[i];
                nearPlayers[i] = nearPlayers[j];
                nearPlayers[j] = tempPlayer;
            }
        }
    }
    return nearPlayers;
}


/**
 * @deprecated
 * @brief Gets closest alive player
 *
 * @returns entity the closest alive player
 */ 
getClosestTarget()
{
    log("trace", "msg|in entities::getClosestTarget()||");

    ents = level.players;
    nearestEnt = undefined;
    nearestDistance = level.MAX_INT; // 2147483647, 32-bit ints
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        if (!isDefined(ent)) {continue;}
        distance = distanceSquared(self.origin, ent.origin);
        if (ent.isAlive) {
            if (!ent.isTargetable) {continue;}
            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearestEnt = ent;
            }
        }
    }
    return nearestEnt;
}


/**
 * @brief Gets a random entity by targetname
 *
 * @param name string The value of the targetname to return a random example of
 *
 * @returns entity The random entity with a matching targetname value
 */
getRandomEntity(name)
{
    log("trace", "msg|in entities::getRandomEntity()||");

    ents = getentarray(name, "targetname");
    if (ents.size > 0) {
        return ents[randomint(ents.size)];
    }
}


/**
 * @brief Gets a random team deathmatch spawn point
 *
 * @returns entity The random team deathmatch spawnpoint
 */
getRandomTdmSpawn()
{
    log("trace", "msg|in entities::getRandomTdmSpawn()||");

    currentSpawns = getentarray("mp_tdm_spawn", "classname");
    return currentSpawns[randomint(currentSpawns.size)];
}
