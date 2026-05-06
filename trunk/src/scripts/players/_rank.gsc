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

#include common_scripts\utility;
#include scripts\include\hud;
#include scripts\include\utility;


/**
 * @brief Initializes rank, scores, UI strings, and stats data
 *
 * @returns nothing
 */
init()
{
    log("trace", "msg|in _rank::init()||");

    level.scoreInfo = [];
    level.rankTable = [];

    level.rankedMatch = 1;

    precacheShader("white");

    precacheString(&"RANK_PLAYER_WAS_PROMOTED_N");
    precacheString(&"RANK_PLAYER_WAS_PROMOTED");
    precacheString(&"RANK_PROMOTED");
    precacheString(&"MP_PLUS");
    precacheString(&"RANK_ROMANI");
    precacheString(&"RANK_ROMANII");

    registerScoreInfo("kill", 10);
    registerScoreInfo("assist0", 1);
    registerScoreInfo("assist1", 2);
    registerScoreInfo("assist2", 3);
    registerScoreInfo("assist3", 5);
    registerScoreInfo("assist4", 7);
    registerScoreInfo("assist5", 10);
    registerScoreInfo("revive", 50);
    registerScoreInfo("revive_cover", 40); // providing covering fire for a revive
    registerScoreInfo("headshot", 10);
    registerScoreInfo("suicide", 0);
    registerScoreInfo("teamkill", 0);


    registerScoreInfo( "challenge", 250 );

    // @deprecated rankTable2.csv and rankicontable2.csv are deprecated, I guess

    // tableLookup(fileName, keyColumn, keyValue, dataColumn)
    // tableLookupIString(fileName, keyColumn, keyValue, dataColumn)
    // zero-indexed max number of ranks, i.e. 54
    level.maxRank = int(tableLookup( "mp/rankTable.csv", 0, "maxrank", 1 ));
    // number of prestige levels, i.e. 65
    level.maxPrestige = int(tableLookup( "mp/rankIconTable.csv", 0, "maxprestige", 1 ));

    // For every row/column location in rankIconTable.csv, precache the rank icon
    for (column = 0; column <= level.maxPrestige; column++) {
        for (row = 0; row <= level.maxRank; row++) {
            precacheShader(tableLookup("mp/rankIconTable.csv", 0, row, column+1));
        }
    }

    // Load all the basic info about the ranks from rankTable.csv
    rankId = 0;
    rankName = tableLookup("mp/ranktable.csv", 0, rankId, 1);
    assert ((isDefined(rankName)) && (rankName != ""));
    while ((isDefined(rankName)) && (rankName != "")) {
        // rankID, i.e. "pfc1"
        level.rankTable[rankId][1] = tableLookup("mp/ranktable.csv", 0, rankId, 1);
        // rank starts at this rankXP level, i.e. 0
        level.rankTable[rankId][2] = tableLookup("mp/ranktable.csv", 0, rankId, 2);
        // need to earn this many rankXP points while this rank to get next rank, i.e. 10
        level.rankTable[rankId][3] = tableLookup("mp/ranktable.csv", 0, rankId, 3);
        // next rank starts at this rankXP, i.e. 10
        level.rankTable[rankId][7] = tableLookup("mp/ranktable.csv", 0, rankId, 7);
        // localized string name for the rank
        precacheString(tableLookupIString("mp/ranktable.csv", 0, rankId, 16));

        rankId++;
        rankName = tableLookup("mp/ranktable.csv", 0, rankId, 1);
    }

    level.statOffsets = [];
    level.statOffsets["weapon_assault"] = 290;
    level.statOffsets["weapon_lmg"] = 291;
    level.statOffsets["weapon_smg"] = 292;
    level.statOffsets["weapon_shotgun"] = 293;
    level.statOffsets["weapon_sniper"] = 294;
    level.statOffsets["weapon_pistol"] = 295;
    level.statOffsets["perk1"] = 296;
    level.statOffsets["perk2"] = 297;
    level.statOffsets["perk3"] = 298;

    level.numChallengeTiers = 10;

    //buildChallegeInfo();
}


