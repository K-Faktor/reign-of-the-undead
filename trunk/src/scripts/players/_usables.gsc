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

#include scripts\include\data;
#include scripts\include\utility;
#include scripts\include\hud;
#include scripts\include\entities;


init()
{
    log("trace", "msg|in _usables::init()||");

    level.useObjects = [];
    thread debugUsables();
}

debugUsables()
{
    log("trace", "msg|in _usables::debugUsables()||");

    wait 10;
    useObjects = level.useObjects;
    for (i=0; i<useObjects.size; i++) {
        if ((useObjects[i].type == "extras") ||
            (useObjects[i].type == "ammobox")) {
        }
    }
}


/**
 * @brief Adds a usable item to the game
 *
 * @param ent entity The entity to place the usable on
 * @param type string The type of usable
 * @param hintstring string The UI activation hintstring
 * @param distance integer The activation distance for the usable
 *
 * @returns nothing
 */
addUsable(ent, type, hintstring, distance)
{
    log("trace", "msg|in _usables::addUsable()||");

    self.useObjects[self.useObjects.size] = ent;
    ent.occupied = false;
    ent.type = type;
    ent.hintstring = hintstring;
    if (isDefined(distance)) {ent.distance = distance;}
    else {ent.distance = 96;}

    if (ent.type == "revive") {
        log("dev", "msg|Added revive usable to: " + ent.name + "||");
    }
}


/**
 * @brief Removes a usable from the game.
 *
 * @param ent entity The usable entity to remove
 *
 * @returns nothing
 */
removeUsable(ent)
{
    log("trace", "msg|in _usables::removeUsable()||");

    for (i=0; i<level.players.size; i++) {
        player = level.players[i];
        if (isdefined(player.curEnt)) {
            if (player.curEnt == ent) {
                player usableAbort();
                player.curEnt = undefined;
            }
        }
    }

    self.useObjects = removeFromArray(self.useObjects, ent);
    if ((isDefined(ent.isPlayer)) && (ent.isPlayer)) {
        log("dev", "msg|Finished removing usables from: " + ent.name + "||");
    }
}


/**
 * @brief Manages a player's interactions with usables
 *
 * @returns nothing
 */
checkForUsableObjects()
{
    log("trace", "msg|in _usables::checkForUsableObjects()||");

    self endon("death");
    self endon("disconnect");
    self endon("downed");
    self endon("spawned");      // end this instance before a respawn

    self.curEnt = undefined;
    hasPressedF = false;
    isUsing = false;

    while (1) {
        // Don't let the player use this usable if they aren't allowed to use it
        if (!self.canUse) {
            log("dev", "msg|117:" + self.name + " can't use this " + self.curEnt.type + " usable, aborting.||");
            self usableAbort();
            wait .1;
            continue;
        }

        // If player isn't near a usable, try to find a usable
        if (!isdefined(self.curEnt)) {
            // normal whenever player isn't near a usable
            // log("dev", "msg|124:" + self.name + " self.curEnt is undefined||");

            /// @bug: unreviveable: seems to be self.curEnt is undefined, and getBetterUseObj(1024)
            /// is not finding the revive usable
            if (self.isBusy) {self.isBusy = false;}

            if (self getBetterUseObj(1024)) {
                // log("dev", "msg|130:" + self.name + " Found a better use object within 1024 units||");
                wait 0.05;
            }
        }

        // try again
        if (!isdefined(self.curEnt)) {
            // still no usable the player can use.  This is the expected case most of the time
            wait 0.2;
            continue;
        } else {
            // player is near a usable
            extraLogging = false;
            if (self.curEnt.type == "revive") {
                extraLogging = true;
            }

            dis = distance(self.origin, self.curEnt.origin);
            if (extraLogging) {log("dev", sprintfLog("msg|Revive data||name|$1||entType|$2||distance|$3:n||isBusy|$4:b||", self.name, self.curEnt.type, dis, self.isBusy));}

            // Is the player not busy, and within range of this usable?
            if ((!self.isBusy) && (dis <= self.curEnt.distance)) {
                if (self.curEnt.occupied) { // this must be a revive usable, and someone else is already mid-revive
                    // another player is using this usable
                    if (extraLogging) {log("dev", "msg|The " + self.curEnt.type + " usable is occupied||");}
                    log("dev", "msg|150:The " + self.curEnt.type + " usable is occupied||");
                    self.curEnt = undefined;
                    self setclientdvar("ui_hintstring", "" );
                    wait 0.05;
                    continue;
                }

                // Attempt to solve the unrevivable bug--doesn't seem to be the issue
                // Ensure the UI hintstring is properly set
                if ((self.curEnt.type == "revive") && (self.curEnt.hintstring != "Hold [USE] to revive")) {
                    log("error", "msg|Revive hintstring was incorrect; correcting.||");
                    // correct for this player
                    self.curEnt.hintstring = "Hold [USE] to revive";
                    self setclientdvar("ui_hintstring", self.curEnt.hintstring);
                    // correct for the level
                    for (i=0; i<level.useObjects.size; i++) {
                        if (level.useObjects[i] == self.curEnt) {
                            level.useObjects[i].hintstring = "Hold [USE] to revive";
                            break;
                        }
                    }
                }

                if (self useButtonPressed()) {
                    if (hasPressedF == false && self isOnGround() && !self.curEnt.occupied ) {
                        // log("dev", "msg|Starting to use usable||");
                        self thread usableUse();
                        hasPressedF = true;
                    }
                } else {
                    if (hasPressedF == true) {
                        // log("dev", "msg|hasPressedF is true, calling usableAbort()||");
                        self usableAbort();
                        hasPressedF = false;
                    }
                }
            } else {
                // log("dev", "msg|" + self.name + " is busy or NOT within range of the usable of type: " + self.curEnt.type + "||");
                self usableAbort();
            }
            wait .05;
        }
    }
}


