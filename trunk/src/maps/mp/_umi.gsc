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
/** @file _umi.gsc The RotU implementation of the unified mapping interface as
 * specified in @code maps\mp\_unified_mapping_interface.gsc @endcode
 *
 * Attention Mappers: Include this file in your main map file--
 *                    not @code maps\mp\_unified_mapping_interface.gsc @endcode
 */

#include scripts\include\array;
#include scripts\include\data;
#include scripts\include\entities;
#include scripts\include\hud;
#include scripts\include\matrix;
#include scripts\include\utility;
#include scripts\include\strings;
#include scripts\include\realtime;

//
// Unified Mapping Interface (UMI) Public Functions
//
// Map makers can count on these functions being defined in every mod that uses
// the UMI.  However, any given function may not actually have a use in the mod,
// e.g. a call to buildParachutePickup() won't cause any compile or runtime errors
// when the map is run in RotU, but that call will have no effect as parachute drops
// aren't part of RotU.
//

// @todo Need to be able to add zombie spawnpoints manually
// maybe a method like: addZombieSpawnpointByOrigin(origin, targetname)
// that creates entity at origin w/targetname spawngroup[N], then calls
// buildZombieSpawnByTargetname()


/**
 * @brief Run RotU in a special non-game mode.
 *
 *        This lets us run other mini-apps useful for dev purposes, like screenshot mode,
 *        UMI Map Editor, or the Model Centroid Finder.
 *
 * @returns nothing
 */
doSpecialRunMode()
{
    log("trace", "msg|in _umi::modName()||");
    log("dev", "msg|in _umi::doSpecialRunMode()||");

    // maps\mp\_umiEditor::devDumpEntities();

    runMode = getdvar("run_mode"); // empty string if dvar not set
    if (runMode == "" && runMode == "game") {
        return;
    }

    // let runMode override eveything else
    if (runMode != "") {
        switch (runMode) {
            case "screenshotMode":
                log("dev", "msg|in screenshot mode||");
                return;
            case "testMysteryBox":
                log("dev", "msg|in test mystery box mode||");
                scripts\gamemodes\_mysterybox::testMysteryBox();
                return;
            case "centroidFinder":
                log("dev", "msg|in centroidFinder mode||");
                scripts\tools\modelCentroidFinder::init("weapon_desert_eagle_gold", "deserteaglegold_mp", "secondary");
                // scripts\tools\modelCentroidFinder::init("weapon_colt1911_silencer" , "colt45_silencer_mp", "secondary");
                // scripts\tools\modelCentroidFinder::init("weapon_mw2_f2000_wm", "m14_acog_mp", "primary");
                // scripts\tools\modelCentroidFinder::init("worldmodel_bo_minigun", "saw_acog_mp", "primary");
                return;
            case "umi":
                log("dev", "msg|in UMI mode||");
                devDrawAllPossibleSpawnpoints();
                maps\mp\_umiEditor::initMapEditor();
                return;
        }
    }

    // if runMode isn't set
    if ((getdvarInt("screenshot_mode") == 1) || (level.screenshotMode)) {
        // do nothing
        log("dev", "msg|in screenshot mode||");
        return;
    } else if (level.umiEnabled) {
        log("dev", "msg|in UMI mode||");
        devDrawAllPossibleSpawnpoints();
        maps\mp\_umiEditor::initMapEditor();
        return;
    }
}


/**
 * @brief Returns the lower-cased name of the mod that is trying to load the map
 *
 * @returns string The name of the mod, e.g. "rotu", "rozo", etc
 * @since RotU 2.2.1
 */
modName()                                           // quality:external_interface
{
    log("trace", "msg|in _umi::modName()||");

    if (isDefined(level.modName)) {return level.modName;}
    else {
        level.modName = "rotu";
        return level.modName;
    }
}

/**
 * @brief Returns the native type of the map being loaded
 *
 * @returns string The native type of the map, e.g. "rotu", "rozo", etc.
 * @since RotU 2.2.1
 */
nativeMapType()                                     // quality:external_interface
{
    log("trace", "msg|in _umi::nativeMapType()||");

    if (isDefined(level.nativeMapType)) {return level.nativeMapType;}
    else {return "";}
}

/**
 * @brief Sets the native type of the map being loaded
 *
 * @param nativeMapType string The native type of the map, e.g. "rotu", "rozo", etc.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
setNativeMapType(nativeMapType)                     // quality:external_interface
{
    log("trace", "msg|in _umi::setNativeMapType()||");

    level.nativeMapType = nativeMapType;
}

/**
 * @brief UMI Converts CSV waypoints to BTD waypoints, and prints them to the server log
 * It prints the BTD function, but will require the timecodes to be removed from the
 * front the the line, as well as any extraneous info printed to the log at the
 * same time by other functions.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
devDumpCsvWaypointsToBtd()                          // quality:external_interface
{
    log("trace", "msg|in _umi::devDumpCsvWaypointsToBtd()||");

    wp = [];
    wpCount = 0;

    fileName =  "waypoints/"+ tolower(getdvar("mapname")) + "_wp.csv";
    wpCount = int(TableLookup(fileName, 0, 0, 1));

    if ((!isDefined(wpCount)) || (wpCount == 0)) {
        log("server", "msg|No csv waypoints in fastfile, nothing to dump.||");
        return;
    }

    wpFilename = tolower(getdvar("mapname"))+"_waypoints.gsc";
    logPrint("// BTD-style load_waypoints() function for file " + wpFilename + " generated by RotU\n");
    logPrint("// based on waypoints compiled into the map's fast file.\n");
    logPrint("//\n");
    logPrint("// These waypoints can be edited and then used to override the waypoints in the fast file\n");
    logPrint("// using _umi::setPreferBtdWaypoints(true)\n");
    logPrint("// Alternatively, you may use these waypoints, and recompile the fast file without the waypoints.\n");
    logPrint("//\n");
    logPrint("// N.B. You will need to delete the timecodes at the beginning of these lines!\n");
    logPrint("//\n");

    logPrint("load_waypoints()\n");
    logPrint("{\n");
    logPrint("    level.waypoints = [];\n");
    logPrint("    \n");

    for (i=0; i<level.WpCount; i++) {
        wpIndex = i;
        csvIndex = i + 1;
        strOrigin = TableLookup(fileName, 0, csvIndex, 1);
        originTokens = strtok(strOrigin, " ");
        x = atof(originTokens[0]);
        y = atof(originTokens[1]);
        z = atof(originTokens[2]);

        logPrint("    level.waypoints["+wpIndex+"] = spawnstruct();\n");
        logPrint("    level.waypoints["+wpIndex+"].origin = ("+x+","+y+","+z+");\n");

        strLinked = TableLookup(fileName, 0, csvIndex, 2);
        linkedTokens = strtok(strLinked, " ");
        childCount = linkedTokens.size;
        logPrint("    level.waypoints["+wpIndex+"].childCount = "+childCount+";\n");

        for (j=0; j<childCount; j++) {
            logPrint("    level.waypoints["+wpIndex+"].children["+j+"] = "+linkedTokens[j]+";\n");
        }
    }

    logPrint("    \n");
    logPrint("    level.waypointCount = level.waypoints.size;\n");
    logPrint("}\n");
}

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
devDumpBtdWaypointsToCsv()                          // quality:external_interface
{
    log("trace", "msg|in _umi::devDumpBtdWaypointsToCsv()||");

    if ((!isDefined(level.waypoints)) || (level.waypoints.size == 0)) {
        log("server", "msg|No BTD waypoints in memory, nothing to dump.||");
        return;
    }

    fileName =  "waypoints/"+ tolower(getdvar("mapname")) + "_wp.csv";
    logPrint("// CSV-style waypoints generated by RotU from BTD-style waypoints.\n");
    logPrint("// Save these lines in a file named " + fileName + "\n");
    logPrint("//\n");
    logPrint("// These waypoints can then be compiled into the map's fast file.\n");
    logPrint("//\n");
    logPrint("// N.B. You will need to delete the timecodes at the beginning of these lines!\n");
    logPrint("//\n");

    logPrint("0,"+level.waypoints.size+",0\n");
    for (i=0; i<level.waypoints.size; i++) {
        csvIndex = i+1;
        x = level.waypoints[i].origin[0];
        y = level.waypoints[i].origin[1];
        z = level.waypoints[i].origin[2];
        linkedWaypoints = level.waypoints[i].children[0];
        for (j=1; j<level.waypoints[i].childCount; j++) {
            linkedWaypoints = linkedWaypoints + " " + level.waypoints[i].children[j];
        }
        logPrint(csvIndex+","+x+" "+y+" "+z+","+linkedWaypoints+"\n");
    }
}

/**
 * @brief UMI draws all possible spawnpoints on the map
 * This is useful when placing tradespawns to ensure you don't block a spawning player
 * @threaded
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
devDrawAllPossibleSpawnpoints()
{
    log("trace", "msg|in _umi::devDrawAllPossibleSpawnpoints()||");

    // mark RotU-style spawngroups by targetname
    for (i=0; i<20; i++) {
        targetname = "spawngroup" + i;
        ents = getentarray(targetname, "targetname");
        for (j=0; j<ents.size; j++) {
            maps\mp\_umiEditor::devDrawLaser("red", ents[j].origin, (0,0,1));
        }
    }
    // mark RotU-style spawngroups by classname
    for (i=0; i<20; i++) {
        classname = "spawngroup" + i;
        ents = getentarray(classname, "classname");
        for (j=0; j<ents.size; j++) {
            maps\mp\_umiEditor::devDrawLaser("red", ents[j].origin, (0,0,1));
        }
    }
    // mark the Cod4 stock spawnpoints
    codSpawnpointClasses[0] = "mp_tdm_spawn";
    codSpawnpointClasses[1] = "mp_tdm_spawn_allies_start";
    codSpawnpointClasses[2] = "mp_tdm_spawn_axis_start";
    codSpawnpointClasses[3] = "mp_dm_spawn";
    codSpawnpointClasses[4] = "mp_global_intermission";
    codSpawnpointClasses[5] = "mp_sab_spawn_axis_start";
    codSpawnpointClasses[6] = "mp_sab_spawn_axis";
    codSpawnpointClasses[7] = "mp_sab_spawn_allies_start";
    codSpawnpointClasses[8] = "mp_sab_spawn_allies";
    codSpawnpointClasses[9] = "mp_sd_spawn_attacker";
    codSpawnpointClasses[10] = "mp_sd_spawn_defender";
    codSpawnpointClasses[11] = "mp_dom_spawn_axis_start";
    codSpawnpointClasses[12] = "mp_dom_spawn_allies_start";
    codSpawnpointClasses[13] = "mp_dom_spawn";
    codSpawnpointClasses[14] = "mp_ctf_spawn_allies";
    codSpawnpointClasses[15] = "mp_ctf_spawn_allies_start";
    codSpawnpointClasses[16] = "mp_ctf_spawn_axis_start";
    codSpawnpointClasses[17] = "mp_ctf_spawn_axis";

    /// @todo don't draw multiple lasers at almost the same spot
    for (i=0; i<codSpawnpointClasses.size; i++) {
        ents = getentarray(codSpawnpointClasses[i], "classname");
        for (j=0; j<ents.size; j++) {
            maps\mp\_umiEditor::devDrawLaser("green", ents[j].origin, (0,0,1));
        }
    }
}

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
deleteUnusedSpawnpoints(deleteSab, deleteSd, deleteDom, deleteCtf)  // quality:external_interface
{
    log("trace", "msg|in _umi::deleteUnusedSpawnpoints()||");

    classes = [];

    // RotU uses tdm spawns, so they are never 'unused'
    if (deleteSab) {
        classes[classes.size] = "mp_sab_spawn_axis_start";
        classes[classes.size] = "mp_sab_spawn_allies_start";
        classes[classes.size] = "mp_sab_spawn_axis";
        classes[classes.size] = "mp_sab_spawn_allies";
    }
    if (deleteSd) {
        classes[classes.size] = "mp_sd_spawn_attacker";
        classes[classes.size] = "mp_sd_spawn_defender";
    }
    if (deleteDom) {
        classes[classes.size] = "mp_dom_spawn_axis_start";
        classes[classes.size] = "mp_dom_spawn_allies_start";
        classes[classes.size] = "mp_dom_spawn";
    }
    if (deleteCtf) {
        classes[classes.size] = "mp_ctf_spawn_allies";
        classes[classes.size] = "mp_ctf_spawn_allies_start";
        classes[classes.size] = "mp_ctf_spawn_axis_start";
        classes[classes.size] = "mp_ctf_spawn_axis";
    }

    for (i=0; i<classes.size; i++) {
        ents = getentarray(classes[i], "classname");
        for (j=0; j<ents.size; j++) {
            ents[j] delete();
        }
    }
}


/**
 * @brief UMI deletes from memory unused capture the flag entities from maps
 *
 * On some maps, deleting unused spawnpoints and other entities can triple or
 * quadruple the speed of the getEntArray() and related functions.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteCtfEntities()                                 // quality:external_interface
{
    log("trace", "msg|in _umi::deleteCtfEntities()||");

    origins = [];
    index = 0;

    ctfEntities[0] = "ctf_flag_allies";
    ctfEntities[1] = "ctf_flag_axis";
    for (i=0; i<ctfEntities.size; i++) {
        ents = getentarray(ctfEntities[i], "targetname");
        for (j=0; j<ents.size; j++) {
            origins[index] = ents[j].origin;
            index++;
        }
    }
    for (i=0; i<origins.size; i++) {
        deleteNearbyEntities(origins[i], 20, 25);
    }
}


/**
 * @brief UMI deletes built-in turrets from maps
 *
 * @returns nothing
 * @since RotU 2.2.2
 */
