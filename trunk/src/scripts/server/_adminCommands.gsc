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
 * @file _adminCommands.gsc This file contains the implementation of all the admin commands
 */


#include scripts\include\data;
#include scripts\include\entities;
#include scripts\include\hud;

#include scripts\include\adminCommon;
#include scripts\include\utility;

init()
{
    log("trace", "msg|in _adminCommands::init()||");

    precache();
    buildAdminData();
    thread onPlayerConnect();
    thread cleanupDeadLocks();
}


/**
 * @brief Removes the admin lock on a player
 *
 * @param player The player to remove the locks from
 *
 * @returns nothing
 */
unlockPlayer(player)
{
    log("trace", "msg|in _adminCommands::unlockPlayer()||");

    player.isLocked = false;
    player.lockedBy = "";
    player.lockTime = -1;
    player.lockingCommand = "";
}



/**
 * @brief Removes dead locks from a player
 * We shouldn't have to do this, but if a bug in the code creates a lock then fails
 * to remove the lock, we unlock the player here after maxLockTime has transpired.
 *
 * @threaded
 *
 * @returns nothing
 */
cleanupDeadLocks()
{
    log("trace", "msg|in _adminCommands::cleanupDeadLocks()||");

    maxLockTime = 7000; // time, in ms
    while(1) {
        players = level.players;
        if (isDefined(players)) {
            for ( i = 0; i < players.size; i++ ) {
                if ((players[i].islocked) && (getTime() > players[i].lockTime + maxLockTime)) {
                    // Player has been locked for 10 seconds or more, so almost certainly
                    // there is a bug in the code that failed to unlock the player
                    message = players[i].name + " was locked by " + players[i].lockedBy;
                    message += " at gametime " + players[i].lockTime + "ms for command " + players[i].lockingCommand;
                    log("bug", "msg|Cleaning dead lock: " + message + "||");
                    unlockPlayer(players[i]);
                }
            }
        }
        wait 5;
    }
}


/**
 * @brief Warns a player
 *
 * @param admin The admin that is warning the player
 * @param reason string The reason the player is being warned
 *
 * @returns nothing
 */
warnPlayer(admin, reason)
{
    log("trace", "msg|in _adminCommands::warnPlayer()||");

    if(isDefined(self)) {
        message = self.name + " ^7got warned on this server. ^3Reason: " + reason + ".";

        if(reason == "silent") {
            self.pers["generalWarnings"]++;
            self setStat(2354, self.pers["generalWarnings"]);
            if (self.pers["generalWarnings"] == level.generalWarningTempBanThreshold) {
                // do temp ban
                temporarilyBanPlayer(admin, reason);
            } else if (self.pers["generalWarnings"] == level.generalWarningBanThreshold) {
                // do perm ban
                // reset warning to just below temp ban, in case admin decides to manually unban player,
                // player will still have some record of bad behavior
                self.pers["generalWarnings"] = level.generalWarningTempBanThreshold - 1;
                banPlayer(admin, reason);
            } else {
                // just warn
                admin thread adminActionConsoleMessage(self.name + " ^7got warned on this server.");
            }
        } else if (reason == "Bad Language") {
            self.pers["badLanguageWarnings"]++;
            self setStat(2355, self.pers["badLanguageWarnings"]);
            if (self.pers["badLanguageWarnings"] == level.badLanguageWarningTempBanThreshold) {
                // do temp ban
                temporarilyBanPlayer(admin, reason);
            } else if (self.pers["badLanguageWarnings"] == level.badLanguageWarningBanThreshold) {
                // do perm ban
                // reset warning to just below temp ban, in case admin decides to manually unban player,
                // player will still have some record of bad behavior
                self.pers["badLanguageWarnings"] = level.badLanguageWarningTempBanThreshold - 1;
                banPlayer(admin, reason);
            } else {
                // just warn
                admin thread informAllPlayersOfAdminAction(self, "negative", message);
                admin thread adminActionConsoleMessage(message);
            }

            // Let player know if they will be banned/temp banned on their next warning
            if (self.pers["badLanguageWarnings"] == level.badLanguageWarningTempBanThreshold - 1) {
                admin thread informPlayerOfAdminAction(self, "negative", "One more bad language warning and you will be temporarily banned.");
            } else if (self.pers["badLanguageWarnings"] == level.badLanguageWarningBanThreshold - 1) {
                admin thread informPlayerOfAdminAction(self, "negative", "One more bad language warning and you will be permanently banned.");
            }
        } else {
            self.pers["generalWarnings"]++;
            self setStat(2354, self.pers["generalWarnings"]);
            if (self.pers["generalWarnings"] == level.generalWarningTempBanThreshold) {
                // do temp ban
                temporarilyBanPlayer(admin, reason);
            } else if (self.pers["generalWarnings"] == level.generalWarningBanThreshold) {
                // do perm ban
                // reset warning to just below temp ban, in case admin decides to manually unban player,
                // player will still have some record of bad behavior
                self.pers["generalWarnings"] = level.generalWarningTempBanThreshold - 1;
                banPlayer(admin, reason);
            } else {
                // just warn
                admin thread informAllPlayersOfAdminAction(self, "negative", message);
                admin thread adminActionConsoleMessage(message);
            }

            // Let player know if they will be banned/temp banned on their next warning
            if (self.pers["generalWarnings"] == level.generalWarningTempBanThreshold - 1) {
                admin thread informPlayerOfAdminAction(self, "negative", "One more general warning and you will be temporarily banned.");
            } else if (self.pers["generalWarnings"] == level.generalWarningBanThreshold - 1) {
                admin thread informPlayerOfAdminAction(self, "negative", "One more general warning and you will be permanently banned.");
            }
        }
        log("server", "msg|Admin " + admin.name + " warned " + self.name + ". Reason: " + reason + ".||");
        unlockPlayer(self);
    }
}