/**
 * @brief Is \c type a registered scoring event type?
 *
 * @param type string The name of the type of score
 *
 * @returns boolean indicating whether type is a known type or not
 */
isRegisteredEvent(type)
{
    log("trace", "msg|in _rank::isRegisteredEvent()||");

    if (isDefined(level.scoreInfo[type])) {return true;}
    else {return false;}
}


/**
 * @brief Registers a score value forthey given score type
 *
 * @param type string The name of the type of score
 * @param value integer The score awarded for that type
 *
 * @returns nothing
 */
registerScoreInfo(type, value)
{
    log("trace", "msg|in _rank::registerScoreInfo()||");

    level.scoreInfo[type]["value"] = value;
}


/**
 * @brief Get the value for a given score type
 *
 * @param type string The name of the type of score
 *
 * @returns integer the value for that type of score
 */
getScoreInfoValue(type)
{
    log("trace", "msg|in _rank::getScoreInfoValue()||");

    return (level.scoreInfo[type]["value"]);
}


/**
 * @brief Get the label for a given score type. Unused.
 *
 * @param type string The name of the type of score
 *
 * @returns string the label for that type of score
 */
getScoreInfoLabel(type)
{
    log("trace", "msg|in _rank::getScoreInfoLabel()||");

    return (level.scoreInfo[type]["label"]);
}


/**
 * @brief Get the minimum XP for a given rank
 *
 * @param rankId integer The Id for the rank.
 *                       [0, 54] in rankTable.csv
 *
 * @returns integer the minimum XP for that rank
 */
getRankInfoMinXP(rankId)
{
    log("trace", "msg|in _rank::getRankInfoMinXP()||");

    return int(level.rankTable[rankId][2]); // 2nd 0-based column in rankTable.csv
}


/**
 * @brief Gets the range of XP for this rank. This rank's
 *        minXP + XPAmt == next rank's minXP == this rank's maxXP
 *
 * @param rankId integer The Id for the rank, [0, 54]
 *
 * @returns integer the range of XP for that rank
 */
getRankInfoXPAmt(rankId)
{
    log("trace", "msg|in _rank::getRankInfoXPAmt()||");

    return int(level.rankTable[rankId][3]); // 3rd 0-based column in rankTable.csv
}


/**
 * @brief Gets the maximum XP for this rank.
 *
 * @param rankId integer The Id for the rank, [0, 54]
 *
 * @returns integer the maximum of XP for that rank
 */
getRankInfoMaxXp(rankId)
{
    log("trace", "msg|in _rank::getRankInfoMaxXp()||");

    return int(level.rankTable[rankId][7]); // 7th 0-based column in rankTable.csv
}


/**
 * @brief Gets the UI key for the rank name
 *
 * @param rankId integer The Id for the rank, [0, 54]
 *
 * @returns string the key for the rank name, like RANK_CPL_FULL_N
 */
getRankInfoFull(rankId)
{
    log("trace", "msg|in _rank::getRankInfoFull()||");

    return tableLookupIString("mp/ranktable.csv", 0, rankId, 16); // 16th 0-based column in rankTable.csv
}


/**
 * @brief Gets the UI key for the rank name
 *
 * @param rankId integer The Id for the rank, [0, 54]
 * @param prestigeId integer The Id for the prestige level.
 *                           [1, 65] are real prestige levels, 0 is valid,
 *                           and used for players that haven't prestiged.
 *
 * @returns string the key for the prestige Id, like rank_prestige_5, or rank_ltgen3
 */
getRankInfoIcon(rankId, prestigeId)
{
    log("trace", "msg|in _rank::getRankInfoIcon()||");

    return tableLookup("mp/rankIconTable.csv", 0, rankId, prestigeId+1); // prestigeId + 1 --> [2, 66]
}


/**
 * @brief Gets the weapon unlocked at the rank, if any
 *
 * @param rankId integer The Id for the rank, [0, 54]
 *
 * @returns string the weapon unlocked at that rank, if any, like ak74u
 */