/**
 * @brief Prints usables data for dev purposes.  Usually unused.
 *
 * @returns nothing
 */
watchUsablesData()
{
    log("trace", "msg|in _usables::watchUsablesData()||");

    while(!isDefined(level.players)) {
        log("dev", "msg|Waiting for level.players to be defined||");
        wait 2;
    }

    player = undefined;

    // <debug>
    taffJoined = false;
    while (!taffJoined) {
        log("dev", "msg|Waiting for taff to join||");
        player = scripts\include\adminCommon::getPlayerByShortGuid("dcf4d9e5"); // taff @todo this'll wait for this old guid forever
        if (isDefined(player)) {
            taffJoined = true;
            break;
        } else {wait 3;}
    }

    player thread printPlayerUsablesData();
    player endon("disconnect");

    while(1) {
        wait 45;
        player printLevelUsablesData();
    }
    // </debug>
}


/**
 * @brief Print a level usable to the log as JSON
 *
 * @param ent entity The entity to print
 *
 * @returns nothing
 */
printLevelUsableJson(ent)
{
    // quality:ignore_trace

    canUse = self canUseObj(ent);
    isPlayer = isPlayer(ent);
    occupied = ent.occupied;
    entOrigin = ent.origin;
    if (isDefined(ent.name)) {
        name = ent.name;
    } else {name = "undefined";}
    if (isDefined(ent.type)) {
        type = ent.type;
    } else {type = "undefined";}
    if (isDefined(ent.hintstring)) {
        hintstring = ent.hintstring;
    } else {hintstring = "undefined";}
    if (isDefined(ent.distance)) {
        range = ent.distance;
    } else {range = "undefined";}
    fmt = "msg|Entity data||canUse|$1||isPlayer|$2||isOccupied|$3||entOrigin|$4||name|$5||type|$6||range|$7||hintstring|$8||";
    log("dev", sprintfLog(fmt, canUse, isPlayer, occupied, entOrigin, name, type, range, hintstring));
}


/**
 * @brief Print a player usable to the log as JSON
 *
 * @param ent entity The entity to print
 *
 * @returns nothing
 */
printPlayerUsableJson(ent)
{
    // quality:ignore_trace

    canUse = self canUseObj(ent);
    isPlayer = isPlayer(ent);
    occupied = ent.occupied;
    entOrigin = ent.origin;

    selfOrigin = self.origin;
    distance = distance(self.origin, ent.origin);

    if (isDefined(ent.name)) {
        name = ent.name;
    } else {name = "undefined";}
    if (isDefined(ent.type)) {
        type = ent.type;
    } else {type = "undefined";}
    if (isDefined(ent.hintstring)) {
        hintstring = ent.hintstring;
    } else {hintstring = "undefined";}
    if (isDefined(ent.distance)) {
        range = ent.distance;
    } else {range = "undefined";}
    fmt = "msg|Entity data||canUse|$1||isPlayer|$2||isOccupied|$3||entOrigin|$4||name|$5||type|$6||range|$7||hintstring|$8||playerOrigin|$9||distance|$10||";
    log("dev", sprintfLog(fmt, canUse, isPlayer, occupied, entOrigin, name, type, range, hintstring, selfOrigin, distance));
}