/**
 * @brief Remove one general warning for a player
 *
 * @param admin The admin that is removing one warning from the player
 *
 * @returns nothing
 */
removeOneWarning(admin)
{
    log("trace", "msg|in _adminCommands::removeOneWarning()||");

    if(isDefined(self)) {
        self.pers["generalWarnings"]--;
        if (self.pers["generalWarnings"] < 0) {self.pers["generalWarnings"] = 0;}
        self setStat(2354, self.pers["generalWarnings"]);

        log("server", "msg|Admin " + admin.name + " removed one warning from " + self.name + "||");
        admin thread informPlayerOfAdminAction(self, "positive", "Admin removed one warning from you.");
        admin thread adminActionConsoleMessage("One warning was removed from " + self.name);

        unlockPlayer(self);
    }
}


/**
 * @brief Remove one language warning for a player
 *
 * @param admin The admin that is removing the warning
 *
 * @returns nothing
 */
removeOneLanguageWarning(admin)
{
    log("trace", "msg|in _adminCommands::removeOneLanguageWarning()||");

    if(isDefined(self)) {
        self.pers["badLanguageWarnings"]--;
        if (self.pers["badLanguageWarnings"] < 0) {self.pers["badLanguageWarnings"] = 0;}
        self setStat(2355, self.pers["badLanguageWarnings"]);

        log("server", "msg|Admin " + admin.name + " removed one language warning from " + self.name + "||");
        admin thread informPlayerOfAdminAction(self, "positive", "Admin removed one language warning from you.");
        admin thread adminActionConsoleMessage("One language warning was removed from " + self.name);

        unlockPlayer(self);
    }
}


/**
 * @brief Remove all warnings for a player
 *
 * @param admin The admin that removing the warnings
 *
 * @returns nothing
 */
removeAllWarnings(admin)
{
    log("trace", "msg|in _adminCommands::removeAllWarnings()||");

    if(isDefined(self)) {
        self.pers["badLanguageWarnings"] = 0;
        self setStat(2355, self.pers["badLanguageWarnings"]);

        self.pers["generalWarnings"] = 0;
        self setStat(2354, self.pers["generalWarnings"]);

        log("server", "msg|Admin " + admin.name + " removed all warnings from " + self.name + "||");
        admin thread informPlayerOfAdminAction(self, "positive", "Admin removed all warnings from you.");
        admin thread adminActionConsoleMessage("All warnings were removed from " + self.name);

        unlockPlayer(self);
    }
}


/**
 * @brief Demotes a player one rank, or 750 rank points, whichever is less
 *
 * @param admin The admin that is demoting the player
 *
 * @returns nothing
 */
demotePlayer(admin)
{
    log("trace", "msg|in _adminCommands::demotePlayer()||");

    if(isDefined(self)) {
        rankTaken = false;

        currentRankXP = self scripts\players\_rank::getRankXP();

        currentPrestigeLevel = self scripts\players\_rank::getPrestigeLevel();
        previousPrestigeLevel = currentPrestigeLevel - 1;

        currentRankId = self scripts\players\_rank::getRank();

        if ((currentRankId == 0) && (currentPrestigeLevel == 0)) {
            // We cannot demote the player, just take all their rank points
            newRankXP = 0;
            self.pers["rankxp"] = newRankXP;
            self scripts\players\_persistence::statSet("rankxp", newRankXP);
        } else if ((currentRankId == 0) && (currentPrestigeLevel > 0)) {
            // we will take 750 points and roll back their prestige level & reset rank
            newRankId = level.maxRank;
            newRankXP = int(level.rankTable[newRankId][7]) + currentRankXP - 750;

            // set new rank xp
            self.pers["rankxp"] = newRankXP;
            self scripts\players\_persistence::statSet("rankxp", newRankXP);

            // set new rank
            self.pers["rank"] = newRankId;
            self scripts\players\_persistence::statSet("rank", newRankId);
            self scripts\players\_persistence::statSet("minxp", int(level.rankTable[newRankId][2]));
            self scripts\players\_persistence::statSet("maxxp", int(level.rankTable[newRankId][7]));

            // set current new rank index to stat#252
            self setStat(252, newRankId);
            self setStat(253, newRankId);

            // set new prestige level
            self.pers["prestige"] = previousPrestigeLevel;
            self setStat(2326, self.pers["prestige"]);
            self setStat(210, self.pers["prestige"]);

            self setRank(self.pers["rank"], self.pers["prestige"]);

            rankTaken = true;
        } else {
            // We don't have to worry about crossing prestige boundaries
            currentRankMinXP = int(level.rankTable[currentRankId][2]);
            previousRankId = currentRankId - 1;
            previousRankMinXP = int(level.rankTable[previousRankId][2]);
            if (currentRankXP - previousRankMinXP < 750) {
                // we will demote them to the beginning of the previous rank
                // set new rank xp
                self.pers["rankxp"] = previousRankMinXP;
                self scripts\players\_persistence::statSet("rankxp", previousRankMinXP);

                // set new rank
                self.pers["rank"] = previousRankId;
                self scripts\players\_persistence::statSet("rank", previousRankId);
                self scripts\players\_persistence::statSet("minxp", int(level.rankTable[previousRankId][2]));
                self scripts\players\_persistence::statSet("maxxp", int(level.rankTable[previousRankId][7]));

                // set current new rank index to stat#252
                self setStat(252, previousRankId);
                self setStat(253, previousRankId);

                self setRank(self.pers["rank"], self.pers["prestige"]);

                rankTaken = true;
            } else if (currentRankXP - currentRankMinXP >= 750){
                // we will take 500 rank points, and will not reduce their rank
                newRankXP = currentRankXP - 750;
                self.pers["rankxp"] = newRankXP;
                self scripts\players\_persistence::statSet("rankxp", newRankXP);
            } else {
                // we will take 500 rank points and reduce their rank
                newRankXP = currentRankXP - 750;
                self.pers["rankxp"] = newRankXP;
                self scripts\players\_persistence::statSet("rankxp", newRankXP);

                // set new rank
                self.pers["rank"] = previousRankId;
                self scripts\players\_persistence::statSet("rank", previousRankId);
                self scripts\players\_persistence::statSet("minxp", int(level.rankTable[previousRankId][2]));
                self scripts\players\_persistence::statSet("maxxp", int(level.rankTable[previousRankId][7]));

                // set current new rank index to stat#252
                self setStat(252, previousRankId);
                self setStat(253, previousRankId);

                self setRank(self.pers["rank"], self.pers["prestige"]);
                rankTaken = true;
            }
        }

        if (rankTaken) {
            // Inform player they were demoted
            self glowMessage(&"ZOMBIE_RANK_DEMOTED", "", decimalRgbToColor(255, 0, 0), 5, 90, 2, "mp_level_up");

            log("server", "msg|Admin " + admin.name + " demoted " + self.name + "||");
            admin thread adminActionConsoleMessage("Admin demoted " + self.name);
            unlockPlayer(self);
            return "Player demoted one rank";
        } else {
            log("server", "msg|Admin " + admin.name + " took 750 rank points from " + self.name + "||");
            admin thread informPlayerOfAdminAction(self, "negative", "Admin took 750 rank points from you.");
            admin thread adminActionConsoleMessage("Admin took 750 rank points from " + self.name);
            unlockPlayer(self);
            return "Took 750 rank points";
        }
    }
    return "Command failed";
}


