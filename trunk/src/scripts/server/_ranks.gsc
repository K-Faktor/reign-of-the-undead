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

// This file is deprecated, and needs to be removed

/** @deprecated
 * @brief init
 *
 * @returns nothing
 */
init()
{
    log("trace", "msg|in _ranks::init()||");

    level.rank = [];
    setupRanks();
}


/** @deprecated
 * @brief Loads custom rank dvars
 *
 * @returns nothing
 */
setupRanks()
{
    log("trace", "msg|in _ranks::setupRanks()||");

    i = 1;
    for (;;) {
        dvar = getdvar("rank_custom_" + i);
        if (dvar == "") {return;}
        else {addRank(dvar);}
        i++;
    }
}


/** @deprecated
 * @brief Loads a player's rank
 * 
 * This entire file seems mostly deprecated.  This is the pnly method used; called from
 * _clients::Callback_PlayerConnect().
 *
 * It mostly loads level.rank[] array, which is unused outside of this file.
 *
 * @returns boolean 1 if rank was loaded, 0 otherwise
 */
loadPlayerRank()
{
    log("trace", "msg|in _ranks::loadPlayerRank()||");

    log("dev", "msg|in _ranks::loadPlayerRank()||");
    self.title = "";                // used in _players::Callback_PlayerConnect() if non-empty, and tested for non-empty
    self.overrideStatusIcon = "";   // unused, except for tested for empty string in _players::setStatusIcon()
    self.power = 0;                 // unused
    guid = self getGuid();

    if (guid == "") {
        self.title = "^5HOST";
        self.power = 100;
        log("dev", "msg|setting title to HOST||");
        return 1;
    }

    log("dev", "msg|level.rank.size: " + level.rank.size + "||");

    for (i=0; i<level.rank.size; i++) {
        struct = level.rank[i];
        for (j=0; j<level.rank[i].players.size; j++) {
            if (level.rank[i].players[j] == getSubStr(guid, 24, 32)) {
                self.title = level.rank[i].title;
                self.power = level.rank[i].power;
                self.overrideStatusIcon = level.rank[i].icon;
                self.statusicon = self.overrideStatusIcon;
                return 1;
            }
        }
    }
    return 0;
}


/** @deprecated
 * @brief unused
 *
 * @param rank_title string unused
 * @param guid string unused
 * 
 * @returns nothing
 */
addGuid(rank_title, guid)
{
    log("trace", "msg|in _ranks::addGuid()||");

    for (i=1; i<level.rank.size; i++) {
        if (IsSubStr(rank_title, level.rank[i].title)) {
            level.rank[i].players[level.rank[i].players.size] = guid;
            return;
        }
    }
}

/** @deprecated
 * @brief unused
 *
 * @param title string unused
 * @param power integer unused
 * @param icon string unused
 * 
 * @returns nothing
 */
addRank(title, power, icon)
{
    log("trace", "msg|in _ranks::addRank()||");

    // only called from ::setupRanks, but with a single param, the value of a rank_custom_N dvar
    struct = spawnstruct();
    struct.ID = level.rank.size;
    level.rank[level.rank.size] = struct;
    struct.title = title;
    struct.power = power;
    if (!isdefined(icon)) {icon = "";}
    struct.players = [];
}