/**
 * @brief Prints all level usables data to to g_log as pre-formatted text
 *
 * @returns nothing
 */
printLevelUsablesData()
{
    log("trace", "msg|in _usables::printLevelUsablesData()||");

    if (level.useObjects.size == 0) {return;}
    header = "name           canUse isPlayer  occupied   origin                range   type        hintstring";
    log("pre", header);
    for (i=0; i<level.useObjects.size; i++) {
        ent = level.useObjects[i];
        canUse = self canUseObj(ent);
        isPlayer = isPlayer(ent);
        occupied = ent.occupied;
        entOrigin = ent.origin;
/*        self.origin = self.origin;
        distance = distance(self.origin, ent.origin);*/
        if (isDefined(ent.name)) {
            name = ent.name;
        } else {name = "undefined";}
        if (isDefined(ent.type)) {
            type = ent.type;
        } else {type = "undefined";}
        if (isDefined(ent.hintstring)) {
            hintstring = ent.hintstring;
        } else {hintstring = "undefined";}
        if (isDefined(ent.distance)) {
            range = ent.distance;
        } else {range = "undefined";}
        line = name + " \t" + canUse + " \t" + isPlayer + " \t" + occupied + " \t" + entOrigin + " \t\t" + range + " \t" + type + " \t" + hintstring;
        log("pre", line);
    }
}


/**
 * @brief Prints all player usables data to to g_log as pre-formatted text
 *
 * @returns nothing
 */
printPlayerUsablesData()
{
    log("trace", "msg|in _usables::printPlayerUsablesData()||");
    self endon("disconnect");

    while (1) {
        wait 2;
        // log("dev", "msg|Checking self.useObjects.size||");
        if (self.useObjects.size == 0) {continue;}
        // log("dev", "msg|Checking self.shortGuid||");
        if (self.shortGuid != "dcf4d9e5") {continue;} // only for taff

        header = "playerName   name           canUse isPlayer  occupied   origin                range   distance   type        hintstring";
        log("pre", header);
        for (i=0; i<self.useObjects.size; i++) {
            ent = self.useObjects[i];
            canUse = self canUseObj(ent);
            isPlayer = isPlayer(ent);
            occupied = ent.occupied;
            entOrigin = ent.origin;
            selfOrigin = self.origin;
            distance = distance(self.origin, ent.origin);
            if (isDefined(ent.name)) {
                name = ent.name;
            } else {name = "undefined";}
            if (isDefined(ent.type)) {
                type = ent.type;
            } else {type = "undefined";}
            if (isDefined(ent.hintstring)) {
                hintstring = ent.hintstring;
            } else {hintstring = "undefined";}
            if (isDefined(ent.distance)) {
                range = ent.distance;
            } else {range = "undefined";}
            line = self.name + " \t" + name + " \t" + canUse + " \t" + isPlayer + " \t" + occupied + " \t" + entOrigin + " \t\t" + range + " \t" + distance + " \t" + type + " \t" + hintstring;
            log("pre", line);
        }
    }
}


/**
 * @brief Finds a better usable within \c searchDistance from the player
 *        If successful, it sets self.curEnt to the found entity, and
 *        set the client's UI hintstring
 *
 * @param searchDistance integer Check for usables closer than this
 *
 * @returns boolean indicating whether a better usable was found
 */