/**
 * @brief Promotes a player one rank, or 750 rank points, whichever is less
 *
 * @param admin The admin that is promoting the player
 *
 * @returns nothing
 */
promotePlayer(admin)
{
    log("trace", "msg|in _adminCommands::promotePlayer()||");

    if(isDefined(self)) {
        rankGiven = false;

        rankId = self scripts\players\_rank::getRank();
        currentRankXP = self scripts\players\_rank::getRankXP();
        currentRankEndingXp = int(level.rankTable[rankId][7]);
        difference = currentRankEndingXp - currentRankXP;
        if (difference <= 750) {
            // promote to next rank
            value = difference + 1;
            rankGiven = true;
        } else {
            // give 750 rank points
            value = 750;
        }

        self scripts\players\_rank::incRankXP(value);

        // Update rank, if required, then notify the player
        if (self scripts\players\_rank::updateRank()) {
            self thread scripts\players\_rank::updateRankAnnounceHUD();
        }

        if (rankGiven) {
            log("server", "masg|Admin " + admin.name + " promoted " + self.name + "||");
            admin thread informPlayerOfAdminAction(self, "positive", "Admin promoted you.");
            admin thread adminActionConsoleMessage("Admin promoted " + self.name);
            unlockPlayer(self);
            return "Player promoted one rank";
        } else {
            log("server", "msg|Admin " + admin.name + " gave 750 rank points to " + self.name + "||");
            admin thread informPlayerOfAdminAction(self, "positive", "Admin gave 750 rank points to you.");
            admin thread adminActionConsoleMessage("Admin gave 750 rank points to " + self.name);
            unlockPlayer(self);
            return "Gave 750 rank points";
        }
    }
    return "Command failed";
}


/**
 * @brief Restore's a player's default primary weapon
 *
 * @param admin The admin that is restoring the player's primary weapon
 *
 * @returns nothing
 */
restorePlayersPrimaryWeapon(admin)
{
    log("trace", "msg|in _adminCommands::restorePlayersPrimaryWeapon()||");

    if(isDefined(self)) {
        if (isDefined(self.primary) && self.primary != "none") {
            self takeweapon(self.primary);
        }
        self.unlock["primary"] = 0;
        self.persData.unlock["primary"] = 0;
        self.persData.primary = getdvar("surv_"+self.class+"_unlockprimary"+self.unlock["primary"]);
        self.persData.primaryAmmoClip = WeaponClipSize(self.persData.primary);
        self.persData.primaryAmmoStock = WeaponMaxAmmo(self.persData.primary);
        self.primary = self.persData.primary;
        self giveWeapon(self.primary);
        self setSpawnWeapon(self.primary);
        self SwitchToWeapon(self.primary);
        self giveMaxAmmo(self.primary);

        admin thread informPlayerOfAdminAction(self, "positive", "Admin restored your default primary weapon.");
        admin thread adminActionConsoleMessage("Admin restored " + self.name + "'s primary weapon.");

        unlockPlayer(self);
    }
}


/**
 * @brief Restore's a player's default sidearm
 *
 * @param admin The admin that is restoring the player's sidearm
 *
 * @returns nothing
 */