deleteTurrets()                                     // quality:external_interface
{
    log("trace", "msg|in _umi::deleteTurrets()||");

    ents = getentarray("misc_turret", "classname");
    for (i=0; i<ents.size; i++) {
        ents[i] delete();
    }
}


/**
 * @brief UMI deletes from memory unused headquarters entities from maps
 *
 * On some maps, deleting unused spawnpoints and other entities can triple or
 * quadruple the speed of the getEntArray() and related functions.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteHqEntities()                                  // quality:external_interface
{
    log("trace", "msg|in _umi::deleteHqEntities()||");

    origins = [];
    index = 0;

    hqEntities[0] = "hq_hardpoint";
    for (i=0; i<hqEntities.size; i++) {
        ents = getentarray(hqEntities[i], "targetname");
        for (j=0; j<ents.size; j++) {
            origins[index] = ents[j].origin;
            index++;
        }
    }
    for (i=0; i<origins.size; i++) {
        deleteNearbyEntities(origins[i], 25, 35);
    }
}


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
disambiguateBarrelsByTargetname(targetname)         // quality:external_interface
{
    log("trace", "msg|in _umi::disambiguateBarrelsByTargetname()||");

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ents[i] setmodel("com_barrel_blue_rust");
    }
}


/**
 * @brief UMI deletes from memory unused sabotage entities from maps
 *
 * On some maps, deleting unused spawnpoints and other entities can triple or
 * quadruple the speed of the getEntArray() and related functions.
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteSabotageEntities()                            // quality:external_interface
{
    log("trace", "msg|in _umi::deleteSabotageEntities()||");

    origins = [];
    index = 0;

    sabotageEntities[0] = "sab_bomb_axis";
    sabotageEntities[1] = "sab_bomb_allies";
    sabotageEntities[2] = "bombzone";
    sabotageEntities[3] = "sab_bomb";
    sabotageEntities[4] = "sd_bomb";
    for (i=0; i<sabotageEntities.size; i++) {
        ents = getentarray(sabotageEntities[i], "targetname");
        for (j=0; j<ents.size; j++) {
            origins[index] = ents[j].origin;
            index++;
        }
    }
    for (i=0; i<origins.size; i++) {
        deleteNearbyEntities(origins[i], 5, 30);
    }
}


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
loadCentralTrap(trigger, bat, base, activator, price)   // quality:external_interface
{
    log("trace", "msg|in _umi::loadCentralTrap()||");

    if (!isDefined(level.mapTraps)) {level.mapTraps = [];}
    if (!isDefined(price)) {price = 5000;} // default if not spec'd and not overriden in game.cfg

    text = "";
    cost = 0;

    text = "Central";
    configCost = getDvarInt("trap_central_costs");
    if (!isDefined(configCost)) {cost = price;}
    else {cost = configCost;}
    if (cost <= 0) {cost = 100;} // hard-coded minimum cost

    ents = getEntArray(trigger, "targetname");
    for (i=0; i<ents.size; i++) {
        trap = spawnStruct();
        trap.trigger = ents[i];
        trap.cost = cost;
        trap.type = "central";
        trap.text = text;
        trap.isBeingUsed = false;
        trap.activator = getEnt(activator, "targetname");
        trap.bat = getEnt(bat, "targetname");
        trap.base = getEnt(base, "targetname");
        level.mapTraps[level.mapTraps.size] = trap;
    }
}


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
loadRotatingTrap(trigger, death, activator, price)  // quality:external_interface
{
    log("trace", "msg|in _umi::loadRotatingTrap()||");

    if (!isDefined(level.mapTraps)) {level.mapTraps = [];}
    if (!isDefined(price)) {price = 5000;} // default if not spec'd and not overriden in game.cfg

    text = "";
    cost = 0;

    text = "Rotating";
    configCost = getDvarInt("trap_rotating_costs");
    if (!isDefined(configCost)) {cost = price;}
    else {cost = configCost;}
    if (cost <= 0) {cost = 100;} // hard-coded minimum cost

    ents = getEntArray(trigger, "targetname");
    for (i=0; i<ents.size; i++) {
        trap = spawnStruct();
        trap.trigger = ents[i];
        trap.cost = cost;
        trap.type = "rotating";
        trap.text = text;
        trap.isBeingUsed = false;
        trap.activator = getEnt(activator, "targetname");
        trap.death = getEnt(death, "targetname");
        level.mapTraps[level.mapTraps.size] = trap;
    }
}


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
loadSpikeTrap(trigger, death, activator, price)     // quality:external_interface
{
    log("trace", "msg|in _umi::loadSpikeTrap()||");

    if (!isDefined(level.mapTraps)) {level.mapTraps = [];}
    if (!isDefined(price)) {price = 5000;} // default if not spec'd and not overriden in game.cfg

    text = "";
    cost = 0;

    text = "Spike";
    configCost = getDvarInt("trap_spike_costs");
    if (!isDefined(configCost)) {cost = price;}
    else {cost = configCost;}
    if (cost <= 0) {cost = 100;} // hard-coded minimum cost

    ents = getEntArray(trigger, "targetname");
    for (i=0; i<ents.size; i++) {
        trap = spawnStruct();
        trap.trigger = ents[i];
        trap.cost = cost;
        trap.type = "spike";
        trap.text = text;
        trap.isBeingUsed = false;
        trap.activator = getEnt(activator, "targetname");
        trap.death = getEnt(death, "targetname");
        level.mapTraps[level.mapTraps.size] = trap;
    }
}


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
loadFireTrap(trigger, fire1, fire2, fire3, fire4, death, activator, price)  // quality:external_interface
{
    log("trace", "msg|in _umi::loadFireTrap()||");

    if (!isDefined(level.mapTraps)) {level.mapTraps = [];}
    if (!isDefined(price)) {price = 5000;} // default if not spec'd and not overriden in game.cfg

    text = "";
    cost = 0;

    text = "Fire";
    configCost = getDvarInt("trap_fire_costs");
    if (!isDefined(configCost)) {cost = price;}
    else {cost = configCost;}
    if (cost <= 0) {cost = 100;} // hard-coded minimum cost

    ents = getEntArray(trigger, "targetname");
    for (i=0; i<ents.size; i++) {
        trap = spawnStruct();
        trap.trigger = ents[i];
        trap.cost = cost;
        trap.type = "fire";
        trap.text = text;
        trap.isBeingUsed = false;
        trap.activator = getEnt(activator, "targetname");
        trap.death = getEnt(death, "targetname");
        trap.fire1 = getEnt(fire1, "targetname");
        trap.fire2 = getEnt(fire2, "targetname");
        trap.fire3 = getEnt(fire3, "targetname");
        trap.fire4 = getEnt(fire4, "targetname");
        level.mapTraps[level.mapTraps.size] = trap;
    }
}


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
loadElectricTrap(trigger, elec1, elec2, elec3, elec4, elec5, elec6, death, activator, price)    // quality:external_interface
{
    log("trace", "msg|in _umi::loadElectricTrap()||");

    if (!isDefined(level.mapTraps)) {level.mapTraps = [];}
    if (!isDefined(price)) {price = 5000;} // default if not spec'd and not overriden in game.cfg

    text = "";
    cost = 0;

    text = "Electric";
    configCost = getDvarInt("trap_electric_costs");
    if (!isDefined(configCost)) {cost = price;}
    else {cost = configCost;}
    if (cost <= 0) {cost = 100;} // hard-coded minimum cost

    ents = getEntArray(trigger, "targetname");
    for (i=0; i<ents.size; i++) {
        trap = spawnStruct();
        trap.trigger = ents[i];
        trap.cost = cost;
        trap.type = "electric";
        trap.text = text;
        trap.isBeingUsed = false;
        trap.activator = getEnt(activator, "targetname");
        trap.death = getEnt(death, "targetname");
        trap.elec1 = getEnt(elec1, "targetname");
        trap.elec2 = getEnt(elec2, "targetname");
        trap.elec3 = getEnt(elec3, "targetname");
        trap.elec4 = getEnt(elec4, "targetname");
        trap.elec5 = getEnt(elec5, "targetname");
        trap.elec6 = getEnt(elec6, "targetname");
        level.mapTraps[level.mapTraps.size] = trap;
    }
}


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
loadGlidePad(trigger, origin1, origin2, origin3, origin4, origin5, origin6, velocity)   // quality:external_interface
{
    log("trace", "msg|in _umi::loadGlidePad()||");

    if (!isDefined(level.glidePads)) {level.glidePads = [];}

    if (!isDefined(velocity)) {
        velocity = 300; // units/s
    }
    if (velocity == 0) {velocity = 0.001;} // divide by zero guard

    pad = spawnStruct();
    ents = getEntArray(trigger, "targetname");
    pad.trigger = ents[0];

    // grab the points
    if (isDefined(origin1)) {
        ents = getEntArray(origin1, "targetname");
        pad.origin1 = ents[0].origin;
    }
    if (isDefined(origin2)) {
        ents = getEntArray(origin2, "targetname");
        pad.origin2 = ents[0].origin;
    }
    if (isDefined(origin3)) {
        ents = getEntArray(origin3, "targetname");
        pad.origin3 = ents[0].origin;
    }
    if (isDefined(origin4)) {
        ents = getEntArray(origin4, "targetname");
        pad.origin4 = ents[0].origin;
    }
    if (isDefined(origin5)) {
        ents = getEntArray(origin5, "targetname");
        pad.origin5 = ents[0].origin;
    }
    if (isDefined(origin6)) {
        ents = getEntArray(origin6, "targetname");
        pad.origin6 = ents[0].origin;
    }

    if ((isDefined(pad.origin1)) && (isDefined(pad.origin2))){
        dist = distance(pad.origin1, pad.origin2);
        pad.time12 = dist / velocity;
    }
    if ((isDefined(pad.origin2)) && (isDefined(pad.origin3))){
        dist = distance(pad.origin2, pad.origin3);
        pad.time23 = dist / velocity;
    }
    if ((isDefined(pad.origin3)) && (isDefined(pad.origin4))){
        dist = distance(pad.origin3, pad.origin4);
        pad.time34 = dist / velocity;
    }
    if ((isDefined(pad.origin4)) && (isDefined(pad.origin5))){
        dist = distance(pad.origin4, pad.origin5);
        pad.time45 = dist / velocity;
    }
    if ((isDefined(pad.origin5)) && (isDefined(pad.origin6))){
        dist = distance(pad.origin5, pad.origin6);
        pad.time56 = dist / velocity;
    }

    level.glidePads[level.glidePads.size] = pad;
}


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
loadCyclicalAnimation(model, type, steps, reversible, delay)    // quality:external_interface
{
    log("trace", "msg|in _umi::loadCyclicalAnimation()||");

    if (!isDefined(level.mapAnimations)) {level.mapAnimations = [];}

    if (!isDefined(delay)) {
        delay = 0; // s
    }
    if (!isDefined(reversible)) {
        reversible = false; // s
    }

    for (i=0; i<steps.size; i++) {
        if (steps[i].velocity == 0) {steps[i].velocity = 0.01;}
        if (type == "linear") {
            steps[i].time = distance(steps[i].origin, steps[i].destination) / steps[i].velocity;
        } else if (type == "rotate") {
            theta = scripts\players\_turrets::angleBetweenTwoVectors(steps[i].toAngles, steps[i].fromAngles);
            steps[i].time = theta / steps[i].velocity;
        }
    }

    animation = spawnStruct();
    ents = getEntArray(model, "targetname");
    animation.model = ents[0];
    animation.reversible = reversible;
    animation.delay = delay;
    animation.type = type;
    animation.steps = steps;

    level.mapAnimations[level.mapAnimations.size] = animation;
}


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
loadElevator(model, trigger, positionA, positionB, velocity)    // quality:external_interface
{
    log("trace", "msg|in _umi::loadElevator()||");

    if (!isDefined(level.elevators)) {level.elevators = [];}

    if (!isDefined(velocity)) {
        velocity = 350; // units/s
    }
    if (velocity == 0) {velocity = 0.001;} // divide by zero guard

    elevator = spawnStruct();

    ents = getEntArray(model, "targetname");
    elevator.model = ents[0];
    ents = getEntArray(trigger, "targetname");
    elevator.triggers = ents;
    elevator.positionA = positionA;
    elevator.positionB = positionB;
    dist = distance(elevator.positionB, elevator.positionA);
    elevator.time = dist / velocity;

    level.elevators[level.elevators.size] = elevator;
}


/**
 * @brief Loads a teleporter specified in a map
 *
 * @param trigger string The targetname of the entity with a classname of 'trigger_multiple'
 * @param destination string The targetname of the entity with a classname of 'script_origin'
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadMapTeleporter(trigger, destination)             // quality:external_interface
{
    log("trace", "msg|in _umi::loadMapTeleporter()||");

    if (!isDefined(level.mapTeleporters)) {level.mapTeleporters = [];}

    mapTeleporter = spawnStruct();
    ents = getEntArray(trigger, "targetname");
    mapTeleporter.trigger = ents[0];
    ents = getEntArray(destination, "targetname");
    mapTeleporter.destination = ents[0].origin;

    level.mapTeleporters[level.mapTeleporters.size] = mapTeleporter;
}


/**
 * @brief Loads a hurt trigger specified in a map
 *
 * @param trigger string The classname of the entities with a classname of 'trigger_hurt'
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
loadHurtTriggers(trigger)                           // quality:external_interface
{
    log("trace", "msg|in _umi::loadHurtTriggers()||");

    if (!isDefined(level.mapHurtTriggers)) {level.mapHurtTriggers = [];}

    ents = getEntArray("trigger_hurt", "classname");
    for (i=0; i<ents.size; i++) {
        hurtTrigger = spawnStruct();
        hurtTrigger.trigger = ents[i];
        hurtTrigger.origin = ents[i].origin;
        level.mapHurtTriggers[level.mapHurtTriggers.size] = hurtTrigger;
    }
}


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
buildShopsByTradespawns(equipmentShops, havePrefabModels)   // quality:external_interface
{
    log("trace", "msg|in _umi::buildShopsByTradespawns()||");

    if (!isDefined(havePrefabModels)) {havePrefabModels = false;}

    log("server", "msg|Map: RotU prefers _umi::buildShopsByTargetname(targetname).||");
    log("server", "msg|Map: You may call _umi::modName() to determine which mod is trying to load the map.||");

    shops = strTok(equipmentShops, " ");
    if (level.autoMapTesting) {
        fmt = "msg|Tested equipment shop presence.||equipmentShopCount|$1:n||";
        log("automaptest", sprintfLog(fmt, shops.size));
    }
    if (!isDefined(level.tradespawns[int(shops[0])])) {
        log("error", "msg|Map: No equipment shop tradespawns defined, or tradespawns haven't been loaded().||");
        return;
    }

    for (i=0; i<shops.size; i++) {
        tradespawn = level.tradespawns[int(shops[i])];
        shop = spawn("script_model", tradespawn.origin);
        if (isDefined(shop)) {
            shop.angles = tradespawn.angles;
            shop setModel("ad_sodamachine");
        }

        // a column vector for the xmodel's centroid
        centroid = zeros(2,1);
        // 20.2 is approx. x-coord of 2-D centroid of xmodel, i.e. x bar
        setValue(centroid,1,1,20.2);
        // 15.8 is approx. y-coord of 2-D centroid of xmodel, i.e. y bar.  Negative
        // sign is needed due to location of origin in the xmodel
        setValue(centroid,2,1,-15.8);
        // phi is the angle the xmodel is rotated through
        phi = tradespawn.angles[1];
        // create standard rotation matrix
        A = eye(2);
        setValue(A,1,1,cos(phi));
        setValue(A,1,2,-1*sin(phi));
        setValue(A,2,1,sin(phi));
        setValue(A,2,2,cos(phi));
        // apply the rotation matrix
        R = matrixMultiply(A, centroid);
        // now (x,y) hold the proper rotated position offset relative to tradespawn.origin
        x = value(R,1,1);
        y = value(R,2,1);
        level scripts\players\_usables::addUsable(shop, "extras", "Press [USE] to buy upgrades!", 96);
        center = tradespawn.origin + (x, y, 0);
        createTeamObjpoint(getObjHudPosition(tradespawn, center), "hud_ammo", 1);

        // spawn a solid trigger_radius to simulate xmodel actually being solid
        level.solid = spawn("trigger_radius", (0, 0, 0), 0, 22, 122 );
        level.solid.origin = tradespawn.origin + (x,y,0);
        level.solid.angles = tradespawn.angles;
        level.solid setContents(1);
    }
}


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
buildShopsByTargetname(targetname)                  // quality:external_interface
{
    log("trace", "msg|in _umi::buildShopsByTargetname()||");

    ents = getentarray(targetname, "targetname");
    if (level.autoMapTesting) {
        fmt = "msg|Tested equipment shop presence.||equipmentShopCount|$1:n||";
        log("automaptest", sprintfLog(fmt, ents.size));
    }
    if (ents.size == 0) {
        log("error", "msg|Map: No equipment shops (entities matching targetname: " + targetname + ") found.||");
        return;
    }

    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        level scripts\players\_usables::addUsable(ent, "extras", "Press [USE] to buy upgrades!", 96);
        createTeamObjpoint(getObjHudPosition(ent), "hud_ammo", 1);
    }
}


/**
 * @brief Calculates the hieght above a shop for the team objective HUD
 *
 * @param ent entity entity serving as the shop
 * @param centroid vector The x-y center of the model used for a shop. Optional.
 *                        Needed when the model origin isn't in the central axis of the model
 *
 * @returns vector The position to place the team objective HUD element at
 * @since RotU 2.2.3
 */