getBetterUseObj(searchDistance)
{
    // quality:ignore_trace
    // 15th most-called function (1% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    // search for better usable objects in the level array
    // "revive" usables go in the level array
    bestEnt = undefined;
    for (i=0; i<level.useObjects.size; i++) {
        /// @todo need a debugEntity() to print entity info for debugging
        ent = level.useObjects[i];
        playerCanUse = self canUseObj(ent);
        isEntPlayer = isplayer(ent); // stock method?
        // log("debug", sprintfLog("msg|Useable data||canUseObject|$1:b||entityIsPlayer|$2:b||isEntityOccupied|$3:b||", playerCanUse, isEntPlayer, ent.occupied));
        if ((!playerCanUse) || (ent.occupied)) {continue;}

        dis = distance(self.origin, ent.origin);
        // log("debug", sprintfLog("msg|Useable data||dis|$1:n||entDistance|$2:n||searchDistance|$3:n||", dis, ent.distance, searchDistance));
        if ((dis <= ent.distance) && (dis < searchDistance)) { // ent.distance is the range of the usable
            if (!isEntPlayer) {
                bestEnt = ent;
                if (ent.type == "revive") {break;} // the first revive usable we can use trumps everything else
            }
        }
    }
    if (isDefined(bestEnt)) {
        self setclientdvar("ui_hintstring", bestEnt.hintstring );
        self.curEnt = bestEnt;
        // log("dev", "msg|Found better level usable||");
        // printLevelUsableJson(bestEnt);
        return 1;
    }

    // search for better usable objects in the players own array
    for (i=0; i<self.useObjects.size; i++) {
        ent = self.useObjects[i];
        dis = distance(self.origin, ent.origin);
        if ((dis <= ent.distance) && (!ent.occupied) && (dis < searchDistance)) {
            self setclientdvar("ui_hintstring",ent.hintstring );
            self.curEnt = ent;
            // log("dev", "msg|Found better player usable||");
            // printPlayerUsableJson(ent);
            return 1;
        }
    }
    return 0;
}


/**
 * @brief Can the player use this usable?
 *
 * @param ent entity The usable entity
 *
 * @returns boolean indicating whether player can use this usable
 */
canUseObj(ent)
{
    // quality:ignore_trace
    // 3rd most-called function (13% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (ent == self) {return 0;}
    if (!isDefined(ent.type)) {
        /// @bug somehow, we are getting entities with no .type property!
        log("bug", "msg|Usable entity has no type! Printing current usables.");
        printLevelUsableJson(ent);
        printPlayerUsableJson(ent);
        // printLevelUsablesData();
        // printPlayerUsablesData();
        return 0;
    }
    if (ent.type == "infected" && !self.canCure) {return 0;}
    else if (ent.type == "turret") {
        if ((!isDefined(ent.gun.owner)) || (self != ent.gun.owner)) {return 0;}
        else {return 1;}
    }

    return 1;
}


/**
 * @brief Main logic for actually using a usable item, based on player.curEnt
 *
 * @returns nothing
 */
