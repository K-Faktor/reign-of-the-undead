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

/** @file _unified_mapping_interface.gsc An unified interface specification for
 * maps into CoD4 zombie mods.  Each mod should copy this interface as
 * @code maps\mp\_umi.gsc @endcode and then implement the specified interface in
 * @code _umi.gsc @endcode as required for their mod.
 *
 * Attention Mappers:
 *      Use `#include maps\mp\_umi.gsc` in your main map file--
 *      not `#include maps\mp\_unified_mapping_interface.gsc`.
 *
 *      This file is auto-generated, and doesn't contain the implementation.
 *      It is a reference to methods we make available for mapmakers.
 */

/**
 * @brief Returns the lower-cased name of the mod that is trying to load the map
 *
 * @returns string The name of the mod, e.g. "rotu", "rozo", etc
 * @since RotU 2.2.1
 */
modName() {}


/**
 * @brief Returns the native type of the map being loaded
 *
 * @returns string The native type of the map, e.g. "rotu", "rozo", etc.
 * @since RotU 2.2.1
 */
nativeMapType() {}


/**
 * @brief Sets the native type of the map being loaded
 *
 * @param nativeMapType string The native type of the map, e.g. "rotu", "rozo", etc.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
setNativeMapType(nativeMapType) {}


/**
 * @brief UMI Converts CSV waypoints to BTD waypoints, and prints them to the server log
 * It prints the BTD function, but will require the timecodes to be removed from the
 * front the the line, as well as any extraneous info printed to the log at the
 * same time by other functions.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
devDumpCsvWaypointsToBtd() {}


/**
 * @brief UMI Converts BTD waypoints to CSV waypoints, and prints them to the server log
 * It prints the contents of the *.csv file, but will require the timecodes to be removed from the
 * front the the line, as well as any extraneous info printed to the log at the
 * same time by other functions.
 *
 * This function must be called immediately after load_waypoints(), e.g.
 * @code
 * maps\mp\mp_burgundy_bulls_waypints::load_waypoints();
 * devDumpBtdWaypointsToCsv();
 * @endcode
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
devDumpBtdWaypointsToCsv() {}


/**
 * @brief UMI deletes from memory unused spawn entities from maps
 *
 * On some maps, deleting unused spawnpoints and other entities can triple or
 * quadruple the speed of the getEntArray() and related functions.
 *
 * @param deleteSab boolean Delete all the sabatage spawnpoints?
 * @param deleteSd boolean Delete all the search and destroy spawnpoints?
 * @param deleteDom boolean Delete all the domination spawnpoints?
 * @param deleteCtf boolean Delete all the capture the flag spawnpoints?
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteUnusedSpawnpoints(deleteSab, deleteSd, deleteDom, deleteCtf) {}


/**
 * @brief UMI deletes from memory unused capture the flag entities from maps
 *
 * On some maps, deleting unused spawnpoints and other entities can triple or
 * quadruple the speed of the getEntArray() and related functions.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteCtfEntities() {}


/**
 * @brief UMI deletes built-in turrets from maps
 *
 * @returns nothing
 * @since RotU 2.2.2
 */
deleteTurrets() {}


/**
 * @brief UMI deletes from memory unused headquarters entities from maps
 *
 * On some maps, deleting unused spawnpoints and other entities can triple or
 * quadruple the speed of the getEntArray() and related functions.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteHqEntities() {}


/**
 * @brief UMI changes the model of barrels to be a blue rusty barrel
 *
 * @param targetname string The targetname parameter of the barrel entity
 *
 * Some maps have stock barrels that look like RotU's regular, exploding, or MG+Barrels.
 * This function lets us change the model to a blue barrel so players don't get
 * confused.
 *
 * Use maps\mp\_umiEditor::devDumpEntities() to dump entities to the server log.
 *
 * @returns nothing
 * @since RotU 2.2.2
 */
disambiguateBarrelsByTargetname(targetname) {}