getObjHudPosition(ent, centroid)
{
    log("trace", "msg|in _umi::getObjHudPosition()||");

    if (isDefined(centroid)) {
        trace = bulletTrace(centroid + (0, 0, 85), centroid + (0, 0, -100), false, ent);
        topPos = trace["position"];
        newPos = topPos + (0, 0, 30);
        // oldPos = centroid + (0, 0, 85);
    } else {
        trace = bulletTrace(ent.origin + (0, 0, 72), ent.origin + (0, 0, -100), false, ent);
        topPos = trace["position"];
        newPos = topPos + (0, 0, 30);
        // oldPos = ent.origin + (0, 0, 72);
    }
    // log("debug", sprintfLog("msg|Objective HUD position data||oldPos|$1||newPos|$2", oldPos, newPos));
    return newPos;
}


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
buildWeaponShopsByTargetname(targetname, loadTime)  // quality:external_interface
{
    log("trace", "msg|in _umi::buildWeaponShopsByTargetname()||");

    ents = getentarray(targetname, "targetname");
    if (level.autoMapTesting) {
        fmt = "msg|Tested weapon shop presence.||weaponShopCount|$1:n||";
        log("automaptest", sprintfLog(fmt, ents.size));
    }
    if (ents.size == 0) {
        log("error", "msg|Map: No weapon shops (entities matching targetname: " + targetname + ") found.||");
        return;
    }

    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        ent.loadtime = loadTime;
        // log("warn", "msg|building weapon shop. level.ammoStockType: " + level.ammoStockType + "||");
        if (level.ammoStockType == "weapon") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Press [USE] for a weapon! (^1"+level.dvar["surv_waw_costs"]+"^7)", 96);
            createTeamObjpoint(getObjHudPosition(ent), "hud_weapons", 1);
        } else if (level.ammoStockType == "upgrade") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Press [USE] to upgrade your weapon!", 96);
            createTeamObjpoint(getObjHudPosition(ent), "hud_weapons", 1);
        } else if (level.ammoStockType == "ammo") {
            level scripts\players\_usables::addUsable(ent, "ammobox", "Hold [USE] to restock ammo", 96);
        } else {
            log("error", "msg|level.ammoStockType isn't a valid ammoStockType.||");
        }
    }
}


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
buildWeaponShopsByTradespawns(weaponShops, havePrefabModels)    // quality:external_interface
{
    log("trace", "msg|in _umi::buildWeaponShopsByTradespawns()||");

    if (!isDefined(havePrefabModels)) {havePrefabModels = false;}

    log("server", "msg|Map: RotU prefers _umi::buildWeaponShopsByTargetname(targetname).||");
    log("server", "msg|Map: You may call _umi::modName() to determine which mod is trying to load the map.||");

    weapons = strTok(weaponShops, " ");
    if (level.autoMapTesting) {
        fmt = "msg|Tested weapon shop presence.||weaponShopCount|$1:n||";
        log("automaptest", sprintfLog(fmt, weapons.size));
    }

    if (!isDefined(level.tradespawns[int(weapons[0])])) {
        log("error", "msg|Map: No weapon shop tradespawns defined, or tradespawns haven't been loaded().||");
        return;
    }

    for (i=0; i<weapons.size; i++) {
        tradespawn = level.tradespawns[int(weapons[i])];
        weaponupgrade = spawn("script_model", tradespawn.origin);
        if (isDefined(weaponupgrade)) {
            weaponupgrade.angles = tradespawn.angles;
            weaponupgrade setModel("com_plasticcase_green_big");

            // spawn a solid trigger_radius to simulate xmodel actually being solid
            level.solid = spawn("trigger_radius", (0, 0, 0), 0, 21, 27 );
            level.solid.origin = tradespawn.origin;
            level.solid.angles = tradespawn.angles;
            level.solid setContents(1);

            level scripts\players\_usables::addUsable(weaponupgrade, "ammobox", "Press [USE] to upgrade your weapon!", 96);
            createTeamObjpoint(getObjHudPosition(tradespawn), "hud_weapons", 1);
        }
    }
}