usableUse()
{
    log("trace", "msg|in _usables::usableUse()||");

    self setclientdvar("ui_hintstring", "");
    if (isDefined(self.curEnt)) {
        if (!canUseObj(self.curEnt)) {
            self usableAbort();
            return;
        }
        self notify("used_usable");
        switch (self.curEnt.type) {
            case "revive":
                self.curEnt.occupied = true;
                self.isBusy = true;
                self.curEnt setclientdvar("ui_infostring", "You are being revived by: " + self.name);
                self freezecontrols(1);
                self disableWeapons();
                self progressBar(self.revivetime);
                self thread reviveInTime(self.revivetime, self.curEnt);
                break;
            case "infected":
                if (!self.curEnt.isDown) {
                    iprintln("^2"+self.curEnt.name+"^2's infection has been cured by " + self.name);
                    self.curEnt scripts\players\_infection::cureInfection();
                    self scripts\players\_players::incUpgradePoints(20*level.dvar["game_rewardscale"]);
                    self thread scripts\players\_rank::giveRankXP("revive");
                }
                break;
            case "weaponpickup":
                self scripts\players\_weapons::swapWeapons(self.curEnt.wep_type, self.curEnt.myWeapon);
                break;
            case "objective":
                level notify("obj_used"+self.curEnt.usable_obj_id);
                break;
            case "extras": // shop
                self setclientdvar("ui_points", self.points);
                self closeMenu();
                self closeInGameMenu();
                self openMenu(game["menu_extras"]);
                break;
            case "teleporter":
                if (level.teleporter.size > 1) {
                    index = randomint(level.teleporter.size-1);
                    ent = level.teleporter[index];
                    if (ent == self.curEnt) {ent = level.teleporter[index+1];}
                    self thread scripts\players\_teleporter::teleOut(self.curEnt, ent.origin, ent.angles);
                } else {
                    ent = getRandomTdmSpawn();
                    self thread scripts\players\_teleporter::teleOut(self.curEnt, ent.origin, ent.angles);
                }
                break;
            case "ammobox": // weapons crate
                if (level.ammoStockType == "ammo") {
                    self.isBusy = true;
                    self freezecontrols(1);
                    self disableWeapons();
                    self progressBar(self.curEnt.loadtime);
                    self thread ammoInTime(self.curEnt.loadtime);
                }
                if (level.ammoStockType == "upgrade") {
                    wep = self getcurrentWeapon();
                    if (wep == self.primary) {scripts\gamemodes\_upgradables::doUpgrade("primary");}
                    if (wep == self.secondary) {scripts\gamemodes\_upgradables::doUpgrade("secondary");}
                    if (wep == self.extra) {scripts\gamemodes\_upgradables::doUpgrade("extra");}
                }
                if (level.ammoStockType == "weapon") {
                    if (!isDefined(self.box_weapon)) {
                        if (self.points >= level.dvar["surv_waw_costs"]) {
                            if (level.dvar["surv_waw_alwayspay"]) {
                                self scripts\players\_players::incUpgradePoints(-1*level.dvar["surv_waw_costs"]);
                            }
                            scripts\gamemodes\_mysterybox::mystery_box(self.curEnt);
                        }
                    } else {
                        if (self.box_weapon.done) {
                            self scripts\players\_weapons::swapWeapons(self.box_weapon.slot, self.box_weapon.weaponName);
                            self.box_weapon delete();
                            if (!level.dvar["surv_waw_alwayspay"]) {
                                self scripts\players\_players::incUpgradePoints(-1*level.dvar["surv_waw_costs"]);
                            }
                        }
                    }
                }
                break;
            case "barricade":
                self.isBusy = true;
                self freezecontrols(1);
                self disableWeapons();
                self progressBar(1);
                self thread restoreBarricadeInTime(1);
                break;
            case "turret":
                self scripts\players\_turrets::moveDefenseTurret(self.curEnt);
                break;
            case "equipmentShop":
                self maps\mp\_umiEditor::devMoveEquipmentShop(self.curEnt);
                break;
            case "weaponsShop":
                self maps\mp\_umiEditor::devMoveWeaponShop(self.curEnt);
                break;
            case "waypoint":
                self maps\mp\_umiEditor::devMoveWaypoint(self.curEnt);
                break;
            case "trap":
                trap = undefined;
                for (i=0; i<level.mapTraps.size; i++) {
                    if (level.mapTraps[i].trigger == self.curEnt) {
                        trap = level.mapTraps[i];
                        break;
                    }
                }
                if (self.points >= trap.cost + 1500) { // 1500 holdback for Heal and Cure
                    if (!trap.isBeingUsed) {
                        self scripts\players\_players::incUpgradePoints(-1 * trap.cost);
                        self thread scripts\players\_traps::startTrap(trap);
                    } else {
                        self iPrintLnBold("This trap is already in use!");
                    }
                } else {
                    self iPrintLnBold("You can not afford it! Cost = ^1" + trap.cost + " + 1500^7");
                }
                break;
        }
    }
}


/**
 * @brief Aborts using a useable, or finishes using a usable.
 *        Unsets player.curEnt, so we are in a consistent state after each usable use
 *
 * @returns nothing
 */
usableAbort()
{
    log("trace", "msg|in _usables::usableAbort()||");

    self notify("usable_abort");
    self setclientdvar("ui_hintstring", "");
    if (isdefined(self.curEnt)) {
        switch (self.curEnt.type)
        {
            case "revive":
                self.isBusy = false;
                self.isReviving = false;
                self.curEnt setclientdvar("ui_infostring", "");
                self.curEnt.occupied = false;
                self freezecontrols(0);
                self EnableWeapons();
                self destroyProgressBar();
            break;
            case "ammobox":
                if (level.ammoStockType == "ammo")
                {
                    self.isBusy = false;
                    self freezecontrols(0);
                    self EnableWeapons();
                    self destroyProgressBar();
                }
            break;
            case "barricade":
                self.isBusy = false;
                self freezecontrols(0);
                self EnableWeapons();
                self destroyProgressBar();
            break;
        }
        self.curEnt = undefined;
    }
}


/**
 * @brief Starts restoration a barricade a player repairs
 *
 * @param time integer Time to delay restoring the barricade
 *
 * @returns nothing
 */
restoreBarricadeInTime(time)
{
    log("trace", "msg|in _usables::restoreBarricadeInTime()||");

    self endon("death");
    self endon("disconnect");
    self endon("usable_abort");
    wait time;

    self thread restoreBarricade();
    self thread usableAbort();
}


/**
 * @brief Restores a barricade a player repaired
 *
 * @returns nothing
 */