/**
 * @brief UMI deletes from memory unused sabotage entities from maps
 *
 * On some maps, deleting unused spawnpoints and other entities can triple or
 * quadruple the speed of the getEntArray() and related functions.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteSabotageEntities() {}


/**
 * @brief Loads a central trap specified in the map
 *
 * @param trigger string The targetname of the entity with a classname of 'trigger_use_touch' used by player to activate the trap
 * @param bat string The targetname of a 'script_brushmodel' for the spinning battering rams
 * @param base string The targetname of a 'script_brushmodel' for the spinning base
 * @param activator string The targetname of a 'script_brushmodel' used by player to activate the trap
 * @param price integer The cost to activate the trap
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadCentralTrap(trigger, bat, base, activator, price) {}


/**
 * @brief Loads a rotating trap specified in the map
 *
 * @param trigger string The targetname of the entity with a classname of 'trigger_use_touch' used by player to activate the trap
 * @param death string The targetname of a 'script_brushmodel' used to locate the kill trigger
 * @param activator string The targetname of a 'script_brushmodel' used by player to activate the trap
 * @param price integer The cost to activate the trap
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadRotatingTrap(trigger, death, activator, price) {}


/**
 * @brief Loads a spike trap specified in the map
 *
 * @param trigger string The targetname of the entity with a classname of 'trigger_use_touch' used by player to activate the trap
 * @param death string The targetname of a 'script_brushmodel' used to locate the kill trigger
 * @param activator string The targetname of a 'script_brushmodel' used by player to activate the trap
 * @param price integer The cost to activate the trap
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadSpikeTrap(trigger, death, activator, price) {}


/**
 * @brief Loads a fire trap specified in the map
 *
 * @param trigger string The targetname of the entity with a classname of 'trigger_use_touch' used by player to activate the trap
 * @param fire1 string The targetname of a 'script_brushmodel' for a fire location
 * @param fire2 string The targetname of a 'script_brushmodel' for a fire location
 * @param fire3 string The targetname of a 'script_brushmodel' for a fire location
 * @param fire4 string The targetname of a 'script_brushmodel' for a fire location
 * @param death string The targetname of a 'script_brushmodel' used to locate the kill trigger
 * @param activator string The targetname of a 'script_brushmodel' used by player to activate the trap
 * @param price integer The cost to activate the trap
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadFireTrap(trigger, fire1, fire2, fire3, fire4, death, activator, price) {}


/**
 * @brief Loads an electric trap specified in the map
 *
 * @param trigger string The targetname of the entity with a classname of 'trigger_use_touch' used by player to activate the trap
 * @param elec1 string The targetname of a 'script_brushmodel' for an arcing point
 * @param elec2 string The targetname of a 'script_brushmodel' for an arcing point
 * @param elec3 string The targetname of a 'script_brushmodel' for an arcing point
 * @param elec4 string The targetname of a 'script_brushmodel' for an arcing point
 * @param elec5 string The targetname of a 'script_brushmodel' for an arcing point
 * @param elec6 string The targetname of a 'script_brushmodel' for an arcing point
 * @param death string The targetname of a 'script_brushmodel' used to locate the kill trigger
 * @param activator string The targetname of a 'script_brushmodel' used by player to activate the trap
 * @param price integer The cost to activate the trap
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadElectricTrap(trigger, elec1, elec2, elec3, elec4, elec5, elec6, death, activator, price) {}


/**
 * @brief Loads a glide pad specified in the map
 *
 * A glide pad, when triggered, moves a player from point to point to point, over time
 *
 * @param trigger string The targetname of the entity with a classname of 'trigger_multiple'
 * @param origin1 string The targetname of the entity with a classname of 'script_origin'
 * @param origin2 string The targetname of the entity with a classname of 'script_origin'
 * @param origin3 string The targetname of the entity with a classname of 'script_origin'
 * @param origin4 string The targetname of the entity with a classname of 'script_origin'
 * @param origin5 string The targetname of the entity with a classname of 'script_origin'
 * @param origin6 string The targetname of the entity with a classname of 'script_origin'
 * @param velocity integer distance to move the player per second
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadGlidePad(trigger, origin1, origin2, origin3, origin4, origin5, origin6, velocity) {}


/**
 * @brief Loads a continuous animation
 *
 * @param model string The targetname of the entity with a classname of 'script_brushmodel'
 * @param type string The type of motion. One of [linear|rotate]
 * @param steps array An array of step structs
 *      If \c type is "linear", the step struct has members:
 *          .origin
 *          .destination
 *          .velocity, a distance to travel per second
 *          .delay, how long to wait before doing the next step
 *      If \c type is "rotate", the step struct has members:
 *          .fromAngles
 *          .toAngles
 *          .velocity, in degrees per second
 *          .delay, how long to wait before doing the next step
 * @param reversible boolean Should the animation be reversed between each cycle?
 * @param delay integer time in seconds to wait before doing the next iteration of the animation
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadCyclicalAnimation(model, type, steps, reversible, delay) {}


/**
 * @brief Loads an elevator or moving platform from a map
 *
 * @param model string The targetname of the entity with a classname of 'script_brushmodel'
 * @param trigger string The targetname of the entity with a classname of 'trigger_use_touch'
 * @param positionA tuple The location of the elevator at position A
 * @param positionB tuple The location of the elevator at position B
 * @param velocity integer distance to move the elevator per second
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadElevator(model, trigger, positionA, positionB, velocity) {}


/**
 * @brief Loads a teleporter specified in a map
 *
 * @param trigger string The targetname of the entity with a classname of 'trigger_multiple'
 * @param destination string The targetname of the entity with a classname of 'script_origin'
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadMapTeleporter(trigger, destination) {}


/**
 * @brief Loads a hurt trigger specified in a map
 *
 * @param trigger string The classname of the entities with a classname of 'trigger_hurt'
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadHurtTriggers(trigger) {}


/**
 * @brief UMI to build equipment stores by tradespawns
 *
 * @param equipmentShops string Space-separated list of tradespawn array indices,
 * e.g. @code buildShopsByTradespawns("1 3 5 7"); @endcode
 * @param havePrefabModels boolean Does the map already have prefab shop models
 *
 * @pre tradespawns have been loaded into level.tradespawns
 * @returns nothing
 * @since RotU 2.2.1
 */