/**
 * @brief UMI converts BTD/ROZO waypoints into RotU waypoints
 *
 * @pre waypoints loaded into memory in level.waypoints
 * @returns nothing
 * @since RotU 2.2.1
 */
convertToNativeWaypoints()                       // quality:external_interface
{
    log("trace", "msg|in _umi::convertToNativeWaypoints()||");

    loadWaypoints();
}


/**
 * @brief Preferentially loads external waypoints, falls-back to internal waypoints
 *
 * @pre waypoints loaded into memory in level.waypoints
 * @returns nothing
 * @since RotU 2.2.1
 */
loadWaypoints()                                     // quality:external_interface
{
    log("trace", "msg|in _umi::loadWaypoints()||");
    log("dev", "msg|in _umi::loadWaypoints()||");

    waypointsLoaded = false;
    waypointType = "None";

    if (isDefined(level.waypoints)) {
        // load external waypoints
        waypointsLoaded = loadExternalWaypoints();
    }
    if (waypointsLoaded) {
        waypointType = "external";
        log("server", "msg|External waypoints loaded: true||");
    } else {
        log("server", "msg|No external waypoints found, attempting to load internal waypoints.||");
    }
    if (!waypointsLoaded) {
        // load internal waypoints
        waypointsLoaded = loadInternalWaypoints();
        if (waypointsLoaded) {
            log("server", "msg|Internal waypoints loaded: true||");
            waypointType = "internal";
        } else {
            log("warn", "msg|No internal waypoints found.||");
        }
    }

    if (level.autoMapTesting) {
        fmt = "msg|Waypoints loaded.||waypointType|$1||";
        log("automaptest", sprintfLog(fmt, waypointType));
    }    

    if (waypointsLoaded) {
        // load distances, validate, kd-tree
        loadWaypointLinkDistances();
        level.waypointsInvalid = false;
        validateWaypoints();
    } else {
        level.waypointsInvalid = true;
    }
}


/**
 * @brief Loads internal waypoints
 *
 * @pre waypoints loaded into memory in level.waypoints
 * @returns nothing
 * @since RotU 2.2.1
 */
loadInternalWaypoints()
{
    log("trace", "msg|in _umi::loadInternalWaypoints()||");

    level.Wp = [];
    level.WpCount = 0;

    fileName =  "waypoints/"+ tolower(getdvar("mapname")) + "_wp.csv";
    testCount = int(TableLookup(fileName, 0, 0, 1));
    if ((isDefined(testCount)) && (testCount > 0)) {
        level.WpCount = testCount;
        for (i=0; i<level.WpCount; i++) {
            waypoint = spawnstruct();
            level.Wp[i] = waypoint;
            strOrigin = TableLookup(fileName, 0, i+1, 1);
            tokens = strtok(strOrigin, " ");

            waypoint.origin = (atof(tokens[0]), atof(tokens[1]), atof(tokens[2]));
            waypoint.isLinking = false;
            waypoint.ID = i;
            waypoint.type = "stand";
        }
        for (i=0; i<level.WpCount; i++) {
            waypoint = level.Wp[i];
            strLnk = TableLookup(fileName, 0, i+1, 2);
            tokens = strtok(strLnk, " ");
            waypoint.linkedCount = tokens.size;
            for (j=0; j<tokens.size; j++) {
                waypoint.linked[j] = level.Wp[atoi(tokens[j])];
            }
        }
        return true;
    } else {
        log("error", "msg|Map: No internal waypoints found!||");
        return false;
    }
}


/**
 * @brief Loads external waypoints
 *
 * @pre waypoints loaded into memory in level.waypoints
 * @returns nothing
 * @since RotU 2.2.1
 */
loadExternalWaypoints()
{
    log("trace", "msg|in _umi::loadExternalWaypoints()||");

    if (level.waypoints.size == 0) {
        log("error", "msg|Map: No external waypoints found!||");
        return false;
    }

    level.Wp = [];
    level.WpCount = 0;

    level.WpCount = level.waypoints.size;
    // Add in all of the waypoints
    for (i=0; i<level.WpCount; i++) {
        waypoint = spawnstruct();
        level.Wp[i] = waypoint;

        waypoint.origin = level.waypoints[i].origin;
        waypoint.isLinking = false;
        waypoint.ID = i;

        if (isDefined(level.waypoints[i].type)) { // stand, jump, mantle, climb/clamp
            waypoint.type = level.waypoints[i].type;
        } else if (isDefined(level.waypoints[i].clamp) && (level.waypoints[i].clamp)) {
            waypoint.type = "clamped";
        } else {
            waypoint.type = "stand";
        }
        // RotU doesn't use .angles, but read it in so we can preserve the info
        // for _umiEditor::devSaveWaypoints
        if (isDefined(level.waypoints[i].angles)) {
            waypoint.angles = level.waypoints[i].angles;
        }

        // used for bot angles while climbing up/down ladders
        if (isDefined(level.waypoints[i].upAngles)) {
            waypoint.upAngles = level.waypoints[i].upAngles;
        }
        if (isDefined(level.waypoints[i].downAngles)) {
            waypoint.downAngles = level.waypoints[i].downAngles;
        }

        // RotU doesn't use .use, but read it in so we can preserve the info
        // for _umiEditor::devSaveWaypoints
        if (isDefined(level.waypoints[i].use)) {
            waypoint.use = level.waypoints[i].use;
        }
    }
    // Now link the waypoints
    for (i=0; i<level.WpCount; i++) {
        waypoint = level.Wp[i];
        waypoint.linkedCount = level.waypoints[i].childCount;
        for (j=0; j<waypoint.linkedCount; j++) {
            waypoint.linked[j] = level.Wp[level.waypoints[i].children[j]];
        }
    }

    // Now that the external waypoints are in memory in RotU format, we can free the
    // memory used by the intial loading of the waypoints
    level.waypoints = [];
    return true;
}