getRankInfoUnlockWeapon(rankId)
{
    log("trace", "msg|in _rank::getRankInfoUnlockWeapon()||");

    return tableLookup("mp/ranktable.csv", 0, rankId, 8);   // 8th 0-based column in rankTable.csv
}


/**
 * @brief Gets the perk unlocked at the rank, if any
 *
 * @param rankId integer The Id for the rank, [0, 54]
 *
 * @returns string the perk unlocked at that rank, if any, like specialty_fastreload
 */
getRankInfoUnlockPerk(rankId)
{
    log("trace", "msg|in _rank::getRankInfoUnlockPerk()||");

    return tableLookup("mp/ranktable.csv", 0, rankId, 9);     // 9th 0-based column in rankTable.csv
}


/**
 * @brief Gets the challenge unlocked at the rank, if any
 *
 * @param rankId integer The Id for the rank, [0, 54]
 *
 * @returns string the challenge unlocked at that rank, if any, like 'ch_marksman_ak74u_1;ch_expert_ak74u_1'
 */
getRankInfoUnlockChallenge(rankId)
{
    log("trace", "msg|in _rank::getRankInfoUnlockChallenge()||");

    return tableLookup("mp/ranktable.csv", 0, rankId, 10);  // 10th 0-based column in rankTable.csv
}


/**
 * @brief Gets the challenge feature unlocked at the rank, if any
 *
 * @param rankId integer The Id for the rank, [0, 54]
 *
 * @returns string the challenge feature unlocked at that rank, if any, like feature_sniper
 */
getRankInfoUnlockFeature(rankId)
{
    log("trace", "msg|in _rank::getRankInfoUnlockFeature()||");

    return tableLookup("mp/ranktable.csv", 0, rankId, 15);  // 15th 0-based column in rankTable.csv
}


/**
 * @brief Gets the weapon camo unlocked at the rank, if any
 *
 * @param rankId integer The Id for the rank, [0, 54]
 *
 * @returns string the weapon camo unlocked at that rank, if any, like 'uzi camo_brockhaurd;uzi camo_bushdweller'
 */
getRankInfoUnlockCamo(rankId)
{
    log("trace", "msg|in _rank::getRankInfoUnlockCamo()||");

    return tableLookup("mp/ranktable.csv", 0, rankId, 11);  // 11th 0-based column in rankTable.csv
}


/**
 * @brief Gets the weapon attachment unlocked at the rank, if any
 *
 * @param rankId integer The Id for the rank, [0, 54]
 *
 * @returns string the weapon attachment unlocked at that rank, if any, like 'm4 gl'
 */
getRankInfoUnlockAttachment(rankId)
{
    log("trace", "msg|in _rank::getRankInfoUnlockAttachment()||");

    return tableLookup("mp/ranktable.csv", 0, rankId, 12);  // 12th 0-based column in rankTable.csv
}


/**
 * @brief Gets the level for the rank, equal to rankId + 1
 *
 * @param rankId integer The Id for the rank, [0, 54]
 *
 * @returns integer the level for that rank
 */
getRankInfoLevel(rankId)
{
    log("trace", "msg|in _rank::getRankInfoLevel()||");

    return int(tableLookup("mp/ranktable.csv", 0, rankId, 13)); // 12th 0-based column in rankTable.csv
}


/**
 * @brief Sets a player's rank & prestige when they connect
 *
 * @returns nothing
 */
