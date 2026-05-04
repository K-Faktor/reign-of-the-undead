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

init()
{
    log("trace", "msg|in _persistence::init()||");

    level.persistentDataInfo = [];
    level.persPlayerData = [];
    level thread onPlayerConnect();
    // debugStatsTable();
}


/** @deprecated
 * @brief Initializes one unused property (.enableText)
 *
 * @returns nothing
 */
onPlayerConnect()
{
    log("trace", "msg|in _persistence::onPlayerConnect()||");

    for(;;) {
        level waittill("connected", player);

        player setClientDvar("ui_xpText", "1");
        player.enableText = true;
    }

}


/**
 * @brief Loads existing persisted player data, or initializes it for new players
 *
 * @returns nothing
 */
restoreData()
{
    log("trace", "msg|in _persistence::restoreData()||");

    struct = level.persPlayerData[self.guid];
    if (!isdefined(struct)) {
        struct = spawnstruct();
        level.persPlayerData[self.guid] = struct;
        struct.unlock["primary"] = 0;
        struct.unlock["secondary"] = 0;
        struct.unlock["extra"] = 0;
        struct.primary = level.spawnPrimary;
        struct.primaryAmmoStock = 10;
        struct.primaryAmmoClip = 10;
        struct.secondary = level.spawnSecondary;
        struct.secondaryAmmoStock = 0;
        struct.secondaryAmmoClip = 0;
        struct.extra = "none";
        struct.extraAmmoStock = 0;
        struct.extraAmmoClip = 0;
        struct.points = level.dvar["game_startpoints"];
        struct.isDown = false;
        struct.downOrigin = (0,0,0);
        struct.class = "";
    }
    self.persData = struct;

    self.points = struct.points;
    self.unlock["primary"] = struct.unlock["primary"];
    self.unlock["secondary"] = struct.unlock["secondary"];
    self.unlock["extra"] = struct.unlock["extra"];

}


/**
 * @brief Prints a player's stats table to g_log
 *
 * @returns nothing
 */
debugStatsTable()
{
    log("trace", "msg|in _persistence::debugStatsTable()||");

    for (i=0; i<2500; i++) {
        log("dev", "msg|" + tableLookup("mp/playerStatsTable.csv", 0, i, 0) + ":" + tableLookup("mp/playerStatsTable.csv", 0, i, 1) + "||");
    }
}


/**
 * Script persistent data functions
 * These are made for convenience, so persistent data can be tracked by strings.
 * They make use of code functions which are prototyped below.
 */

/**
 * @brief Gets a stat value from the player's stats table
 *
 * @param dataName string The name of the stat to retrieve
 *
 * @returns integer The value of the stat
 */
statGet(dataName)
{
    log("trace", "msg|in _persistence::statGet()||");

    return self getStat(int(tableLookup("mp/playerStatsTable.csv", 1, dataName, 0)));
}


/**
 * @brief Sets a stat value in the player's stats table
 *
 * @param dataName string The name of the stat to set
 * @param value unknown The value of the stat to set - probably ints, but maybe strings; needs testing
 *
 * @returns nothing
 */
statSet(dataName, value)
{
    log("trace", "msg|in _persistence::statSet()||");

    self setStat(int(tableLookup("mp/playerStatsTable.csv", 1, dataName, 0)), value);
}


/**
 * @brief Sets a stat to it's current value plus some delta
 *
 * @param dataName string The name of the stat to set
 * @param delta integer The value to change the current stat by
 *
 * @returns nothing
 */
statAdd(dataName, delta)
{
    log("trace", "msg|in _persistence::statAdd()||");

    curValue = self getStat(int(tableLookup("mp/playerStatsTable.csv", 1, dataName, 0)));
    self setStat(int(tableLookup("mp/playerStatsTable.csv", 1, dataName, 0)), delta + curValue);
}