/**
 * @brief Pre-compute and save distances between linked waypoints to optimize A*
 * We compute and store each distance twice to minimize the work A* has to do to
 * find the distance
 *
 * @returns nothing
 */
loadWaypointLinkDistances()
{
    log("trace", "msg|in _umi::loadWaypointLinkDistances()||");

    for (i=0; i<level.Wp.size; i++) {
        if (!isDefined(level.Wp[i].linked)) {
            continue;
        }
        for (j=0; j<level.Wp[i].linked.size; j++) {
            level.Wp[i].distance[j] = distance(level.Wp[i].origin, level.Wp[level.Wp[i].linked[j].ID].origin);
        }
    }
}


/**
 * @brief Validates the waypoints for this map
 *
 * This function will find unlinked waypoints, as well as waypoints that are linked,
 * but are part of a section that isn't linked to another section of linked waypoints.
 *
 * If it finds any errors, RotU will ignore all the waypoints in the map.
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
validateWaypoints()
{
    log("trace", "msg|in _umi::validateWaypoints()||");

    if (!isDefined(level.astarCalls)) {level.astarCalls = 0;}
    if (!isDefined(level.astarDistanceCalls)) {level.astarDistanceCalls = 0;}
    if (!isDefined(level.savedAStarCalls)) {level.savedAStarCalls = 0;}

    visited = [];
    unvisited = [];
    wps = [];
    invalidWaypoints = [];
    count = 0;
    fromWp = undefined;
    fixedWaypoints = false;
    validStr = "";

    // handle unlinked waypoints first
    for (i=0; i<level.Wp.size; i++) {
        if (!isDefined(level.Wp[i].linked)) {
            log("error", sprintfLog("msg|Unlinked Waypoint: $1 at: $2||", i, level.Wp[i].origin));
            deleteUnlinkedWaypoint(i);
            fixedWaypoints = true;
        }
    }

    for (i=0; i<level.Wp.size; i++) {
        wps[i] = 0; // boolean
    }

    // only use wp with children as a fromWp
    for (i=0; i<level.Wp.size; i++) {
        if (isDefined(level.Wp[i].linked)) {
            fromWp = i;
            break;
        }
    }
    if (!isDefined(fromWp)) {
        level.waypointsInvalid = true;
        log("error", sprintfLog("msg|Map $1 has no valid waypoints!||", getdvar("mapname")));
        return;
    }

    toWp = level.Wp.size - 1;
    while ((visited.size < wps.size) && (count < 150)) {
        count++;
        // closed = scripts\include\waypoints::AStarNew(fromWp, toWp, true);
        closed = scripts\include\waypoints::biDirectionalAStar(fromWp, toWp, true);
        if (!isDefined(closed)) {
            // didn't find a path
            invalidWaypoints[invalidWaypoints.size] = toWp;
            wps[toWp] = 1;
        } else {
            // update the waypoints we've processed
            for (i=0; i<closed.size; i++) {
                wps[closed[i].wpIdx] = 1;
            }
            wps[toWp] = 1;
        }

        // update the visited and unvisited arrays
        visited = [];
        unvisited = [];
        for (i=0; i<wps.size; i++) {
            if (wps[i] == 1) {visited[visited.size] = i;}
            else {unvisited[unvisited.size] = i;}
        }

        if (unvisited.size == 0) {break;}
        fromWp = visited[randomInt(visited.size)];
        toWp = unvisited[randomInt(unvisited.size)];
    }

    if (count == 150) {
        log("warn", "msg|Waypoint validation was stopped for performance reasons before it finished.||");
        log("warn", "msg|There may be invalid waypoints that aren't noted.||");
    }

    if (invalidWaypoints.size > 0) {
        log("error", sprintfLog("msg|Map $1 has invalid waypoints!||", getdvar("mapname")));
        for (i=0; i<invalidWaypoints.size; i++) {
            log("error", sprintfLog("msg|Waypoint: $1 at: $2 is part of a linked section not linked to the other section.||", invalidWaypoints[i], level.Wp[invalidWaypoints[i]].origin));
            level.waypointsInvalid = true;
        }
    }

    if (level.waypointsInvalid) {
        log("warn", "msg|RotU will not be using the waypoints in this map!||");
        validStr = "Invalid";
    } else if (fixedWaypoints) {
        log("server", "msg|RotU sucessfully deleted unlinked waypoints from memory, but the waypoints should still be fixed!||");
        validStr = "Valid, after fixes";
    } else {
        log("server", "msg|Waypoints PASSED critical validation tests!||");
        validStr = "Valid";
    }

    type = "validate";
    if (level.autoMapTesting) {type = "automaptest";}     
    if (level.waypointsInvalid) {
        fmt = "msg|Waypoints are invalid.||waypointsValid|$1||waypointCount|$2:n";
    } else {
        fmt = "msg|Waypoints are valid.||waypointsValid|$1||waypointCount|$2:n";
    }
    log(type, sprintfLog(fmt, validStr, level.Wp.size));

    waypointQuality();
}


/**
 * @brief Checks loaded waypoints for common specification errors
 *
 * @pre waypoints loaded into level.Wp array
 * @returns nothing
 */
waypointQuality()
{
    log("trace", "msg|in _umi::waypointQuality()||");

    for (i=0; i<level.Wp.size; i++) {
        // check waypoint types
        if (!isWaypointTypeValid(level.Wp[i].type)) {
            type = level.Wp[i].type;
            level.Wp[i].type = "stand";
            log("warn", "msg|Waypoint " + i + " had unrecognized type: " + type + ". RotU set type to 'stand'.||");
        }
        // check path types
        if (level.Wp[i].type == "mantle") {
            foundPath = false;
            for (j=0; j<level.Wp[i].linked.size; j++) {
                pathType = scripts\bots\_bot::pathType(i, level.Wp[i].linked[j].ID);
                if (pathType == level.PATH_MANTLE) {
                    foundPath = true;
                    break;
                }
            }
            if (!foundPath) {
                log("warn", "msg|Waypoint " + i + " has type 'mantle', but RotU did not find a valid mantle path.||");
                log("debug", "msg|The mantle waypoint must be linked to the higher destination waypoint.||");
                log("debug", "msg|The destination waypoint must be between " + level.MANTLE_MIN_Z + " and " + level.MANTLE_MAX_Z + " units above the mantle waypoint.||");
                log("debug", "msg|The 2-D distance between the mantle waypoint and the destination waypoint must be less than " + level.MANTLE_MAX_DISTANCE + " units.||");
            }
        } else if (level.Wp[i].type == "teleport") {
            foundPath = false;
            for (j=0; j<level.Wp[i].linked.size; j++) {
                pathType = scripts\bots\_bot::pathType(i, level.Wp[i].linked[j].ID);
                if (pathType == level.PATH_TELEPORT) {
                    foundPath = true;
                    break;
                }
            }
            if (!foundPath) {
                log("warn", "msg|Waypoint " + i + " has type 'teleport', but RotU did not find a valid teleport path.||");
            }
        }
    }
}


/**
 * @brief Checks if a type is a valid waypoint type
 *
 * @param type string A waypoint type to check for validity
 *
 * @returns boolean Indicating whether \ctype is valid or not
 */
isWaypointTypeValid(type)
{
    log("trace", "msg|in _umi::isWaypointTypeValid()||");

    switch(type) {
        case "stand":       // fall through
        case "jump":        // fall through
        case "mantle":      // fall through
        case "ladder":      // fall through
        case "fall":        // fall through
        case "clamped":     // fall through
        case "teleport":
            return true;
    }
    return false;
}


/**
 * @brief Deletes an unlinked waypoint from level.Wp array.
 *        Does not fix the underlying incorrect waypoint in the map or external waypoints file.
 *
 * @param waypointId integer The ID of the unlinked waypoint
 *
 * @returns nothing
 */
deleteUnlinkedWaypoint(waypointId)
{
    log("trace", "msg|in _umi::deleteUnlinkedWaypoint()||");

    // Deleting a waypoint from the middle of the array is very expensive, while
    // deleting it from the end of the array is O(1), so first we ensure the waypoint
    // to be deleted is the last waypoint in the array.
    if (waypointId != level.Wp.size - 1) {
        maps\mp\_umiEditor::devSwapWaypoints(waypointId, level.Wp.size - 1, false);
    }

    // unlink and delete the last waypoint
    level.Wp[level.Wp.size - 1] = undefined;

    // update waypoint count
    level.WpCount = level.Wp.size;
}