buildShopsByTradespawns(equipmentShops, havePrefabModels) {}


/**
 * @brief UMI to build equipment shops by targetname
 *
 * @param targetname string The name of the entities' targetname attribute,
 * e.g. @code buildShopsByTargetname("weaponupgrade"); @endcode
 *
 * "weaponupgrade" is the targetname traditionally used by RotU
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildShopsByTargetname(targetname) {}


/**
 * @brief UMI to build weapons shop/upgrade by targetname
 *
 * @param targetname string The name of the entities' targetname attribute,
 * e.g. @code buildWeaponShopsByTargetname("ammostock"); @endcode
 * "ammostock" is the targetname traditionally used by RotU
 * @param loadTime int ???
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildWeaponShopsByTargetname(targetname, loadTime) {}


/**
 * @brief UMI to build weapons shop/upgrade by tradespawns
 *
 * @param weaponShops string Space-separated list of tradespawn array indices,
 * e.g. @code buildWeaponShopsByTradespawns("0 2 4 6"); @endcode
 * @param havePrefabModels boolean Does the map already have prefab weapon shop models
 *
 * @pre tradespawns have been loaded into level.tradespawns
 * @returns nothing
 * @since RotU 2.2.1
 */
buildWeaponShopsByTradespawns(weaponShops, havePrefabModels) {}


/**
 * @brief UMI converts BTD/ROZO waypoints into RotU waypoints
 *
 * @pre waypoints loaded into memory in level.waypoints
 * @returns nothing
 * @since RotU 2.2.1
 */
convertToNativeWaypoints() {}


/**
 * @brief Preferentially loads external waypoints, falls-back to internal waypoints
 *
 * @pre waypoints loaded into memory in level.waypoints
 * @returns nothing
 * @since RotU 2.2.1
 */
loadWaypoints() {}