onPlayerConnect()
{
    log("trace", "msg|in _rank::onPlayerConnect()||");

    self.pers["rankxp"] = self scripts\players\_persistence::statGet("rankxp");
    rankId = self getRankForXp(self getRankXP());
    self.pers["rank"] = rankId;
    self.pers["participation"] = 0;

    self scripts\players\_persistence::statSet("rank", rankId);
    self scripts\players\_persistence::statSet("minxp", getRankInfoMinXp(rankId));
    self scripts\players\_persistence::statSet("maxxp", getRankInfoMaxXp(rankId));
    self scripts\players\_persistence::statSet("lastxp", self.pers["rankxp"]);

    prestige = self getPrestigeLevel();

    self.rankHacker = false;
    if (prestige > 1) {
        stat = self getstat(253);
        if (rankId > stat ) {
            if (rankId < 20) {
                self setstat(253, rankId);
            } else {
                self.rankHacker = true;
                iprintln(self.name + " was kicked for rank hacking");
                Kick(self getEntityNumber());
            }
        } else {
            if (stat != rankId) {self setstat(253, rankId);}
        }
    }
    self.rankUpdateTotal = 0;

    // for keeping track of rank through stat#251 used by menu script
    // attempt to move logic out of menus as much as possible
    self.cur_rankNum = rankId;
    assertex(isdefined(self.cur_rankNum), "rank: "+ rankId + " does not have an index, check mp/ranktable.csv");
    self setStat(251, self.cur_rankNum);

    if (prestige!=self getstat(210)) {
        self.rankHacker = true;
        iprintln(self.name + " was kicked for prestige hacking");
        log("warn", "msg|" + self.name + " was kicked for prestige hacking||");
        Kick(self getEntityNumber());
    }

    self setRank(rankId, prestige);
    self.pers["prestige"] = prestige;
    self setclientdvar("ui_lobbypopup", "");
    //player updateChallenges();
    //player.explosiveKills[0] = 0;
    self.xpGains = [];

    self thread scripts\players\_classes::getSkillpoints(rankId);

    // Initial upgrade point bonus for prestige level
    if (!self.hasPreviouslyJoined) {
        // Fixed: If prestige is 0, then bonus points is 0. This puts a red '0' on game join
        // in the center of the HUD for every player that hasn't prestiged yet.
        // Don't give a useless bonus.
        if (prestige > 0) {
            scripts\players\_players::incUpgradePoints(int(75 * prestige));
        }
    }
}


/**
 * @brief Initializes a player's spree to zero
 *
 * @returns nothing
 */
onPlayerSpawned()
{
    log("trace", "msg|in _rank::onPlayerSpawned()||");

    self endon("disconnect");
    /// @deprecated
    self.spree = 0;

    /*for(;;)
    {
        self waittill("spawned_player");
        self.spree = 0;
        if(!isdefined(self.hud_rankscroreupdate))
        {
            self.hud_rankscroreupdate = newClientHudElem(self);
            self.hud_rankscroreupdate.horzAlign = "center";
            self.hud_rankscroreupdate.vertAlign = "middle";
            self.hud_rankscroreupdate.alignX = "center";
            self.hud_rankscroreupdate.alignY = "middle";
            self.hud_rankscroreupdate.x = 0;
            self.hud_rankscroreupdate.y = -60;
            self.hud_rankscroreupdate.font = "default";
            self.hud_rankscroreupdate.fontscale = 2.0;
            self.hud_rankscroreupdate.archived = false;
            self.hud_rankscroreupdate.color = (0.5,0.5,0.5);
            self.hud_rankscroreupdate maps\mp\gametypes\_hud::fontPulseInit();
        }
    }*/
}


/**
 * @brief Rounds a float up to the next integer
 *
 * @param val float The float to round up
 *
 * @returns integer the rounded value
 */
roundUp(val)
{
    log("trace", "msg|in _rank::roundUp()||");

    if (int(val) != val) {return int(val+1);}
    else {return int(val);}
}


/**
 * @brief Awards rank XP points
 *
 * @param type string The type of points to award [kill|assistN|spree|revive|...]
 * @param value integer The points to award
 *
 * @returns integer the rounded value
 */