/**
 * @brief UMI to build zombie spawn points by the entities' classname property
 *
 * @param classname string The value of the entities' classname property
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildZombieSpawnsByClassname(classname)             // quality:external_interface
{
    log("trace", "msg|in _umi::buildZombieSpawnsByClassname()||");

    ents = getEntArray(classname, "classname");
    if (ents.size == 0) {
        log("error", "msg|Map: No zombie spawn points (entities matching classname: " + classname + ") found.||");
        return;
    }
    for (i=0; i<ents.size; i++) {
        count = i + 1;
        // set targetname property of the spawnpoints so they work with RotU
        ents[i].targetname = "spawngroup"+count;
        buildZombieSpawnByTargetname(ents[i].targetname, 1);
    }
}


/**
 * @brief UMI to build a zombie spawn point by an entity's targetname property
 *
 * @param targetname string The value of the entities' targetname property
 * @param priority int A zombie has a (priority / totalPriority) chance of being spawned here
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
buildZombieSpawnByTargetname(targetname, priority)  // quality:external_interface
{
    log("trace", "msg|in _umi::buildZombieSpawnByTargetname()||");

    if (!isDefined(priority)) {priority = 1;}

    spawns = getentarray(targetname, "targetname");
    if (spawns.size == 0) {
        log("error", "msg|Map: No zombie spawn point matching targetname: " + targetname + ") found.||");
        return;
    }

    for (i=0; i<spawns.size; i++) {
        spawnpoint = spawnStruct();
        spawnpoint.origin = spawns[i].origin;
        if (isDefined(spawns[i].angles)) {spawnpoint.angles = spawns[i].angles;}
        else {spawnpoint.angles = (0,0,0);}
        spawnpoint.priority = priority;
        spawnpoint.children = 0;

        level.botSpawnpoints[level.botSpawnpoints.size] = spawnpoint;
    }
}


/**
 * @brief Finds and loads additional zombie spawnpoints, and loads the spawnpoint queue
 *
 * @returns nothing
 */
findAdditionalSpawnpoints()
{
    log("trace", "msg|in _umi::findAdditionalSpawnpoints()||");

    potentialSpawnpoints = [];

    // For each zombie spawnpoint spec'd in the map by the author, we look for
    // additional spawnpoints near it.  We check four positions releative to the spec'd
    // spawnpoint: 40 units in front, 40 units 35 degrees left of front, 40 units
    // 35 degrees right of front, and 40 units behind.
    for (i=0; i<level.botSpawnpoints.size; i++) {
        spawnpoint = level.botSpawnpoints[i];

        // unit vectors
        anglesLeft = spawnpoint.angles + (0,-35,0);
        anglesRight = spawnpoint.angles + (0,35,0);
        anglesForward = anglesToForward(spawnpoint.angles);
        anglesUp = anglesToUp(spawnpoint.angles);

        // the four positions we will check
        leftOrigin = spawnpoint.origin + (anglesToForward(anglesLeft) * 40);
        rightOrigin = spawnpoint.origin + (anglesToForward(anglesRight) * 40);
        forwardOrigin = spawnpoint.origin + (anglesForward * 40);
        backwardOrigin = spawnpoint.origin + (anglesForward * 40) * -1;

        // a laser at the origin and angles of the original spawnpoint
        // maps\mp\_umiEditor::devDrawLaser("green", spawnpoint.origin + (0,0,20), anglesForward);

        // check the four points, and if OK, consider them to be potential new spawnpoints
        left = isSpawnpointOk(leftOrigin);
        forward = isSpawnpointOk(forwardOrigin);
        right = isSpawnpointOk(rightOrigin);
        backward = isSpawnpointOk(backwardOrigin);
        if (isDefined(left)) {
            potentialSpawnpoint = spawnStruct();
            potentialSpawnpoint.origin = left;
            potentialSpawnpoint.angles = spawnpoint.angles;
            potentialSpawnpoint.parent = i;
            potentialSpawnpoint.priority = 1;
            potentialSpawnpoint.children = 0;
            potentialSpawnpoints[potentialSpawnpoints.size] = potentialSpawnpoint;
        }
        if (isDefined(forward)) {
            potentialSpawnpoint = spawnStruct();
            potentialSpawnpoint.origin = forward;
            potentialSpawnpoint.angles = spawnpoint.angles;
            potentialSpawnpoint.parent = i;
            potentialSpawnpoint.priority = 1;
            potentialSpawnpoint.children = 0;
            potentialSpawnpoints[potentialSpawnpoints.size] = potentialSpawnpoint;
        }
        if (isDefined(right)) {
            potentialSpawnpoint = spawnStruct();
            potentialSpawnpoint.origin = right;
            potentialSpawnpoint.angles = spawnpoint.angles;
            potentialSpawnpoint.parent = i;
            potentialSpawnpoint.priority = 1;
            potentialSpawnpoint.children = 0;
            potentialSpawnpoints[potentialSpawnpoints.size] = potentialSpawnpoint;
        }
        if (isDefined(backward)) {
            potentialSpawnpoint = spawnStruct();
            potentialSpawnpoint.origin = backward;
            potentialSpawnpoint.angles = spawnpoint.angles;
            potentialSpawnpoint.parent = i;
            potentialSpawnpoint.priority = 1;
            potentialSpawnpoint.children = 0;
            potentialSpawnpoints[potentialSpawnpoints.size] = potentialSpawnpoint;
        }
    }

    // test each potential new spawnpoint against all other spawnpoints to ensure
    // they are at least 30 units from each other.  If so, add it as a real spawnpoint.
    added = 0;
    for (i=0; i<potentialSpawnpoints.size; i++) {
        isGood = true;
        for (j=0; j<level.botSpawnpoints.size; j++) {
            dist = distance(potentialSpawnpoints[i].origin, level.botSpawnpoints[j].origin);
            if (dist < 30) {
                // discard this potential spawnpoint
                isGood = false;
                break;
            }
        }
        if (isGood) {
            // add this as a new spawnpoint
            added++;
            level.botSpawnpoints[level.botSpawnpoints.size] = potentialSpawnpoints[i];
            level.botSpawnpoints[potentialSpawnpoints[i].parent].children++;
            anglesUp = anglesToUp(potentialSpawnpoints[i].angles);
            // maps\mp\_umiEditor::devDrawLaser("red", potentialSpawnpoints[i].origin + (0,0,20), anglesUp);
        }
    }

    // Now distribute each spawnpoint's priority amongst itself and its children
    // to preserve the overall priority the map author intended.
    // This math is not correct, but it does give us a close enough approximation.
    lowestPriority = 500;
    for (i=0; i<level.botSpawnpoints.size; i++) {
        level.botSpawnpoints[i].priority = int((level.botSpawnpoints[i].priority * 20) / (level.botSpawnpoints[i].children + 1));
        if (level.botSpawnpoints[i].priority < lowestPriority) {
            lowestPriority = level.botSpawnpoints[i].priority;
        }
    }
    // scale lowestPriority to 1
    for (i=0; i<level.botSpawnpoints.size; i++) {
        level.botSpawnpoints[i].priority = int(level.botSpawnpoints[i].priority / lowestPriority);
    }
    // now give children their parent's reduced priority
    for (i=0; i<level.botSpawnpoints.size; i++) {
        if (!isDefined(level.botSpawnpoints[i].parent)) {continue;}
        level.botSpawnpoints[i].priority = level.botSpawnpoints[level.botSpawnpoints[i].parent].priority;
    }
    log("server", "msg|Added " + added + " extra spawnpoints.||");

    // build a non-randomized queue with the right priorities
    queue = [];
    for (i=0; i<level.botSpawnpoints.size; i++) {
        for (j=0; j<level.botSpawnpoints[i].priority; j++) {
            queue[queue.size] = i;
        }
    }

    // build a filled randomized circular queue we will use to supply spawnpoints
    // for zombies in the game
    while (queue.size > 0) {
        index = randomInt(queue.size);
        level.botSpawnpointsQueue[level.botSpawnpointsQueue.size] = queue[index];
        if (index == queue.size - 1) {
            // is already last element
            queue[index] = undefined;
        } else {
            // copy last element to index, then undefine last element
            queue[index] = queue[queue.size - 1];
            queue[queue.size - 1] = undefined;
        }
    }

    // rebuild level.botSpawnpoints without the now unneeded information
    spawnpoints = level.botSpawnpoints;
    level.botSpawnpoints = [];
    for (i=0; i<spawnpoints.size; i++) {
        sp = spawnStruct();
        sp.origin = spawnpoints[i].origin;
        sp.angles = spawnpoints[i].angles;
        level.botSpawnpoints[i] = sp;
    }

    log("server", sprintfLog("msg|Zombie spawnpoints data||botSpawnpointsSize|$1||botSpawnpointsQueueSize|$2||", level.botSpawnpoints.size, level.botSpawnpointsQueue.size));
    // free unused memory
    potentialSpawnpoints = undefined;
}

/**
 * @brief Tests a potential spawnpoint for obstructions
 *
 * @param origin tuple The location to test
 *
 * @returns The possibly adjusted origin if it is OK, otherwise undefined
 */