restorePlayersSidearm(admin)
{
    log("trace", "msg|in _adminCommands::restorePlayersSidearm()||");

    if(isDefined(self)) {
        if (isDefined(self.secondary) && self.secondary != "none") {
            self takeweapon(self.secondary);
        }
        self.unlock["secondary"] = 0;
        self.persData.unlock["secondary"] = 0;
        self.persData.secondary = getdvar("surv_"+self.class+"_unlocksecondary"+self.unlock["secondary"]);
        self.persData.secondaryAmmoClip = WeaponClipSize(self.persData.secondary);
        self.persData.secondaryAmmoStock = WeaponMaxAmmo(self.persData.secondary);
        self.secondary = self.persData.secondary;
        self giveWeapon(self.secondary);
        self setSpawnWeapon(self.secondary);
        self SwitchToWeapon(self.secondary);
        self giveMaxAmmo(self.secondary);

        admin thread informPlayerOfAdminAction(self, "positive", "Admin restored your default sidearm.");
        admin thread adminActionConsoleMessage("Admin restored " + self.name + "'s sidearm.");

        unlockPlayer(self);
    }
}

/**
 * @brief Gives a player 2,000 upgrade points
 *
 * @param admin The admin that is given the player upgrade points
 *
 * @returns nothing
 */
givePlayerUpgradePoints(admin)
{
    log("trace", "msg|in _adminCommands::givePlayerUpgradePoints()||");

    if(isDefined(self)) {
        self scripts\players\_players::incUpgradePoints(2000);

        admin thread informPlayerOfAdminAction(self, "positive", "Admin gave you 2,000 upgrade points.");
        admin thread adminActionConsoleMessage("Admin gave " + self.name + " 2,000 upgrade points.");

        unlockPlayer(self);
    }
}


/**
 * @brief Permenantly bans a player from this server
 *
 * @param admin The admin that is banning the player
 * @param reason The reason the player is being banned
 *
 * @returns nothing
 */
banPlayer(admin, reason)
{
    log("trace", "msg|in _adminCommands::banPlayer()||");

    if(isDefined(self)) {
        message = self.name + " ^7got banned on this server. ^3Reason: " + reason + ".";

        if(reason == "silent") {
            admin thread adminActionConsoleMessage(self.name + " ^7got ^1BANNED^7 on this server.");
        } else {
            admin thread informAllPlayersOfAdminAction(self, "negative", message);
            admin thread adminActionConsoleMessage(message);
        }

        // In the case of banning, we do not need to unlock the player
        // unlockPlayer(self);

        log("server", "msg|Permanently banned guid: " + self.guid + "||");
        wait 5; // Let player hang around long enough to see they are banned
        ban(self getEntityNumber());
    }
}



/**
 * @brief Kicks a player after a delay, allowing them to rejoin immediately
 * @threaded on player
 *
 * @param admin The admin that is kicking the player
 * @param reason The reason the player is being kicked
 *
 * @returns nothing
 */
kickPlayer(admin, reason)
{
    log("trace", "msg|in _adminCommands::kickPlayer()||");

    if(isDefined(self)) {
        message = self.name + " ^7got kicked on this server. ^3Reason: " + reason + ".";

        if(reason == "silent") {
            admin thread adminActionConsoleMessage(self.name + " ^7got kicked from this server.");
        } else {
            admin thread informAllPlayersOfAdminAction(self, "negative", message);
            admin thread adminActionConsoleMessage(message);
        }

        // In the case of kicking, we do not need to unlock the player
        // unlockPlayer(self);

        wait 5; // Let player hang around long enough to see they are kicked

        log("server", "msg|Admin " + admin.name + " kicked " + self.name + ". Reason: " + reason + ".||");

        if (self.isBot || !self.hasBegun) {return;}

        self setClientDvar("com_errorTitle", "Player kicked.");
        message = "You may re-connect immediately.  Further sanctions may be taken at the admin's discretion.";
        self setClientDvar("com_errorMessage", message);
        wait(1);

        self scripts\players\_players::cleanup();

        lpselfnum = self getEntityNumber();
        lpGuid = self getGuid();
        logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");

        level.players = removeFromArray(level.players, self);
        self thread scripts\players\_players::execClientCommand("disconnect;");
    }
}



/**
 * @brief Temporarily bans a player from this server
 *
 * @param admin The admin that is temp-banning the player
 * @param reason The reason the player is being temp-banned
 *
 * @returns nothing
 */
temporarilyBanPlayer(admin, reason)
{
    log("trace", "msg|in _adminCommands::temporarilyBanPlayer()||");

    if(isDefined(self)) {
        message = self.name + " ^7got temporarily banned on this server. ^3Reason: " + reason + ".";

        if(reason == "silent") {
            admin thread adminActionConsoleMessage(self.name + " ^7got temporarily banned from this server.");
        } else {
            admin thread informAllPlayersOfAdminAction(self, "negative", message);
            admin thread adminActionConsoleMessage(message);
        }

        // In the case of temp banning, we do not need to unlock the player
        // unlockPlayer(self);

        wait 5; // Let player hang around long enough to see they are temp banned

        log("server", "msg|Admin " + admin.name + " temporarily banned " + self.name + ". Reason: " + reason + ".||");

        // Kick() bans player for time set in sv_kickBanTime parameter in server.cfg file
        kick(self getEntityNumber());
    }
}