giveRankXP(type, value)
{
    log("trace", "msg|in _rank::giveRankXP()||");

    self endon("disconnect");

    if (self.rankHacker)
    return;

    if (!isDefined(value)) {
        value = getScoreInfoValue(type);
    }
    if (!isDefined(self.xpGains[type])) {
        self.xpGains[type] = 0;
    }

    /*switch( type )
    {
        case "kill":
        case "headshot":
        case "suicide":
        case "teamkill":
        case "assist":
        case "capture":
        case "defend":
        case "return":
        case "pickup":
        case "assault":
        case "plant":
        case "defuse":
            if ( level.numLives >= 1 )
            {
                multiplier = max(1,int( 10/level.numLives ));
                value = int(value * multiplier);
            }
            break;
    }*/

    self.xpGains[type] += value;
    self incRankXP(value);

    if (updateRank()) {
        self thread updateRankAnnounceHUD();
    }

    /*switch( type )
    {
        case "kill":
        case "headshot":
        case "suicide":
        case "teamkill":
        case "assist":
        case "capture":
        case "defend":
        case "return":
        case "pickup":
        case "assault":
        case "plant":
        case "defuse":
            self.pers["summary"]["score"] += value;
            self.pers["summary"]["xp"] += value;
            break;

        case "win":
        case "loss":
        case "tie":
            self.pers["summary"]["match"] += value;
            self.pers["summary"]["xp"] += value;
            break;

        case "challenge":
            self.pers["summary"]["challenge"] += value;
            self.pers["summary"]["xp"] += value;
            break;

        default:
            self.pers["summary"]["misc"] += value;  //keeps track of ungrouped match xp reward
            self.pers["summary"]["match"] += value;
            self.pers["summary"]["xp"] += value;
            break;
    }

    self setClientDvars(
            "player_summary_xp", self.pers["summary"]["xp"],
            "player_summary_score", self.pers["summary"]["score"],
            "player_summary_challenge", self.pers["summary"]["challenge"],
            "player_summary_match", self.pers["summary"]["match"],
            "player_summary_misc", self.pers["summary"]["misc"]
        );*/
}


/**
 * @brief Sets a player's prestige to the given level
 *
 * @param newPrestige integer The player's new prestige level
 *
 * @returns nothing
 */
setPrestige(newPrestige)
{
    log("trace", "msg|in _rank::setPrestige()||");

    if (true) {return;} // for disabling function
    if (newPrestige > level.maxPrestige) {return;}

    self.pers["prestige"] = newPrestige;
    self setStat(2326, self.pers["prestige"]);
    self setStat(210, self.pers["prestige"]);

    self scripts\players\_persistence::statSet( "rankxp", 0 );
    self scripts\players\_persistence::statSet( "rank", 0 );
    self scripts\players\_persistence::statSet( "minxp", int(level.rankTable[0][2]) );
    self scripts\players\_persistence::statSet( "maxxp", int(level.rankTable[0][7]) );
    self setStat( 252, 0 );
    self setStat( 253, 0 );
    self.pers["rankxp"] = 0;
    self setRank(0, self.pers["prestige"]);
    self thread resetRank(.5);
}


/**
 * @brief Increases a player's prestige level
 *
 * Each prestige level is equal to to passing throght all the normal ranks again.
 *
 * @returns nothing
 */
prestigeUp()
{
    log("trace", "msg|in _rank::prestigeUp()||");

    if (self.pers["prestige"] == level.maxPrestige) {return;}
    if (self getRank() < level.maxRank) {return;}

    self.canGetSpecialWeapons = true;

    self.pers["prestige"] += int(self.pers["rankxp"] / (getRankInfoMaxXp(level.maxRank) - 10));
    self setStat(2326, self.pers["prestige"]);
    self setStat(210, self.pers["prestige"]);
    self scripts\players\_persistence::statSet("rankxp", 0);
    self scripts\players\_persistence::statSet("rank", 0);
    self scripts\players\_persistence::statSet("minxp", int(level.rankTable[0][2]));
    self scripts\players\_persistence::statSet("maxxp", int(level.rankTable[0][7]));
    self setStat(252, 0);
    self setStat(253, 0);
    self.pers["rankxp"] = 0;
    self setRank(0, self.pers["prestige"]);
    self thread resetRank(.5);
}


/**
 * @brief Reloads a player's rank after a delay
 *
 * @param delay float How long to wait until reloading the rank
 *
 * @returns nothing
 */
resetRank(delay)
{
    log("trace", "msg|in _rank::resetRank()||");

    self endon("disconnect");
    wait delay;
    rankId = self getRankForXp(self getRankXP());
    self.pers["rank"] = rankId;

    self scripts\players\_classes::getSkillpoints(rankId);
}


/**
 * @brief Updates a player's rank
 *
 * @returns boolean indicating whether their rank was increased or not
 */