/**
 * @brief UMI to build zombie spawn points by the entities' classname property
 *
 * @param classname string The value of the entities' classname property
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildZombieSpawnsByClassname(classname) {}


/**
 * @brief UMI to build a zombie spawn point by an entity's targetname property
 *
 * @param targetname string The value of the entities' targetname property
 * @param priority int A zombie has a (priority / totalPriority) chance of being spawned here
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildZombieSpawnByTargetname(targetname, priority) {}


/**
 * @brief UMI to build player spawn points by entities' classname property
 *
 *        NOOP. RotU doesn't need to add player spawns
 *
 * @param classname string The value of the classname to use for player spawn points
 * @param enabled boolean ???
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
addPlayerSpawnsByClassname(classname, enabled) {}


/**
 * @brief UMI to build player spawn points by entities' targetname property
 *
 *        NOOP. RotU doesn't need to add player spawns
 *
 * @param targetname string The value of the targetname to use for player spawn points
 * @param enabled boolean ???
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
addPlayerSpawnsByTargetname(targetname, enabled) {}


/**
 * @brief UMI builds all barricades of the given targetname in the map
 *
 * @param targetname string The value of the entities' targetname property
 * @param partCount int The number of parts in barricades with this targetname
 * @param health int The initial and max hitpoints for the barricade
 * @param deathFx object A precached effect (via loadFx()) played when the barricade is destroyed
 * @param buildFx object A precached effect (via loadFx()) played when the barricade is rebuilt
 * @param dropAll boolean Optional, defaults to false
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildBarricadesByTargetname(targetname, partCount, health, deathFx, buildFx, dropAll) {}


/**
 * @brief UMI builds all barricades of the given classname in the map
 *
 *        NOOP. RotU doesn't build barricades by classname
 *
 * @param classname string The value of the entities' classname property
 * @param partCount int The number of parts in barricades with this targetname
 * @param health int The initial and max hitpoints for the barricade
 * @param deathFx object A precached effect (via loadFx()) played when the barricade is destroyed
 * @param buildFx object A precached effect (via loadFx()) played when the barricade is rebuilt
 * @param dropAll boolean Optional, defaults to false
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildBarricadesByClassname(classname, partCount, health, deathFx, buildFx, dropAll) {}


/**
 * @brief UMI builds weapons that can be picked up based on a targetname
 *
 * @param targetname string The name of the entities' targetname property
 * @param itemText string The English name of the weapon
 * @param weapon string The game name of the weapon, i.e. m14_mp
 * @param weaponType string The type of the weapon
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildWeaponPickupByTargetname(targetname, itemText, weapon, weaponType) {}


/**
 * @brief UMI builds weapons that can be picked up based on a classname
 *
 *        NOOP. RotU doesn't build pickup weapons by classname
 *
 * @param classname string The name of the entities' classname property
 * @param itemText string The English name of the weapon
 * @param weapon string The game name of the weapon, i.e. m14_mp
 * @param weaponType string The type of the weapon
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildWeaponPickupByClassname(classname, itemText, weapon, weaponType) {}


/**
 * @brief UMI stops loading the map until the first player is actually ready to play
 *
 * Call this function before calling any map functions that require at least one
 * player to be in the game.
 *
 * Implements the old waittillStart() call.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
waitUntilFirstPlayerSpawns() {}


/**
 * @brief UMI begins the actual gameplay
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
startGame() {}


/**
 * @brief UMI deletes all entities with the given classname property
 *
 * @param classname string The value of the entities' classname property
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteEntitiesByClassname(classname) {}


/**
 * @brief UMI deletes all entities with the given targetname property
 *
 * @param targetname string The value of the entities' targetname property
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteEntitiesByTargetname(targetname) {}


/**
 * @brief UMI deletes entities with a targetname of "oldschool_pickup"
 *
 * This deletes weapon and perk pickups on CoD4 stock maps, like mp_bog
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deletePickupItems() {}


/**
 * @brief UMI deletes from memory nearby entities
 *
 * We use separate calculations for 2D distance first, followed by vertical distance,
 * as this is more discriminating than simply using a 3D distance.
 *
 * @param origin vector The location to use as a basis for comparisions
 * @param maximumDistance2D integer The maximum xy-planar distance between the reference and entity origins
 * @param maxDeltaHeight integer The maximum difference in z-axis position bewteen the refernce and entity origins
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteNearbyEntities(origin, maximumDistance2D, maxDeltaHeight) {}


/**
 * @brief If both BTD and CVS waypoints are available, prefer the BTD waypoints?
 *
 * @returns boolean Whether the mapper or server operator prefers the BTD waypoints
 * @since RotU 2.2.1
 */
preferBtdWaypoints() {}


/**
 * @brief Is this map using the unified mapping interface?
 *
 * @returns boolean true if the map uses UMI, false otherwise
 * @since RotU 2.2.1
 */
isUmiMap() {}


/**
 * @brief Attempts to determine the name of the mod loading the map
 * @private
 *
 * @returns string The name of the mod, or an empty string if undetermined
 * @since RotU 2.2.1
 */
privateGuessModName() {}