/**
 * @brief Kills all zombies currently in the game
 *
 * @param admin The admin that is killing the zombies
 *
 * @returns nothing
 */
killZombies(admin)
{
    log("trace", "msg|in _adminCommands::killZombies()||");

    count = 0;
    for (i=0; i<level.bots.size; i++)
    {
        /// We kill level.bots.size, but only report killing the spawned bots
        if (level.bots[i].hasSpawned) {count++;}
        level.bots[i] suicide();
        wait 0.05;
    }

    log("server", "msg|Admin " + admin.name + " killed " + count + " zombies.||");
    admin thread adminActionConsoleMessage("Admin killed " + count + " zombies.");
}


/**
 * @brief Finishes the current game wave
 *
 * @param admin The admin that is finishing the current wave
 *
 * @returns nothing
 */
finishWave(admin)
{
    log("trace", "msg|in _adminCommands::finishWave()||");

    // don't create more bots
    level.playWave = false;
    // simulated wave ending, triggers signal "wave_finished"
    level.waveProgress = level.waveSize;
    // kill existing bots
    for (j=0; j<level.bots.size; j++) {
        level.bots[j] suicide();
        wait 0.05;
    }
    level.playWave = true;

    log("server", "msg|Admin " + admin.name + " finished the wave.||");
}


/**
 * @brief Restarts the current game wave
 *
 * @param admin The admin that is restarting the current wave
 *
 * @returns nothing
 */
restartWave(admin)
{
    log("trace", "msg|in _adminCommands::restartWave()||");

    // don't create more bots
    level.playWave = false;
    // simulated wave ending, triggers signal "wave_finished"
    level.waveProgress = level.waveSize;
    level.waveOrderCurrentWave--;
    level.currentWave--;
    // kill existing bots
    for (j=0; j<level.bots.size; j++) {
        level.bots[j] suicide();
        wait 0.05;
    }
    level.playWave = true;

    admin thread adminActionConsoleMessage("Wave restarting.");
    log("server", "msg|Admin " + admin.name + " restarted the wave.||");
}


/**
 * @brief Restarts the current map
 *
 * @param admin The admin that is restarting the current map
 *
 * @returns nothing
 */
restartMap(admin)
{
    log("trace", "msg|in _adminCommands::restartMap()||");

    log("server", "msg|Admin " + admin.name + " restarted the map.||");

    scripts\server\_maps::changeMap(getdvar("mapname"));
}


/**
 * @brief Finishes the current map
 *
 * @param admin The admin that is finishing the current map
 *
 * @returns nothing
 */
finishMap(admin)
{
    log("trace", "msg|in _adminCommands::finishMap()||");

    // don't create more bots
    level.playWave = false;
    // simulated wave ending, triggers signal "wave_finished"
    level.waveProgress = level.waveSize;
    level.waveOrderCurrentWave = level.waveOrder.size - 1;
    level.currentWave = level.waveOrder.size;
    // kill existing bots
    for (j=0; j<level.bots.size; j++) {
        level.bots[j] suicide();
        wait 0.05;
    }
    level.playWave = true;
    log("server", "msg|Admin " + admin.name + " finished the map.||");
}



/**
 * @brief Changes to the specified map
 *
 * @param admin The admin that is changing the map
 * @param newMap the full name of the map to change to
 *
 * @returns nothing
 */
changeMap(admin, newMap)
{
    log("trace", "msg|in _adminCommands::changeMap()||");

    if (validateMap(newMap)) {
        log("server", "msg|Admin " + admin.name + " changed the map to " + newMap + "||");
        scripts\server\_maps::changeMap(newMap);
    }
}

/**
 * @brief Ensure that \c mapname is a valid map
 *
 * @param mapname string the code name of a map to validate
 *
 * @returns boolean whether the map is a valid map or not
 */
validateMap(mapname)
{
    log("trace", "msg|in _adminCommands::validateMap()||");

    for (i=0; i<level.mapList.size; i++) {
        if (level.mapList[i].name == mapname) {return true;}
    }
    return false;
}


/**
 * @brief Forces a player to drop their current weapon
 *
 * @param admin The admin that is making the player drop their weapon
 *
 * @returns boolean Whether the weapon was dropped or not
 */
dropPlayerWeapon(admin)
{
    log("trace", "msg|in _adminCommands::dropPlayerWeapon()||");

    if(isDefined(self) && self.isAlive)
    {
        currentWeapon = self getCurrentWeapon(); // getCurrentWeapon returns code name string, "ak74u_reflex_mp"
        hasAmmo = false;
        /** FIXED: if weapon is dropped when it has no ammo, it disappears.
         * If the weapon has 20 or less rounds, don't drop it
         */
        if (self getWeaponAmmoStock(currentWeapon) > 20) {
            hasAmmo = true;
        }
        if (hasAmmo) {
            self dropItem( currentWeapon );
            weaponName = currentWeapon;

            admin thread informPlayerOfAdminAction(self, "negative", "Admin made you drop your weapon");
            admin thread adminActionConsoleMessage(self.name + " dropped their " + weaponName + ".");
            unlockPlayer(self);
            return true;
        } else {
            unlockPlayer(self);
            return false;
        }
    }
    unlockPlayer(self);
}



/**
 * @brief Drops an ammo can near the player
 *
 * @param admin The admin that is dropping the ammo box near the player
 *
 * @returns nothing
 */
