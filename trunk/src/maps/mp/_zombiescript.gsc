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
/**
 * @file _zombiescript.gsc Catches legacy RotU map calls and forwards them to _umi.gsc
 * @deprecated  However, this interface will be maintained indefinitely for backward compatibility
 */

#include scripts\include\utility;

setGameMode(mode)
{
    log("trace", "msg|in maps/mp/_zombiescript::setGameMode()||");

    level.isZombiescript = 1;
    maps\mp\_umi::setGameMode(mode);
}

setPlayerSpawns(targetname)
{
    log("trace", "msg|in maps/mp/_zombiescript::setPlayerSpawns()||");

    level.isZombiescript = 1;
    maps\mp\_umi::setPlayerSpawns(targetname);
}

setWorldVision(vision, transitiontime)
{
    log("trace", "msg|in _zombiescript::setWorldVision()||");

    maps\mp\_umi::setWorldVision(vision, transitiontime);
}

buildParachutePickup(targetname)
{
    log("trace", "msg|in _zombiescript::buildParachutePickup()||");

    maps\mp\_umi::buildParachutePickup(targetname);
}

buildWeaponPickup(targetname, itemtext, weapon, type)
{
    log("trace", "msg|in maps/mp/_zombiescript::buildWeaponPickup()||");

    level.isZombiescript = 1;
    maps\mp\_umi::buildWeaponPickup(targetname, itemtext, weapon, type);
}

buildAmmoStock(targetname, loadtime)
{
    log("trace", "msg|in maps/mp/_zombiescript::buildAmmoStock()||");

    level.isZombiescript = 1;
    maps\mp\_umi::buildAmmoStock(targetname, loadtime);
}

// Weaponshop actually
buildWeaponUpgrade(targetname)
{
    log("trace", "msg|in maps/mp/_zombiescript::buildWeaponUpgrade()||");
    
    level.isZombiescript = 1;
    maps\mp\_umi::buildWeaponUpgrade(targetname);
}

setWeaponHandling(id)
{
    log("trace", "msg|in _zombiescript::setWeaponHandling()||");

    maps\mp\_umi::setWeaponHandling(id);
}

setSpawnWeapons(primary, secondary)
{
    log("trace", "msg|in _zombiescript::setSpawnWeapons()||");

    maps\mp\_umi::setSpawnWeapons(primary, secondary);
}

// ONSLAUGHT MODE
/// @deprecated
beginZomSpawning()
{
    log("trace", "msg|in _zombiescript::beginZomSpawning()||");
    log("error", "msg|" + getdvar("mapname") + " calling the deprecated function _zombiescript::beginZomSpawning().||");
    //scripts\gamemodes\_onslaught::startSpawning();
}

//SURVIVAL MODE
// Loading spawns for survival mode (incomming waves)
buildSurvSpawn(targetname, priority)
{
    log("trace", "msg|in _zombiescript::buildSurvSpawn()||");

    level.isZombiescript = 1;
    maps\mp\_umi::buildSurvSpawn(targetname, priority);

}

startSurvWaves()
{
    log("trace", "msg|in maps/mp/_zombiescript::startSurvWaves()||");

    level.isZombiescript = 1;
    maps\mp\_umi::startSurvWaves(); // redirects to maps\mp\_umi::startGame()
}

//GENERAL SCRIPTS
/**
 * @brief Waits until players are in the game before starting the game
 * N.B. Map makers: You *must* precache your resources before you call this function!
 * You can not precache anything after a call to wait().
 *
 * @returns nothing
 */
waittillStart()
{
    log("trace", "msg|in maps/mp/_zombiescript::waittillStart()||");

    level.isZombiescript = 1;
    maps\mp\_umi::waittillStart(); // redirects to maps\mp\_umi::waitUntilFirstPlayerSpawns();
}

buildBarricade(targetname, parts, health, deathFx, buildFx, dropAll)
{
    log("trace", "msg|in _zombiescript::buildBarricade()||");

    level.isZombiescript = 1;
    maps\mp\_umi::buildBarricade(targetname, parts, health, deathFx, buildFx, dropAll);
}