/**
 * @brief A hook for a function to initialize waypoints. NOOP.
 * @reserved
 *
 * @returns nothing
 */
initWaypoints() {}


/**
 * @brief A hook for a function to initialize game setup. NOOP.
 * @reserved
 *
 * @returns nothing
 */
initSetup() {}


/**
 * @brief A hook for a function to initialize barricades. NOOP.
 * @reserved
 *
 * @returns nothing
 */
initBarricades() {}


/**
 * @brief A hook for a function to load tradespawns. NOOP.
 * @reserved
 *
 * @returns nothing
 */
loadTradespawn() {}


/**
 * @brief Builds weapon shops for RotU maps using old _zombiescript.gsc calls
 *
 *        Compatability method. Catches calls to _zombiescript::buildAmmoStock()
 *        when the include is simply changed from _zombiescript.gsc to _umi.gsc.
 *
 *        New maps, or a complete porting job, should call
 *        _umi::buildWeaponShopsByTargetname(targetname, loadTime) directly.
 *
 * @param targetname string The value of the entities' targetname property
 * @param loadTime int ???
 *
 * @returns nothing
 */
buildAmmoStock(targetname, loadTime) {}


/**
 * @brief Builds equipment shops for RotU maps using old _zombiescript.gsc calls
 *
 *        Compatability method. Catches calls to _zombiescript::buildWeaponUpgrade()
 *        when the include is simply changed from _zombiescript.gsc to _umi.gsc.
 *
 *        New maps, or a complete porting job, should call
 *        _umi::buildShopsByTargetname(targetname) directly.
 *
 * @param targetname string The value of the entities' targetname property
 *
 * @returns nothing
 */
buildWeaponUpgrade(targetname) {}


/**
 * @brief Builds a zombie spawn point for RotU maps using old _zombiescript.gsc calls
 *
 *        Compatability method. Catches calls to _zombiescript::buildSurvSpawn()
 *        when the include is simply changed from _zombiescript.gsc to _umi.gsc.
 *
 *        New maps, or a complete porting job, should call
 *        _umi::buildZombieSpawnByTargetname(targetname, priority) directly.
 *
 * @param targetname string The value of the entities' targetname property,
 *                          traditionally "spawngroup[n]", where n is an integer
 * @param priority int A zombie has a priority / totalPriority chance of being spawned here
 *
 * @returns nothing
 */
buildSurvSpawn(targetname, priority) {}


/**
 * @brief Waits to start the game until the first player chooses their class and is spawned.
 *
 *        You *must* precache() or load() all your map's items *before* any call to any
 *        of the 'wait' methods.
 *
 *        Compatability method. Catches calls to _zombiescript::waittillStart()
 *        when the include is simply changed from _zombiescript.gsc to _umi.gsc.
 *
 *        New maps, or a complete porting job, should call
 *        _umi::waitUntilFirstPlayerSpawns() directly.
 *
 * @returns nothing
 */
waittillStart() {}


/**
 * @brief Begins the first wave of a RotU survival game
 *
 *        Compatability method. Catches calls to _zombiescript::startSurvWaves()
 *        when the include is simply changed from _zombiescript.gsc to _umi.gsc.
 *
 *        New maps, or a complete porting job, should call
 *        _umi::startGame() directly.
 *
 * @returns nothing
 */
startSurvWaves() {}


/**
 * @brief Builds all barricades of the given targetname in the map
 *
 *        Compatability method. Catches calls to _zombiescript::buildBarricade()
 *        when the include is simply changed from _zombiescript.gsc to _umi.gsc.
 *
 *        New maps, or a complete porting job, should call
 *        _umi::buildBarricadesByTargetname(targetname, partCount, health, deathFx, buildFx, dropAll) directly.
 *
 * @param targetname string The value of the entities' targetname property
 * @param partCount int The number of parts in barricades with this targetname
 * @param health int The initial and max hitpoints for the barricade
 * @param deathFx object A precached effect (via loadFx()) played when the barricade is destroyed
 * @param buildFx object A precached effect (via loadFx()) played when the barricade is rebuilt
 * @param dropAll boolean Optional, defaults to false
 *
 * @returns nothing
 */
buildBarricade(targetname, partCount, health, deathFx, buildFx, dropAll) {}