updateRank()
{
    log("trace", "msg|in _rank::updateRank()||");

    if (self.rankHacker) {return false;}

    newRankId = self getRank();
    if (newRankId == self.pers["rank"]) {return false;}

    oldRank = self.pers["rank"];
    rankId = self.pers["rank"];
    self.pers["rank"] = newRankId;

    while (rankId <= newRankId) {
        self scripts\players\_persistence::statSet("rank", rankId);
        self scripts\players\_persistence::statSet("minxp", int(level.rankTable[rankId][2]));
        self scripts\players\_persistence::statSet("maxxp", int(level.rankTable[rankId][7]));

        // set current new rank index to stat#252
        self setStat(252, rankId);
        self setStat(253, rankId);

        rankId++;
    }
    self logString("promoted from " + oldRank + " to " + newRankId + " timeplayed: " + self scripts\players\_persistence::statGet("time_played_total"));

    self setRank( newRankId, self.pers["prestige"] );
    self scripts\players\_classes::getSkillpoints(newRankId);
    return true;
}


/**
 * @brief Announces that a player was promoted
 *
 * @returns nothing
 */
updateRankAnnounceHUD()
{
    log("trace", "msg|in _rank::updateRankAnnounceHUD()||");

    self endon("disconnect");
    self notify("update_rank");
    self endon("update_rank");

    team = self.pers["team"];
    if (!isdefined(team)) {
        return;
    }

    newRankName = self getRankInfoFull(self.pers["rank"]);

    rank_char = level.rankTable[self.pers["rank"]][1];
    subRank = int(rank_char[rank_char.size-1]);

    self glowMessage(&"RANK_PROMOTED", "", (0,1,0), 5, 90, 2, "mp_level_up");

    rank_char = level.rankTable[self.pers["rank"]][1];
    subRank = int(rank_char[rank_char.size-1]);

    if (subRank == 1) {
        for (i=0; i<level.players.size; i++) {
            player = level.players[i];
            player iprintln(&"RANK_PLAYER_WAS_PROMOTED", self, newRankName);
        }
    }
}


/** @deprecated
 * @brief NOOP
 *
 * @returns nothing
 */
endGameUpdate()
{
    log("trace", "msg|in _rank::endGameUpdate()||");

    player = self;
}


/**
 * @brief Gets a player's rank
 *
 * @returns integer The rankId for the player
 */
getRank()
{
    log("trace", "msg|in _rank::getRank()||");

    rankXp = self.pers["rankxp"];
    rankId = self.pers["rank"];

    if (rankXp < (getRankInfoMinXP(rankId) + getRankInfoXPAmt(rankId))) {
        return rankId;
    } else {
        return self getRankForXp(rankXp);
    }
}


/**
 * @brief Gets the rankId for the given XP points
 *
 * @param xpVal integer the XP to calculate the rankId for
 *
 * @returns integer The rankId
 */
getRankForXp(xpVal)
{
    log("trace", "msg|in _rank::getRankForXp()||");

    rankId = 0;
    rankName = level.rankTable[rankId][1];
    assert(isDefined(rankName));

    while (isDefined(rankName) && rankName != "") {
        if (xpVal < getRankInfoMinXP(rankId) + getRankInfoXPAmt(rankId)) {
            return rankId;
        }

        rankId++;
        if (isDefined(level.rankTable[rankId])) {
            rankName = level.rankTable[rankId][1];
        } else {
            rankName = undefined;
        }
    }

    rankId--;
    return rankId;
}


/**
 * @brief Returns the player's Score Per Minute (SPM) value based on rank.
 *
 * Unused. Could be used as a score multiplier of to give upgrade points per minute.
 * Higher ranked players get higher SPM.
 *
 * @returns float SPM value in range [3.5, 30.5]
 */
getSPM()
{
    log("trace", "msg|in _rank::getSPM()||");

    // getRank() should return an integer [0, 54]
    rankLevel = (self getRank() % 61) + 1;
    return 3 + (rankLevel * 0.5);
}


/**
 * @brief Gets the player's current prestige level
 *
 * @returns integer the player's current prestige level
 */
