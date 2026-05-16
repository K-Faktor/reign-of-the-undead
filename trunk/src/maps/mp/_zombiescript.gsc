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

/**
 * @deprecated
 *
 * New maps should call _umi::setGameMode(mode)
 * directly.
 */
setGameMode(mode)
{
    log("trace", "msg|in maps/mp/_zombiescript::setGameMode()||");

    level.isZombiescript = 1;
    maps\mp\_umi::setGameMode(mode);
}

/**
 * @deprecated
 *
 * New maps should call _umi::setPlayerSpawns(targetname)
 * directly.
 */
setPlayerSpawns(targetname)
{
    log("trace", "msg|in maps/mp/_zombiescript::setPlayerSpawns()||");

    level.isZombiescript = 1;
    maps\mp\_umi::setPlayerSpawns(targetname);
}

/**
 * @deprecated
 *
 * New maps should call _umi::setWorldVision(vision, transitiontime)
 * directly.
 */
setWorldVision(vision, transitiontime)
{
    log("trace", "msg|in _zombiescript::setWorldVision()||");

    maps\mp\_umi::setWorldVision(vision, transitiontime);
}

/**
 * @deprecated
 *
 * NOOP. RotU does not support parachute drops.
 */
buildParachutePickup(targetname)
{
    log("trace", "msg|in _zombiescript::buildParachutePickup()||");

    maps\mp\_umi::buildParachutePickup(targetname);
}

/**
 * @deprecated
 *
 * New maps should call _umi::buildWeaponPickupByTargetname(targetname, itemText, weapon, weaponType)
 * directly.
 */
buildWeaponPickup(targetname, itemtext, weapon, type)
{
    log("trace", "msg|in maps/mp/_zombiescript::buildWeaponPickup()||");

    level.isZombiescript = 1;
    maps\mp\_umi::buildWeaponPickup(targetname, itemtext, weapon, type);
}

/**
 * @deprecated
 *
 * New maps should call _umi::buildWeaponShopsByTargetname(targetname, loadTime)
 * directly.
 */
buildAmmoStock(targetname, loadtime)
{
    log("trace", "msg|in maps/mp/_zombiescript::buildAmmoStock()||");

    level.isZombiescript = 1;
    maps\mp\_umi::buildAmmoStock(targetname, loadtime);
}

/**
 * @deprecated
 *
 * New maps should call _umi::buildShopsByTargetname(targetname)
 * directly.
 */
buildWeaponUpgrade(targetname) // equipment shops, actually
{
    log("trace", "msg|in maps/mp/_zombiescript::buildWeaponUpgrade()||");
    
    level.isZombiescript = 1;
    maps\mp\_umi::buildWeaponUpgrade(targetname);
}

/**
 * @deprecated
 *
 * New maps should call _umi::setWeaponHandling(onGiveWeapons)
 * directly.
 */
setWeaponHandling(id)
{
    log("trace", "msg|in _zombiescript::setWeaponHandling()||");

    maps\mp\_umi::setWeaponHandling(id);
}

/**
 * @deprecated
 *
 * New maps should call _umi::setSpawnWeapons(primary, secondary)
 * directly.
 */
setSpawnWeapons(primary, secondary)
{
    log("trace", "msg|in _zombiescript::setSpawnWeapons()||");

    maps\mp\_umi::setSpawnWeapons(primary, secondary);
}

/**
 * @deprecated
 *
 * NOOP. Onslaught mode has been deprecated and removed.
 */
beginZomSpawning()
{
    log("trace", "msg|in _zombiescript::beginZomSpawning()||");
    log("error", "msg|" + getdvar("mapname") + " calling the deprecated function _zombiescript::beginZomSpawning().||");
}

/**
 * @deprecated
 *
 * New maps should call _umi::buildZombieSpawnByTargetname(targetname, priority)
 * directly.
 */
buildSurvSpawn(targetname, priority)
{
    log("trace", "msg|in _zombiescript::buildSurvSpawn()||");

    level.isZombiescript = 1;
    maps\mp\_umi::buildSurvSpawn(targetname, priority);

}

/**
 * @deprecated
 *
 * New maps should call _umi::startGame()
 * directly.
 */
startSurvWaves()
{
    log("trace", "msg|in maps/mp/_zombiescript::startSurvWaves()||");

    level.isZombiescript = 1;
    maps\mp\_umi::startSurvWaves(); // redirects to maps\mp\_umi::startGame()
}

/**
 * @deprecated
 *
 * New maps should call _umi::waitUntilFirstPlayerSpawns()
 * directly.
 */
waittillStart()
{
    // quality:ignore_trace  if we have't bootstrapped, we can't log()

    level.isZombiescript = 1;
    maps\mp\_umi::waittillStart(); // redirects to maps\mp\_umi::waitUntilFirstPlayerSpawns();
}

/**
 * @deprecated
 *
 * New maps should call _umi::buildBarricadesByTargetname(targetname, partCount, health, deathFx, buildFx, dropAll)
 * directly.
 */
buildBarricade(targetname, parts, health, deathFx, buildFx, dropAll)
{
    log("trace", "msg|in _zombiescript::buildBarricade()||");

    level.isZombiescript = 1;
    maps\mp\_umi::buildBarricade(targetname, parts, health, deathFx, buildFx, dropAll);
}