restoreBarricade()
{
    log("trace", "msg|in _usables::restoreBarricade()||");

    if (self.curEnt scripts\players\_barricades::restorePart())
    self scripts\players\_players::incUpgradePoints(3*level.dvar["game_rewardscale"]);
}


/**
 * @brief Starts reviving a player
 *
 * @param time integer Time to delay reviving
 * @param player entity The player being revived
 *
 * @returns nothing
 */
reviveInTime(time, player)
{
    log("trace", "msg|in _usables::reviveInTime()||");

    self endon("death");
    self endon("disconnect");
    self endon("usable_abort");
    // self is the reviver
    self.isReviving = true;
    wait 1.25;
    covering = self coveringPlayers();
    wait time - 1.25;

    self thread finishRevive(player, covering);
}


/**
 * @brief Finds players that were defending the player reviving the downed player
 *        We compare this list at start of revive with list at end of revive
 *
 * @returns entity list List of players that defended the revival
 */
coveringPlayers()
{
    log("trace", "msg|in _usables::coveringPlayers()||");

    players = level.players;
    index = 0;
    covering = [];
    for (i=0; i<players.size; i++) {
        if ((players[i].isAlive) &&
            (distance(self.origin, players[i].origin) < 144) &&
            (self.name != players[i].name))// &&
//             (!self.isBusy))
//             (!self.isReviving))
        {
            covering[index] = players[i] getEntityNumber();
            index++;
        }
    }
    return covering;
}


/**
 * @brief Finished reviving a player, & credits defending players
 *
 * @param player entity The player being revived
 * @param startCovering list The players that were defending the revive at the start
 *
 * @returns nothing
 */
finishRevive(player, startCovering)
{
    log("trace", "msg|in _usables::finishRevive()||");

    self endon("death");
    self endon("disconnect");
    self destroyProgressBar();
    self freezecontrols(0);
    if (isdefined(player) && isalive(player)) {
        endCovering = self coveringPlayers();
        player thread scripts\players\_players::revive();
        player notify ("damage", 0);
        iprintln(player.name + "^7 got revived by " + self.name);
        player setclientdvar("ui_infostring", "");
        player.lastUpTime = getTime();

        self thread scripts\players\_rank::giveRankXP("revive");
        self scripts\players\_players::incUpgradePoints(40*level.dvar["game_rewardscale"]);
        self scripts\players\_abilities::rechargeSpecial(15);
        self.reviveCount++;

        // No credit for covering during wave intermission
        if (level.waveIntermission) {
            self.intermissionReviveCount++;
        } else {
            for (i=0; i<startCovering.size; i++) {
                for (j=0; j<endCovering.size; j++) {
                    if (startCovering[i] == endCovering[j]) {
                        // this player covered during the revive, give them credit for it
                        coveringPlayer = scripts\include\adminCommon::getPlayerByEntityNumber(startCovering[i]);
                        log("dev", "msg|" + coveringPlayer.name + " covered the revival of " + player.name + "||");
                        coveringPlayer thread scripts\players\_rank::giveRankXP("revive_cover");
                        coveringPlayer scripts\players\_players::incUpgradePoints(30*level.dvar["game_rewardscale"]);
                        coveringPlayer scripts\players\_abilities::rechargeSpecial(10);
                        coveringPlayer.reviveCoverCount++;
                        iprintln(coveringPlayer.name + " covered the revival of " + player.name);
                    }
                }
            }
        }
    }
    self.isReviving = false;
    wait .5;
    self EnableWeapons();
    self thread usableAbort();
}


/**
 * @brief Restores ammo from weapon crates
 *
 * @param time integer Time to delay ammmo reload
 *
 * @returns nothing
 */
ammoInTime(time)
{
    log("trace", "msg|in _usables::ammoInTime()||");

    self endon("death");
    self endon("disconnect");
    self endon("usable_abort");
    wait time;

    self destroyProgressBar();
    self freezecontrols(0);
    weaponsList = self GetWeaponsList();
    for (idx = 0; idx < weaponsList.size; idx++) {
        if (weaponsList[idx] == "claymore_mp") {continue;}
        if (weaponsList[idx] == "tnt_mp") {continue;}
        if (weaponsList[idx] == "c4_mp") {continue;}
        if (weaponsList[idx] == "frag_grenade_mp") {continue;}

        self giveMaxAmmo(weaponsList[idx]);
    }
    wait .5;
    self EnableWeapons();
}