isSpawnpointOk(origin)
{
    log("trace", "msg|in _umi::isSpawnpointOk()||");

    // the spec'd spawnpoint may be in the air, with overhead cover, such that
    // we will hit the ceiling when we check for obstructions.  So first we try
    // to find the ground
    trace = bulletTrace(origin + (0,0,20), origin + (0,0,-50), false, undefined);
    if (trace["fraction"] != 1) {
        origin = trace["position"];
    }

    spawnpointClear = true;
    length = 15; // radius of the bot cylinder
    for (h = 5; h<85; h = h + 10) {
        for (i=0; i<360; i = i + 15) {
            center = origin + (0, 0, 45);
            end = origin + (length * cos(i), length * sin(i), h);
            if (!sightTracePassed(center, end, false, undefined)) {
                spawnpointClear = false;
                break;
            }
        }
        if(!spawnpointClear) {break;}
    }
    if (spawnpointClear) {
        // no obstructions detected, see if we are in mid-air
        trace = bulletTrace(origin + (0,0,50), origin + (0,0,-50), false, undefined);
        if (trace["fraction"] == 1) {
            // we are in midair!
            return undefined;
        } else {return trace["position"];}
    } else {return undefined;}
}


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
addPlayerSpawnsByClassname(classname, enabled)      // quality:external_interface
{
    log("trace", "msg|in _umi::addPlayerSpawnsByClassname()||");

    // Do nothing, RotU doesn't need to add player spawns
    log("warn", "msg|Adding player spawns is unsupported.||");
}


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
addPlayerSpawnsByTargetname(targetname, enabled)    // quality:external_interface
{
    log("trace", "msg|in _umi::addPlayerSpawnsByTargetname()||");

    // Do nothing, RotU doesn't need to add player spawns
    log("warn", "msg|Adding player spawns is unsupported.||");
}


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
buildBarricadesByTargetname(targetname, partCount, health, deathFx, buildFx, dropAll)   // quality:external_interface
{
    log("trace", "msg|in _umi::buildBarricadesByTargetname()||");

    if (!isdefined(dropAll)) {dropAll = false;}

    // Map makers can't be trusted:
    //  - to properly count their barricade parts, or
    //  - to properly give them zero-indexed names 'part0', 'part1', etc,
    // which caused runtime errors when we tried to load stuff that didn't exist.
    
    // Our solution is to take the targetname they give us, do our own inspection on it,
    // then load only the destructible barricades that actually exist--those that have parts.
    // There is no point in us loading a staticbarricade that is really just a hack
    // to make something solid.

    ents = getentarray(targetname, "targetname");
    s = 0;
    if (isDefined(ents.size)) {s = ents.size;}
    log("server", sprintfLog("msg|Found $1 barricades named '$2'||", s, targetname));
    for (i=0; i<s; i++) {
        ent = ents[i];
        if (!isDefined(ent)) {
            log("warn", "msg|entity: " + i + " is undefined.||");
            continue;
        }
        // if (isDefined(ent.origin)) {plantFlag(ent.origin);}
        // log("dev", sprintfLog("msg|Found '$1' entity #$2 at $3||", ent.targetname, i, ent.origin));            
        
        temp = [];
        truePartCount = 0;
        // log("dev", sprintfLog("msg|Looking for nearby barricade parts with names starting with `$1`||", ent.target));
        for (j=0; j<int(partCount + 5); j++) { // inspect well beyond the likely end of the array
            testPart = ent getClosestEntity(ent.target + j);
            if (isDefined(testPart)) {
                // log("dev", sprintfLog("msg|Found a barricade part named $1||", testPart.targetname));
                temp[temp.size] = testPart;
                truePartCount++;
            }         
        }
        if (truePartCount == 0) {
            log("server", sprintfLog("msg|Barricade #$1 at $2 is not destructible (no parts); nothing to load.||", i, ent.origin));
            continue;
        }
        level.barricades[level.barricades.size] = ent;
        if (truePartCount != partCount) {
            // mp_surv_dust2 does this
            log("warn", sprintfLog("msg|Map $1 asserts $2 barricade parts, but we found $3 parts.||", level.currentMap, partCount, truePartCount));
        }

        for (j=0; j<temp.size; j++) {
            // Create/load the parts array
            ent.parts[j] = temp[j];
            if (!isDefined(ent.parts[j])) {
                log("bug", sprintfLog("msg|Shouldn't happen. jth part is undefined.||j|$1:n||partCount|$2||", j, partCount));
                continue;
            }
            ent.parts[j].startPosition = ent.parts[j].origin;
            ent.parts[j].isBarricade = true;
            // log("server", sprintfLog("msg|Loaded barricade part '$1' in ent.parts[$2]||", ent.parts[j].targetname, j));
        }
        // prevent divide by zero errors in doBarricadeDamage() when we divide by ent.maxhp
        if (health == 0) {health = 400;} 
        ent.hp = int(health);
        ent.maxhp = int(health);
        ent.partsSize = truePartCount;
        ent.deathFx = deathFx;
        ent.buildFx = buildFx;
        ent.occupied = false;
        ent.dropAll = dropAll;
        ent.isBarricade = true;
        log("server", sprintfLog("msg|Loaded '$1' destructible entity #$2 with $4 parts at $3||", ent.targetname, i, ent.origin, truePartCount));            
        ent thread scripts\players\_barricades::makeBarricade();
    }    
}


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
buildBarricadesByClassname(classname, partCount, health, deathFx, buildFx, dropAll) // quality:external_interface
{
    log("trace", "msg|in _umi::buildBarricadesByClassname()||");

    // Do nothing, RotU builds barricades by targetname
    log("warn", "msg|Building barricades by classname is unsupported. Use _umi::buildBarricadesByTargetname() instead.||");
}


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
buildWeaponPickupByTargetname(targetname, itemText, weapon, weaponType) // quality:external_interface
{
    log("trace", "msg|in _umi::buildWeaponPickupByTargetname()||");

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ent = ents[i];
        ent.myWeapon = weapon;
        ent.wep_type = weaponType;
        level scripts\players\_usables::addUsable(ent, "weaponpickup", "Press [USE] to pick up " + itemText, 96);
    }
}


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
buildWeaponPickupByClassname(classname, itemText, weapon, weaponType)   // quality:external_interface
{
    log("trace", "msg|in _umi::buildWeaponPickupByClassname()||");

    // Do nothing, RotU doesn't build pickup weapons by classname
    log("warn", "msg|Weapon pickups by classname is unsupported. Use _umi::buildWeaponPickupByTargetname() instead.||");
}


/**
 * @brief Sets whether the BTD waypoints are preferred if both BTD and CSV waypoints are available
 *
 * @param value boolean Whether BTD waypoints are preferred over CSV waypoints
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
setPreferBtdWaypoints(value)
{
    log("trace", "msg|in _umi::setPreferBtdWaypoints()||");

    level.preferBtdWaypoints = value;
}


/**
 * @brief Precache common items maps try to use, but often don't precache
 *
 * Must be called before the call to `wait` in the mod
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
precacheCommonItems()
{
    // quality:ignore_trace

    /**
     * Many maps try to load dust_trail_IR, but it generates errors
     * about it not being precached.  Effects cannot be precached after a call to
     * wait(), so we force it to be precached here so it is available when the
     * maps call for it.
     */
    level.barricadefx = loadfx("dust/dust_trail_IR");
    level.windfx = loadfx ("props/car_glass_large");    // mp_fnrp_bigfight  @todo add to mod, have quality check that stuff that should be in the mod is actually in the mod

    /** Many maps try to run shellshock("default_mp", 1), but there
     * was no such shock file, which caused errors about it not being precached.
     * We copied Activision's default.shock file as default_mp.shock, and precache
     * it here to stop these errors
     */
    precacheshellshock("default_mp");

    /**
     * Many maps try to precache these bottles too late, and we can't
     * fix all the maps individually, so we precache them here to stop these errors.
     */
    precacheModel("com_bottle1");
    precacheModel("com_bottle2");
    precacheModel("com_bottle3");
    precacheModel("com_bottle4");

    // Used by UMI so stock barrels don't look like the barrels we use as barricades
    precachemodel("com_barrel_blue_rust");
}


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
waitUntilFirstPlayerSpawns()                        // quality:external_interface
{
    log("trace", "msg|in _umi::waitUntilFirstPlayerSpawns()||");

    // NOTE: Some maps call this method almost *immediately*, thus giving RotU
    // almost no time to get itself set up.  So we ensure we bootstrap a few
    // critical items before any calls to 'wait' or its kin.
    maps\mp\_load::bootstrapCritical();

    log("server", "msg|Map: First call to wait(), it is now too late to precache models or load fx.||");
    // N.B. It doesn't care if the models are already precached or not; it
    //      errors out just calling the precacheModel(), et. al. methods.
    wait 0.5;

    scripts\gamemodes\_gamemodes::initGameMode();

    while (level.activePlayers == 0) {
        wait 0.5;
    }

    maps\mp\_umi::doSpecialRunMode();
}


/**
 * @brief UMI begins the actual gameplay
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
startGame()                                         // quality:external_interface
{
    log("trace", "msg|in _umi::startGame()||");

    if (level.umiEnabled) {
        // Do Nothing.  Don't really start game when we are using UMI or taking screenshots
        log("server", "msg|UMI mode is enabled, not starting game.||");
    } else {
        findAdditionalSpawnpoints();        
        scripts\gamemodes\_survival::beginGame();
    }

}

/**
 * @brief UMI deletes all entities with the given classname property
 *
 * @param classname string The value of the entities' classname property
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteEntitiesByClassname(classname)                // quality:external_interface
{
    log("trace", "msg|in _umi::deleteEntitiesByClassname()||");

    ents = getentarray(classname, "classname");
    for (i=0; i<ents.size; i++) {
        ents[i] delete();
    }
}

/**
 * @brief UMI deletes all entities with the given targetname property
 *
 * @param targetname string The value of the entities' targetname property
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deleteEntitiesByTargetname(targetname)              // quality:external_interface
{
    log("trace", "msg|in _umi::deleteEntitiesByTargetname()||");

    ents = getentarray(targetname, "targetname");
    for (i=0; i<ents.size; i++) {
        ents[i] delete();
    }
}

/**
 * @brief UMI deletes entities with a targetname of "oldschool_pickup"
 *
 * This deletes weapon and perk pickups on CoD4 stock maps, like mp_bog
 *
 * @returns nothing
 * @since RotU 2.2.1
 */
deletePickupItems()                                 // quality:external_interface
{
    log("trace", "msg|in _umi::deletePickupItems()||");

    deleteEntitiesByTargetname("oldschool_pickup");
}

//
// Unified Mapping Interface (UMI) Private Functions
//
// These functions should not be used by map makers, as they are subject to change
// and/or deletion without notice, at the consensus of the developers of the various
// mods.  They are generally utility functions that help make the interface work
// across various mods.
//

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
deleteNearbyEntities(origin, maximumDistance2D, maxDeltaHeight) // quality:external_interface
{
    log("trace", "msg|in _umi::deleteNearbyEntities()||");

    ents = getentarray();
    for (i=0; i<ents.size; i++) {
        if (distance2D(origin, ents[i].origin) < maximumDistance2D) {
            delta = origin[2] - ents[i].origin[2];
            if (delta < 0) {delta = delta * -1;}
            if (delta < maxDeltaHeight) {
                ents[i] delete();
            }
        }
    }
}

/**
 * @brief If both BTD and CVS waypoints are available, prefer the BTD waypoints?
 *
 * @returns boolean Whether the mapper or server operator prefers the BTD waypoints
 * @since RotU 2.2.1
 */
preferBtdWaypoints()                                // quality:external_interface
{
    log("trace", "msg|in _umi::preferBtdWaypoints()||");

    if (isDefined(level.preferBtdWaypoints)) {return level.preferBtdWaypoints;}
    else {return false;}
}

/**
 * @brief Is this map using the unified mapping interface?
 *
 * @returns boolean true if the map uses UMI, false otherwise
 * @since RotU 2.2.1
 */