ammoBox(admin)
{
    log("trace", "msg|in _adminCommands::ammoBox()||");

    if(isDefined(self) && self.isAlive)
    {
        ammoBoxTime = 20;
        adminAmmoBox = Spawn("script_model", self.origin );
        if(IsDefined(adminAmmoBox)){
                adminAmmoBox.angles = (0, 0, 0);
                adminAmmoBox SetModel("ammobox");
        }
        adminAmmoBox thread beAmmobox(ammoBoxTime);
        admin thread informPlayerOfAdminAction(self, "positive", "Admin placed an ammo box near you");
        admin thread adminActionConsoleMessage("Placed an ammo box near ^7" + self.name + ".");
    }
    unlockPlayer(self);
}

/**
 * @brief Makes a script model behave as an ammo box
 * @internal
 *
 * @param time integer the length of time, in seconds, for the ammo box to exist
 *
 * @returns nothing
 */
beAmmobox(time)
{
    log("trace", "msg|in _adminCommands::beAmmobox()||");

    wait 2;
    for (i=0; i<time; i++) {
        for (ii=0; ii<level.players.size; ii++) {
            player = level.players[ii];
            if (distance(self.origin, player.origin) < 120) {
                if (!player.isDown) {
                    self thread restoreAmmoClip(player);
                }
            }
        }
        wait 1;
    }
    self delete();
}


/**
 * @brief Gives a magazine worth of ammunition to a player
 * We do our own restoreAmmoClip() here rather than use
 * scripts\players\_abilities::restoreAmmoClip(), as that function gives points
 * and special recharge benefits to the player that is giving the ammo, and when
 * an admin give the ammo via the admin commands, nobody should get extra points.
 *
 * @internal
 *
 * @param player The player to give the ammunition to
 *
 * @returns nothing
 */
restoreAmmoClip(player)
{
    log("trace", "msg|in _adminCommands::restoreAmmoClip()||");

    weapon = player getcurrentweapon();

    if (!scripts\players\_weapons::canRestoreAmmoByAmmoBoxes(weapon)) {return;}

    stockAmmo = player getWeaponAmmoStock(weapon);
    stockMax = weaponMaxAmmo(weapon);

    if (1) { /// [0|1]: Prevent players from exceeding max explosives from admin ammo box?
        // Don't let players exceed max amount of explosives
        switch (weapon) {
            case "claymore_mp":
                if ((isDefined(player.emplacedClaymores)) &&
                    (player.emplacedClaymores.size + stockAmmo >= level.maxClaymoresPerPlayer))
                {
                    return;
                }
                break;
            case "c4_mp":
                if ((isDefined(player.emplacedC4)) &&
                    (player.emplacedC4.size + stockAmmo >= level.maxC4PerPlayer))
                {
                    return;
                }
                break;
            case "tnt_mp":
                if ((isDefined(player.emplacedTnt)) &&
                    (player.emplacedTnt.size + stockAmmo >= level.maxTntPerPlayer))
                {
                    return;
                }
                break;
        }
    }

    // Rather than use each weapon's actual magazine capacity, we just define
    // it to be 10% of the weapon's maximum ammunition supply
    magazineCapacity = int(stockMax/10);

    // If it is a special weapon, give even less ammo per magazine
    if (scripts\players\_weapons::isSpecialWeap(weapon)) {
        magazineCapacity = int(0.016667 * stockMax);
    }
    // Engineers get half as much ammo from ammo boxes as other players
    if (player.curClass == "engineer") {magazineCapacity = int(magazineCapacity / 2);}
    if (magazineCapacity < 1) {magazineCapacity = 1;}

    if (stockAmmo < stockMax) {
        stockAmmo += magazineCapacity;
        // Don't give the player more ammo than their maximum ammo supply
        if (stockAmmo > stockMax) {
            stockAmmo = stockMax;
        }

        player setWeaponAmmoStock(weapon, stockAmmo);
        player thread screenFlash((0,0,0.65), .5, .6);
        player playlocalsound("weap_pickup");
    }
}


/**
 * @brief Starts a healing aura at the player's position
 *
 * @param admin The admin that is placing the healing aura
 *
 * @returns nothing
 */
healingAura(admin)
{
    log("trace", "msg|in _adminCommands::healingAura()||");

    if(isDefined(self) && self.isAlive)
    {
        origin = self.origin;
        time = 20;
        healObject = scripts\players\_abilities::spawnHealFX(origin, level.healingEffect);
        healObject.healing = self.auraHealing;
        healObject.master = self;
        healObject thread scripts\players\_abilities::beHealingAura(time);

        admin thread informPlayerOfAdminAction(self, "positive", "Admin placed a healing aura near you");
        admin thread adminActionConsoleMessage("Placed a healing aura near ^7" + self.name + ".");
    }
    unlockPlayer(self);
}


/**
 * @brief Takes all of a player's weapons
 *
 * @param admin The admin that is disarming the player
 *
 * @returns nothing
 */
disarmPlayer(admin)
{
    log("trace", "msg|in _adminCommands::disarmPlayer()||");

    if(isDefined(self) && self.isAlive)
    {
        self takeAllWeapons();
        admin thread informPlayerOfAdminAction(self, "negative", "You were disarmed by the Admin");
        admin thread adminActionConsoleMessage("^7" + self.name + "^7 disarmed.");
    }
    unlockPlayer(self);
}



/**
 * @brief Takes a player's current weapon
 *
 * @param admin The admin that is taking the player's current weapon
 *
 * @returns nothing
 */