getPrestigeLevel()
{
    log("trace", "msg|in _rank::getPrestigeLevel()||");

    return self scripts\players\_persistence::statGet("plevel");
}


/**
 * @brief Gets the player's current rank points
 *
 * @returns integer the player's current rank points
 */
getRankXP()
{
    log("trace", "msg|in _rank::getRankXP()||");

    return self.pers["rankxp"];
}


/**
 * @brief Increases a player's rank points
 *
 * @param amount integer The amount to incease the player's rank XP by
 *
 * @returns nothing
 */
incRankXP(amount)
{
    log("trace", "msg|in _rank::incRankXP()||");

    xp = self getRankXP();
    newXp = (xp + amount);

    if ((self.pers["rank"] == level.maxRank) && (newXp >= getRankInfoMaxXP(level.maxRank))) {
        newXp = getRankInfoMaxXP(level.maxRank);
        if (self.pers["prestige"] != level.maxPrestige) {
            // ready to prestige
            self.canGetSpecialWeapons = false;
        }
    }

    self.pers["rankxp"] = newXp;
    self scripts\players\_persistence::statSet( "rankxp", newXp );
}


/**
 * @brief Increases a player's demerits.
 *        If that pushes player past maxDemerits, player loses 500 rank points,
 *        which may then demote the player.
 *
 * @param amount integer The amount of demerits to apply
 * @param reason string The token reason for the demerits
 *
 * @returns nothing
 */
increaseDemerits(amount, reason)
{
    log("trace", "msg|in _rank::increaseDemerits()||");

    if(!isDefined(self)) {return;}

    message = "";
    if (amount == 1) {message = "^11 Demerit: ";}
    else {message = "^1" + amount + " Demerits: ";}

    switch(reason) {
        case "burning":
            if (amount == 0) {message = "Check Your Fire!";}
            else {message += "Injuring Players by Killing a Burning Zombie";}
            break;
        case "wave_intermission_revive":
            if (amount == 0) {message = "Please revive other players!";}
            else {message += "Not Reviving Enough Players Between Waves";}
            break;
        case "gone_zombie":
            if (amount == 0) {message = "Cure your infection before becoming a zombie!";}
            else {message += "Becoming a Zombie When You Could Have Bought a Cure";}
            break;
    }
    self iPrintLnBold(message);
    log("server", "msg|" + self.name + ": " + message + "||");

    demerits = self.pers["demerits"] + amount;
    if (demerits >= level.maxDemerits) {
        log("server", "msg|Taking 500 rank points from " + self.name + " for being a poor team player.||");
        self decreaseRankPoints(500);
        demerits = 0;
    }
    self.pers["demerits"] = demerits;
    self setStat(2356, self.pers["demerits"]);
}


/**
 * @brief Reduces a players rank XP, possibly demoting the player
 *
 * @param amount integer The amount to reduce the player's rank XP by
 *
 * @returns nothing
 */