isUmiMap()                                          // quality:external_interface
{
    log("trace", "msg|in _umi::isUmiMap()||");

    if ((isDefined(level.isZombiescript)) && (level.isZombiescript == 1)) {
        return false;
    }
    return true;
}


/**
 * @brief Attempts to determine the name of the mod loading the map
 * @private
 *
 * @returns string The name of the mod, or an empty string if undetermined
 * @since RotU 2.2.1
 */
privateGuessModName()                               // quality:external_interface
{
    log("trace", "msg|in _umi::privateGuessModName()||");

    return "rotu";
}


//
// Unified Mapping Interface (UMI) Reserved Functions
//
// These functions are reserved for future use as public functions at the consensus
// of the developers of the various mods.  Calling them will not cause a compile
// or a runtime error, but they are't implemented. Any mod developer can implement
// and begin using one of these reserved functions at any time.
//

/**
 * @brief A hook for a function to initialize waypoints. NOOP.
 * @reserved
 *
 * @returns nothing
 */
initWaypoints()                                     // quality:external_interface
{
    // quality:ignore_trace    
}

/**
 * @brief A hook for a function to initialize game setup. NOOP.
 * @reserved
 *
 * @returns nothing
 */
initSetup()                                         // quality:external_interface
{
    // quality:ignore_trace
}

/**
 * @brief A hook for a function to initialize barricades. NOOP.
 * @reserved
 *
 * @returns nothing
 */
initBarricades()                                    // quality:external_interface
{
    // quality:ignore_trace
}

/**
 * @brief A hook for a function to load tradespawns. NOOP.
 * @reserved
 *
 * @returns nothing
 */
loadTradespawn()                                    // quality:external_interface
{
    // quality:ignore_trace
}


//
// RotU legacy functions
//
// These are the function calls in RotU _zombiescript.gsc file as of RotU 2.2.
// They are here for backwards compatibility for old maps.  These functions just
// forward the function call to the appropriate UMI function.
//


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
buildAmmoStock(targetname, loadTime)                // quality:external_interface
{
    log("trace", "msg|in _umi::buildAmmoStock()||");

    setNativeMapType("rotu");
    level.isUmiMap = false;

    buildWeaponShopsByTargetname(targetname, loadTime);
}


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
buildWeaponUpgrade(targetname)                      // quality:external_interface
{
    log("trace", "msg|in _umi::buildWeaponUpgrade()||");

    setNativeMapType("rotu");
    level.isUmiMap = false;

    buildShopsByTargetname(targetname);
}


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
buildSurvSpawn(targetname, priority)                // quality:external_interface
{
    log("trace", "msg|in _umi::buildSurvSpawn()||");

    buildZombieSpawnByTargetname(targetname, priority);
}


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
waittillStart()                                     // quality:external_interface
{
    log("trace", "msg|in _umi::waittillStart()||");

    waitUntilFirstPlayerSpawns();
}


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
startSurvWaves()                                    // quality:external_interface
{
    log("trace", "msg|in _umi::startSurvWaves()||");

    startGame();
}


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
buildBarricade(targetname, partCount, health, deathFx, buildFx, dropAll)    // quality:external_interface
{
    log("trace", "msg|in _umi::buildBarricade()||");

    buildBarricadesByTargetname(targetname, partCount, health, deathFx, buildFx, dropAll);
}


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
buildWeaponPickup(targetname, itemText, weapon, weaponType) // quality:external_interface
{
    log("trace", "msg|in _umi::buildWeaponPickup()||");

    buildWeaponPickupByTargetname(targetname, itemText, weapon, weaponType);
}


/**
 * @brief Allows a mapmaker override the ammoStockType 
 *
 * Call immediately before buildWeaponShopsByTargetname("ammostock")
 *
 * @param type string [weapon|upgrade|ammo] Sets ammo stock type
 *                    weapon    sets level.ammoStockType to "weapon"    // mystery box
 *                    upgrade   sets level.ammoStockType to "upgrade"   // upgrade
 *                    ammo      sets level.ammoStockType to "ammo"      // restock ammo
 *
 * @returns nothing
 */
setAmmoStockType(type)
{
    log("trace", "msg|in _umi::setAmmoStockType()||");

    if (isDefined(type)) {
        switch(type) {
            case "weapon":  // mystery box
            case "upgrade": // weapon upgrade
            case "ammo":    // restock ammo 
                level.ammoStockType = type;
                return;
        }
        log("error", "msg|level.ammoStockType isn't a valid ammoStockType.||");
    }
    log("error", "msg|type undefined isn't a valid ammoStockType.||");
}


/** @deprecated, kept for compat
 * @brief Allows a mapmaker override the ammoStockType
 *
 * ::setAmmoStockType is preferred, as it doesn't use naked numbers
 *
 * @param onGiveWeapons integer [0|1|2] Sets ammo stock type
 *                                    0 sets level.ammoStockType to "weapon"
 *                                    1 sets level.ammoStockType to "upgrade"
 *                                    2 sets level.ammoStockType to "ammo"
 *
 * @returns nothing
 */
setWeaponHandling(onGiveWeapons)                    // quality:external_interface
{
    log("trace", "msg|in _umi::setWeaponHandling()||");

    if (onGiveWeapons == 0) {
        level.onGiveWeapons = 0;
        level.ammoStockType = "weapon";
    } else if (onGiveWeapons == 1) {
        level.onGiveWeapons = 1;
        level.ammoStockType = "upgrade";
    } else if (onGiveWeapons == 2) {
        level.onGiveWeapons = 2;
        level.ammoStockType = "ammo";
    }
}


/**
 * @brief Allows a mapmaker override the default primary and secondary player weapons
 *
 * @param primary string The default primary weapon
 * @param secondary string The default secondary weapon
 *
 * @returns nothing
 */
setSpawnWeapons(primary, secondary)                 // quality:external_interface
{
    log("trace", "msg|in _umi::setSpawnWeapons()||");

    level.spawnPrimary = primary;
    level.spawnSecondary = secondary;
}


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
buildParachutePickup(targetname)                    // quality:external_interface
{
    log("trace", "msg|in _umi::buildParachutePickup()||");

    ents = getentarray(targetname, "targetname");
    //for (i=0; i<ents.size; i++)
    //ents[i] thread scripts\players\_parachute::parachutePickup();
    log("warn", "msg|Map: Parachute pickups are unsupported; doing nothing||");
}


/**
 * @brief Allows a mapmaker to apply a post-processing visual filter
 *
 * @param vision string The name of the vision ao apply
 * @param transitiontime float How long to fade the transition in
 *
 * @returns nothing
 */
setWorldVision(vision, transitiontime)              // quality:external_interface
{
    log("trace", "msg|in _umi::setWorldVision()||");

    scripts\server\_environment::setVision(vision, transitiontime);
}


// This is probably a terrible idea
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
setGameMode(mode)                                   // quality:external_interface
{
    log("trace", "msg|in _umi::setGameMode()||");

    level.gameMode = mode;

    log("server", "msg|Map: First call to wait(), it is now too late to precache models or load fx.||");
    waittillframeend;
}


/**
 * @brief Allows a mapmaker to override using TDM apwnpoints for the players
 *
 * @param targetname string The targetname of the map entities to use as player spawnpoints
 *
 * @returns nothing
 */
setPlayerSpawns(targetname)                         // quality:external_interface
{
    log("trace", "msg|in _umi::setPlayerSpawns()||");

    level.playerspawns = targetname;
}


//
// ROZO legacy functions
// 
// (ROZO) Return of Zombie Ops is a zombie modification for Call of Duty 4,
// it features content from Black Ops Zombie mode as well as from Modern
// Warfare 3 Survival mode and Ghosts Extinction mode.
//
// These are the function calls used for mapping purposes as of ROZO 0.5.
// They are here for backwards compatibility for old maps.  These functions just
// forward the function call to the appropriate UMI function.
//


/**
 * @brief Builds zombie spawn points for old ROZO maps
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @returns nothing
 */
addDefaultZombieSpawns()                            // quality:external_interface
{
    log("trace", "msg|in _umi::addDefaultZombieSpawns()||");

    buildZombieSpawnsByClassname("mp_dm_spawn");
}


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
placeShops(weapons, shops)                          // quality:external_interface
{
    log("trace", "msg|in _umi::placeShops()||");

    setNativeMapType("rozo");
    level.isUmiMap = false;

    // We need to force ROZO maps to waittillStart() or we can't create the usables
    waittillStart();

    buildWeaponShopsByTradespawns(weapons);
    buildShopsByTradespawns(shops);
}


/**
 * @brief Converts waypoints for old ROZO maps
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @returns nothing
 */
convertWaypoints()                                  // quality:external_interface
{
    log("trace", "msg|in _umi::convertWaypoints()||");

    convertToNativeWaypoints();
}


/**
 * @brief NOOP. Old ROZO call.
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @param origin A tuple containing the map position to be the default target
 *
 * @returns nothing
 */
zombieDefaultTarget(origin)                         // quality:external_interface
{
    // quality:ignore_trace

    // Do nothing, RotU doesn't need to set default targets for zombies
}


/**
 * @brief NOOP. Old ROZO call.
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @returns nothing
 */
mapThink()                                          // quality:external_interface
{
    // quality:ignore_trace

    // Do nothing, ROZO internal function
}


/**
 * @brief NOOP. Old ROZO call.
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @returns nothing
 */
setPlayerModels()                                   // quality:external_interface
{
    // quality:ignore_trace

    // Do nothing, ROZO internal function
}


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
getFreeStruct(structs, additional)                  // quality:external_interface
{
    // quality:ignore_trace

    // Do nothing, ROZO internal function
}


/**
 * @brief NOOP. Old ROZO call.
 *
 *        This method should not be used by RotU maps, old or new.
 *
 * @param swap n/a
 *
 * @returns nothing
 */
addDefaultPlayerSpawns(swap)                        // quality:external_interface
{
    // quality:ignore_trace

    // Do nothing, RotU doesn't need to add default player spawns
}


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
addPlayerSpawns(classname, enabled)                 // quality:external_interface
{
    // quality:ignore_trace

    // Do nothing, RotU doesn't need to add player spawns
}