takePlayersCurrentWeapon(admin)
{
    log("trace", "msg|in _adminCommands::takePlayersCurrentWeapon()||");

    if(isDefined(self) && self.isAlive)
    {
        currentWeapon = self getCurrentWeapon();
        self takeWeapon(currentWeapon);
        admin thread informPlayerOfAdminAction(self, "negative", "Admin took your weapon");
        admin thread adminActionConsoleMessage("^7Took " + self.name + "'s ^7 weapon.");
    }
    unlockPlayer(self);
}



/**
 * @brief Restores a player's health
 *
 * @param admin The admin that is healing the player
 *
 * @returns nothing
 */
healPlayer(admin)
{
    log("trace", "msg|in _adminCommands::healPlayer()||");

    if(isDefined(self) && self.isAlive && self.health != self.maxhealth )
    {
        self.health = self.maxhealth;
        scripts\include\hud::updateHealthHud(1);
        admin thread informPlayerOfAdminAction(self, "positive", "Your health was restored by Admin");
        admin thread adminActionConsoleMessage("^7Restored " + self.name + "^7's health to maximum.");
    }
    unlockPlayer(self);
}



/**
 * @brief Cures a player's infection
 *
 * @param admin The admin that is curing the player
 *
 * @returns nothing
 */
curePlayer(admin)
{
    log("trace", "msg|in _adminCommands::curePlayer()||");

    if(isDefined(self) && self.isAlive && self.infected)
    {
        self scripts\players\_infection::cureInfection();
        admin thread informPlayerOfAdminAction(self, "positive", "Your infection was cured by Admin");
        admin thread adminActionConsoleMessage("^7Cured " + self.name + "^7's infection.");
    }
    unlockPlayer(self);
}


/**
 * @brief Spawns a player if they are a spectator
 *
 * @param admin The admin that is spawning the player
 *
 * @returns nothing
 */
spawnPlayer(admin)
{
    log("trace", "msg|in _adminCommands::spawnPlayer()||");

    if (self.isSpectating) {
        // choose one of the unrestricted classes to spawn the player as
        class = "soldier";
        switch(randomInt(3)) {
            case 0:
                class = "soldier";
                break;
            case 1:
                class = "armored";
                break;
            case 2:
                class = "scout";
                break;
        }
        self.class = class;
        self scripts\players\_classes::acceptClass(true);
        admin thread informPlayerOfAdminAction(self, "nuetral", "You were spawned by the Admin");
        admin thread adminActionConsoleMessage("^7 " + self.name + " ^7spawned.");
        unlockPlayer(self);
        return true;
    } else {
        admin thread adminActionConsoleMessage("^7 Can't spawn a player that isn't spectating");
        unlockPlayer(self);
        return false;
    }
}

/**
 * @brief Bounces a player
 *
 * @param admin The admin that is bouncing the player
 *
 * @returns nothing
 */
bouncePlayer(admin)
{
    log("trace", "msg|in _adminCommands::bouncePlayer()||");

    if(isDefined(self) && self.isAlive)
    {
        // increase fall damage minimum height so they land gently
        self setClientDvar("bg_fallDamageMaxHeight", "9999"); // ~833 feet
        self setClientDvar("bg_fallDamageMinHeight", "9998"); // ~833 feet
        wait 0.1;

        for( i = 0; i < 2; i++ ) {
            self doBounce(vectorNormalize(self.origin - (self.origin - (0,0,20)) ), 200 );
        }
        admin thread informPlayerOfAdminAction(self, "nuetral", "You were bounced by the Admin");
        admin thread adminActionConsoleMessage("^7Bounced " + self.name + "^7.");

        self thread restoreFallDamageMinHeight();
    }
    unlockPlayer(self);
}

/**
 * @brief Performs one step of the bounce command
 * @internal
 *
 * @param newPosition integer vector The final position after the explosive bounce
 * @param power integer The power of the explosion
 *
 * @returns nothing
 */
doBounce(newPosition, power)
{
    log("trace", "msg|in _adminCommands::doBounce()||");

    // save original health
    health = self.health;
    // add enough health we don't kill the player due to the damage from the explosion
    self.health = self.health + power;
    // turn off the kick from the explosion
    self setClientDvars( "bg_viewKickMax", 0, "bg_viewKickMin", 0, "bg_viewKickRandom", 0, "bg_viewKickScale", 0 );
    // do the explosion that bounces the player
    self finishPlayerDamage( self, self, power, 0, "MOD_PROJECTILE", "none", undefined, newPosition, "none", 0 );
    // restore the player's original health
    self.health = health;
    self thread kickRestore();
}

/**
 * @brief Restore the default kick parameters after a bounce
 * @internal
 *
 * @returns nothing
 */
kickRestore()
{
    log("trace", "msg|in _adminCommands::kickRestore()||");

    self endon( "disconnect" );
    wait .05;
    // restore default kick from damage
    self setClientDvars( "bg_viewKickMax", 90, "bg_viewKickMin", 5, "bg_viewKickRandom", 0.4, "bg_viewKickScale", 0.2 );
}

/**
 * @brief Retsores the minimum fall height damage parameter after a bounce
 *
 * @returns nothing
 */
