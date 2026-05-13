/******************************************************************************
 *    Reign of the Undead, v2.x
 *
 *    Copyright (c) 2010-2026 Reign of the Undead Team.
 *    See AUTHORS.txt for a listing.
 *
 *    Permission is hereby granted, free of charge, to any person obtaining a copy
 *    of this software and associated documentation files (the "Software"), to
 *    deal in the Software without restriction, including without limitation the
 *    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *    sell copies of the Software, and to permit persons to whom the Software is
 *    furnished to do so, subject to the following conditions:
 *
 *    The above copyright notice and this permission notice shall be included in
 *    all copies or substantial portions of the Software.
 *
 *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *    SOFTWARE.
 *
 *    The contents of the end-game credits must be kept, and no modification of its
 *    appearance may have the effect of failing to give credit to the Reign of the
 *    Undead creators.
 *
 *    Some assets in this mod are owned by Activision/Infinity Ward, so any use of
 *    Reign of the Undead must also comply with Activision/Infinity Ward's modtools
 *    EULA.
 ******************************************************************************/

#include maps\mp\_umi;

main()
{
    maps\mp\mp_ancient_fx::main();
    maps\mp\_load::main();
    maps\mp\teleport::main();

    deletePickupItems();
    deleteSabotageEntities();
    deleteHqEntities();
    deleteCtfEntities();
    deleteUnusedSpawnpoints(true, true, true, true);

    maps\mp\_compass::setupMiniMap("compass_map_mp_ancient");
    setdvar("compassmaxrange","2000");

    ambientPlay("ambient_bloc_ext");

    game["allies"] = "marines";
    game["axis"] = "opfor";
    game["attackers"] = "axis";
    game["defenders"] = "allies";
    game["allies_soldiertype"] = "desert";
    game["axis_soldiertype"] = "desert";

    setdvar("r_specularcolorscale", "2");

    thread maps\mp\mp_ancient_final_waypoints::load_waypoints();
    thread maps\mp\mp_ancient_final_tradespawns::load_tradespawns();    
    convertToNativeWaypoints();

    waitUntilFirstPlayerSpawns();

    // play the game
    buildWeaponShopsByTradespawns("0 2 4");
    buildShopsByTradespawns("1 3 5");    

    // prefered method for zombie spawnpoints
    // buildZombieSpawnByTargetname("spawngroup1", 1);
    // buildZombieSpawnByTargetname("spawngroup2", 1);
    // buildZombieSpawnByTargetname("spawngroup3", 1);

    buildManualZombieSpawns((8615, 1516, 15.7));
    buildManualZombieSpawns((8645, 489, 15));
    buildManualZombieSpawns((4983, -2457, 127));
    buildManualZombieSpawns((3279, 4125, 237));
    buildManualZombieSpawns((-1197, 919, 30));
    buildManualZombieSpawns((-1205, 1413, 23));
    buildManualZombieSpawns((-2083, 3260, 42));
    buildManualZombieSpawns((714, 4335, 177));
    buildManualZombieSpawns((4542, 4236, 204));
    devDrawUsedSpawnpoints();

    // An option in lieu of buildManualZombieSpawns() for maps without real zombie spawnpoints
    // buildZombieSpawnsByClassname("mp_dm_spawn");

    startGame();
    
}