decreaseRankPoints(amount)
{
    log("trace", "msg|in _rank::decreaseRankPoints()||");

    if(!isDefined(self)) {return;}

    currentRankXP = self getRankXP();
    currentPrestigeLevel = self getPrestigeLevel();
    previousPrestigeLevel = currentPrestigeLevel - 1;
    currentRankId = self getRank();

    if (currentRankXP > amount) {
        // we can reduce the points without worrying about prestige level
        newRankXp = currentRankXP - amount;
        newRankId = getRankForXp(newRankXp);
        if (currentRankId != newRankId) {
            // player was demoted

            self.pers["rankxp"] = newRankXp;
            self scripts\players\_persistence::statSet("rankxp", newRankXp);

            // set new rank
            self.pers["rank"] = newRankId;
            self scripts\players\_persistence::statSet("rank", newRankId);
            self scripts\players\_persistence::statSet("minxp", int(level.rankTable[newRankId][2]));
            self scripts\players\_persistence::statSet("maxxp", int(level.rankTable[newRankId][7]));

            // set current new rank index to stat#252
            self setStat(252, newRankId);
            self setStat(253, newRankId);

            self setRank(self.pers["rank"], self.pers["prestige"]);

            rankCount = currentRankId - newRankId;
            log("server", "msg|Demoted " + self.name + " " + rankCount + " ranks.||");
            self thread demotionAnnouncement(newRankId);
        } else {
            // just took rank points

            self.pers["rankxp"] = newRankXp;
            self scripts\players\_persistence::statSet("rankxp", newRankXp);

            self iPrintLnBold("^1You Lost " + amount + " Rank Points Due to Demerits");
            log("server", "msg|Took " + amount + " rank points from " + self.name + "||");
        }
    } else if (currentPrestigeLevel == 0) {
        // new player, just take all their points
        newRankXp = 0;
        newRankId = getRankForXp(newRankXp);
        if (currentRankId != newRankId) {
            // player was demoted

            self.pers["rankxp"] = newRankXp;
            self scripts\players\_persistence::statSet("rankxp", newRankXp);

            // set new rank
            self.pers["rank"] = newRankId;
            self scripts\players\_persistence::statSet("rank", newRankId);
            self scripts\players\_persistence::statSet("minxp", int(level.rankTable[newRankId][2]));
            self scripts\players\_persistence::statSet("maxxp", int(level.rankTable[newRankId][7]));

            // set current new rank index to stat#252
            self setStat(252, newRankId);
            self setStat(253, newRankId);

            self setRank(self.pers["rank"], self.pers["prestige"]);

            rankCount = currentRankId - newRankId;
            log("server", "msg|Demoted " + self.name + " " + rankCount + " ranks.||");
            self thread demotionAnnouncement(newRankId);
        } else {
            self.pers["rankxp"] = newRankXp;
            self scripts\players\_persistence::statSet("rankxp", newRankXp);
            self iPrintLnBold("^1You Lost " + currentRankXP + " Rank Points Due to Demerits");
        }

    } else {
        // we can take the points, but we will cross a prestige boundary, & player is demoted
        newRankXp = int(level.rankTable[level.maxRank][7]) + currentRankXP - amount;
        newRankId = getRankForXp(newRankXp);
        newPrestigeLevel = previousPrestigeLevel;

        self.pers["rankxp"] = newRankXp;
        self scripts\players\_persistence::statSet("rankxp", newRankXp);

        // set new rank
        self.pers["rank"] = newRankId;
        self scripts\players\_persistence::statSet("rank", newRankId);
        self scripts\players\_persistence::statSet("minxp", int(level.rankTable[newRankId][2]));
        self scripts\players\_persistence::statSet("maxxp", int(level.rankTable[newRankId][7]));

        // set current new rank index to stat#252
        self setStat(252, newRankId);
        self setStat(253, newRankId);

        // set new prestige level
        self.pers["prestige"] = newPrestigeLevel;
        self setStat(2326, self.pers["prestige"]);
        self setStat(210, self.pers["prestige"]);

        self setRank(self.pers["rank"], self.pers["prestige"]);

        rankCount = level.maxRank - newRankId + currentRankId;
        log("server", "msg|Demoted " + self.name + " " + rankCount + " ranks.||");
        self thread demotionAnnouncement(newRankId);
    }
}


/**
 * @brief Announces that a player was demoted
 *
 * @param newRankId integer [0-54] The Id for the player's new rank
 *
 * @returns nothing
 */
demotionAnnouncement(newRankId)
{
    log("trace", "msg|in _rank::demotionAnnouncement()||");

    if(!isDefined(self)) {return;}

    // rgb 255,0,0 is red
    self glowMessage(&"ZOMBIE_RANK_DEMOTED", "", decimalRgbToColor(255, 0, 0), 5, 90, 2, "mp_level_up");

    // tableLookupIString( <filename>, <column>, <row>, <string_ref_column> )
    newRankName = tableLookupIString( "mp/ranktable.csv", 0, newRankId, 5 );

    // Inform other players that player was demoted
    for (i = 0; i < level.players.size; i++) {
        player = level.players[i];
        player iprintln(&"ZOMBIE_RANK_PLAYER_WAS_DEMOTED", self.name, newRankName);
    }
}