restoreFallDamageMinHeight()
{
    log("trace", "msg|in _adminCommands::restoreFallDamageMinHeight()||");

    self endon( "disconnect" );

    // wait until the player lands
    while (!(self isOnGround())) {
        wait 1;
    }

    if (isDefined(level.fallDamageMaxHeight)) {
        self setClientDvar("bg_fallDamageMaxHeight", level.fallDamageMaxHeight);
    } else {
        self setClientDvar("bg_fallDamageMaxHeight", "300"); // ~25 ft
    }

    if (isDefined(level.fallDamageMinHeight)) {
        self setClientDvar("bg_fallDamageMinHeight", level.fallDamageMinHeight);
    } else {
        self setClientDvar("bg_fallDamageMinHeight", "128"); // ~10.6 feet
    }
}

/**
 * @brief Teleports a player to the spawn point
 *
 * @param admin The admin that is teleporting the player
 *
 * @returns nothing
 */
teleportPlayerToSpawn(admin)
{
    log("trace", "msg|in _adminCommands::teleportPlayerToSpawn()||");

    if(isDefined(self) && self.isAlive) {
        self setOrigin(self.originalSpawnLocation);
        admin thread informPlayerOfAdminAction(self, "nuetral", "You were teleported by admin");
        admin thread adminActionConsoleMessage("^7 " + self.name + " ^7was teleported to spawn point.");
    }
    unlockPlayer(self);
}


/**
 * @brief Teleports a player to the admin's location
 *
 * @param location The player's new location
 * @param admin The admin that is teleporting the player
 *
 * @returns nothing
 */
teleportPlayerToAdmin(location, admin)
{
    log("trace", "msg|in _adminCommands::teleportPlayerToAdmin()||");

    if(isDefined(self) && self.isAlive) {
        self setOrigin(location);
        admin thread informPlayerOfAdminAction(self, "nuetral", "You were teleported by admin");
        admin thread adminActionConsoleMessage("^7 " + self.name + " ^7was teleported to admin's location'.");
    }
    unlockPlayer(self);
}



/**
 * @brief Teleports a player forward about 3 feet
 *
 * @param admin The admin that is teleporting the player
 *
 * @returns nothing
 */
teleportPlayerForward(admin)
{
    log("trace", "msg|in _adminCommands::teleportPlayerForward()||");

    if(isDefined(self) && self.isAlive)
    {
        position = self.origin;
        distance = 120;
        playerAngles = self getPlayerAngles();
        // Set new position to be 120 inches forward, and 45 inches up
        positionOffset = (distance * cos(playerAngles[1]), distance * sin(playerAngles[1]), 45);
        newPosition = position + positionOffset;
        self setOrigin(newPosition);
        admin thread informPlayerOfAdminAction(self, "nuetral", "You were teleported by admin");
        admin thread adminActionConsoleMessage("^7 " + self.name + " ^7was teleported forward.");
    }
    unlockPlayer(self);
}



/**
 * @brief Downs a player, but they can still be revived
 *
 * @param admin The admin that is downing the player
 *
 * @returns nothing
 */
downPlayer(admin)
{
    log("trace", "msg|in _adminCommands::downPlayer()||");

    if(isDefined(self) && self.isAlive)
    {
        if (!isDefined(self.isPlayer)) {
            log("bug", "msg|" + self.name + " can't be downed because self.isPlayer is undefined.||");
            unlockPlayer(self);
            return;
        } else if (!self.isPlayer){
            log("bug", "msg|" + self.name + " can't be downed because self.isPlayer is false.||");
            unlockPlayer(self);
            return;
        }

        interval = 1;
        damage = 25;
        while (!self.isDown)
        {
            self damageEnt(
                self, // eInflictor = the entity that causes the damage (e.g. a claymore)
                self, // eAttacker = the player that is attacking
                damage, // iDamage = the amount of damage to do
                "MOD_EXPLOSIVE", // sMeansOfDeath = string specifying the method of death (e.g. "MOD_PROJECTILE_SPLASH")
                "none", // sWeapon = string specifying the weapon used (e.g. "claymore_mp")
                self.origin, // damagepos = the position damage is coming from
                //(0,self GetPlayerAngles()[1],0) // damagedir = the direction damage is moving in
                (0,0,0)
                );
            wait interval;
        }
        admin thread informPlayerOfAdminAction(self, "negative", "You were downed by the Admin");
        admin thread adminActionConsoleMessage("^7 " + self.name + " ^7downed.");
    }
    unlockPlayer(self);
}


/**
 * @brief Revives a player
 *
 * @param admin The admin that is reviving the player
 *
 * @returns nothing
 */
revivePlayer(admin)
{
    log("trace", "msg|in _adminCommands::revivePlayer()||");

    if((isDefined(self)) &&
       (self.isDown) &&
       (!self.isZombie) &&
       (!self.infected))
    {
        self scripts\players\_players::revive();
        admin thread informPlayerOfAdminAction(self, "positive", "You were revived by Admin");
        admin thread adminActionConsoleMessage("^7Revived " + self.name + ".");
        log("server", "msg|" + admin.name + " revived " + self.name + "||");
    }
    unlockPlayer(self);
}



/**
 * @brief Kills a player, and they cannot be revived
 *
 * @param admin The admin that is killing the player
 *
 * @returns nothing
 */
explodePlayer(admin)
{
    log("trace", "msg|in _adminCommands::explodePlayer()||");

    if(isDefined(self) && self.isAlive)
    {
        playFx( level.fx["bombexplosion"], self.origin );
        admin thread informPlayerOfAdminAction(self, "negative", "You were exploded by the Admin");
        self suicide();
        admin thread adminActionConsoleMessage("^7 " + self.name + " ^7exploded.");
    }
    // in the case of explode player, we do not need to unlock the player
    // unlockPlayer(self);
}