/**
 * @brief Builds a weapon that can be picked up from an old RotU map using _zombiescript.gsc
 *
 *        Compatability method. Catches calls to _zombiescript::buildWeaponPickup()
 *        when the include is simply changed from _zombiescript.gsc to _umi.gsc.
 *
 *        New maps, or a complete porting job, should call
 *        _umi::buildWeaponPickupByTargetname(targetname, itemText, weapon, weaponType) directly.
 *
 * @param targetname string The name of the entities' targetname property
 * @param itemText string The English name of the weapon
 * @param weapon string The game name of the weapon, i.e. m14_mp
 * @param weaponType string The type of the weapon
 *
 * @returns nothing
 */
buildWeaponPickup(targetname, itemText, weapon, weaponType) {}


/**
 * @brief Allows a mapmaker override the ammoStockType
 *
 * @param onGiveWeapons integer [0|1] Sets ammo stock type
 *                                    0 sets level.ammoStockType to "weapon"
 *                                    1 sets level.ammoStockType to "upgrade"
 *
 * @returns nothing
 */
setWeaponHandling(onGiveWeapons) {}


/**
 * @brief Allows a mapmaker override the default primary and secondary player weapons
 *
 * @param primary string The default primary weapon
 * @param secondary string The default secondary weapon
 *
 * @returns nothing
 */
setSpawnWeapons(primary, secondary) {}


/** @deprecated
 * @brief Related to dropping supplies by parachute?
 *
 *        NOOP.  Must be from RotU 2.1 or earlier. The file _parachutes.gsc
 *        doesn't exist anywhere from 2.2.0 onwards.
 *
 *        Compatability method. Catches calls to _zombiescript::buildWeaponPickup()
 *        when the include is simply changed from _zombiescript.gsc to _umi.gsc.
 *
 * @param targetname string The entities to load as parachute drop points
 *
 * @returns nothing
 */
buildParachutePickup(targetname) {}


/**
 * @brief Allows a mapmaker to apply a post-processing visual filter
 *
 * @param vision string The name of the vision ao apply
 * @param transitiontime float How long to fade the transition in
 *
 * @returns nothing
 */
setWorldVision(vision, transitiontime) {}


/**
 * @brief Allows a mapmaker to override the server's game mode.
 *
 *        This method includes a 'wait' call, so you must precache & load
 *        all your assets prior to this call.
 *
 *        Note: Only modes "waves_special" and "waves_endless" are supported.
 *              "onslaught" & "scripted" are deprecated
 * @param mode string The level.gameMode value for this map
 *
 * @returns nothing
 */
setGameMode(mode) {}


/**
 * @brief Allows a mapmaker to override using TDM apwnpoints for the players
 *
 * @param targetname string The targetname of the map entities to use as player spawnpoints
 *
 * @returns nothing
 */
setPlayerSpawns(targetname) {}


/**
 * @brief Builds zombie spawn points for old ROZO maps
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @returns nothing
 */
addDefaultZombieSpawns() {}


/**
 * @brief Builds weapon shops and equipment shops using old ROZO calls
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @param weapons string Space-separated list of tradespawn array indices
 * @param shops string Space-separated list of tradespawn array indices
 *
 * e.g. @code placeShops("0 2 4 6", "1 3 5 7"); @endcode
 *
 * @returns nothing
 */
placeShops(weapons, shops) {}


/**
 * @brief Converts waypoints for old ROZO maps
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @returns nothing
 */
convertWaypoints() {}


/**
 * @brief NOOP. Old ROZO call.
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @param origin A tuple containing the map position to be the default target
 *
 * @returns nothing
 */
zombieDefaultTarget(origin) {}


/**
 * @brief NOOP. Old ROZO call.
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @returns nothing
 */
mapThink() {}


/**
 * @brief NOOP. Old ROZO call.
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @returns nothing
 */
setPlayerModels() {}


/**
 * @brief NOOP. Old ROZO call.
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @param structs n/a
 * @param additional n/a
 *
 * @returns nothing
 */
getFreeStruct(structs, additional) {}


/**
 * @brief NOOP. Old ROZO call.
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @param swap n/a
 *
 * @returns nothing
 */
addDefaultPlayerSpawns(swap) {}


/**
 * @brief NOOP. Old ROZO call.
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @param classname n/a
 * @param enabled n/a
  *
 * @returns nothing
 */
addPlayerSpawns(classname, enabled) {}

