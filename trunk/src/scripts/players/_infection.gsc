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

#include scripts\include\hud;
#include scripts\include\entities;
#include scripts\include\utility;

init()
{
    log("trace", "msg|in _infection::init()||");

    precache();
    level.becomingZombieDemeritSize = getDvarInt("surv_becoming_a_zombie_demerit_size");
}

precache()
{
    log("trace", "msg|in _infection::precache()||");

    preCacheShellShock("infection");    // infection overlay
    precacheHeadIcon("icon_infection"); // infected headicon
    precachemodel("ch_tombstone3");     // cross headstone
    precacheshader("compass_waypoint_kill");
}

/**
 * @brief Cures a player's infection
 *
 * @returns nothing
 */
cureInfection()
{
    log("trace", "msg|in _infection::cureInfection()||");

    self.infected = false;
    self notify("infection_cured");

    // Remove overlay, infected headicon, and 'use' to cure usable
    if (isdefined(self.infection_overlay)) {self.infection_overlay destroy();}
    self scripts\players\_players::defaultHeadicon();
    level scripts\players\_usables::removeUsable(self);
}

/**
 * @brief Infects a player, leading to damage and becoming a zombie
 *
 * @returns nothing
 */
goInfected()
{
    log("trace", "msg|in _infection::goInfected()||");

    self endon("infection_cured");
    self endon("disconnect");
    self endon("death");

    // Bail if they are already infected
    if (self.infected) {return;}

    // If they aren't down, they can be cured by another player
    if (!self.isDown) {
        level scripts\players\_usables::addUsable(self, "infected", "Press [USE] to cure", 96);
    }

    // Infect the player
    self.headicon = "icon_infection";
    self.infectionTime = getTime();
    self.headiconteam = "allies";
    self.infection_overlay = createHealthOverlay((0,1,0));
    self.infection_overlay.alpha = .5;
    self.infected = true;
    iprintln("^1" + self.name + "^1 got infected!!!");
    self glowMessage(&"ZOMBIE_INFECTED", "", (1, 0, 0), 5, 100, 2);

    // Infection overlay
    wait level.dvar["zom_infectiontime"]; // 15
    if(!isDefined(self)) {return;}
    time = 1 + randomint(int(level.dvar["zom_infectiontime"]*.5));
    // Make sure player has at least 3 seconds before they start taking damage
    // after getting infected
    if (time < 3) {time = 3;}
    if (!isDefined(self) || !isDefined(self.infection_overlay)) {return;}
    self.infection_overlay fadeovertime(time);
    self.infection_overlay.alpha = 1;
    wait time;

    // Begin causing damage and turn player into a zombie
    if (!isDefined(self)) {return;}
    self thread startDamaging();
    self thread waitGoZombie();
}


/**
 * @brief While infected, damages a player until they are down
 *
 * @returns nothing
 */
startDamaging()
{
    log("trace", "msg|in _infection::startDamaging()||");

    self endon("infection_cured");
    self endon("disconnect");
    self endon("death");
    self endon("zombify");

    interval = 3;
    damage = 4;
    while (1)
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
        self shellShock("infection",1);
        if (interval > 1) {
            interval = interval - .1;
        }
        wait interval;
    }
}


/**
 * @brief Turns an infected player into a zombie 5 seconds after they are downed
 *
 * @returns nothing
 */
waitGoZombie()
{
    log("trace", "msg|in _infection::waitGoZombie()||");

    self endon("disconnect");
    self endon("death");
    self endon("revived");
    self endon("infection_cured");

    while (!self.isDown)
    {
        wait .1;
    }
    wait 5;
    self thread playerGoZombie();
}

/**
 * @brief Turns a player into a zombie
 *
 * @returns nothing
 */
playerGoZombie()
{
    log("trace", "msg|in _infection::playerGoZombie()||");

    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    if (self.sessionteam == "spectator") {return;}

    // How long did they have the ability to seek a cure before going down?
    curableTime = self.lastDownTime - self.infectionTime;

    // If the player had enough upgrade points and time to buy a cure, but didn't, give them a demerit
    if ((self.points >= level.dvar["shop_item3_costs"]) &&
        (curableTime >= 9000)) // in ms
    {
        log("debug", "msg|Demeriting " + self.name + " for becoming a zombie. self.points: " + self.points + " curableTime: " + curableTime + "||");
        self thread scripts\players\_rank::increaseDemerits(level.becomingZombieDemeritSize, "gone_zombie");
    } else {
        log("debug", "msg|Not demeriting " + self.name + " for becoming a zombie. self.points: " + self.points + " curableTime: " + curableTime + "||");
    }

    self.tombEnt = spawn( "script_model", self.origin );
    self.tombEnt setmodel( "ch_tombstone3" );
    self.tombEnt.origin = self.origin;
    self.tombEnt.angles = self.angles;
    self.tombEnt.targetname = "tombstone";
    self.tombEnt.player = self;

    //self.isDown = false;
    self.infected = false;
    level scripts\players\_usables::removeUsable(self);
    self.isZombie = true;
    self notify("zombify");
    type = "tank";
    self.type = "tank";
    self playerSetPermanentTweaks(0, 0, ".2 .1 .1", "1 0 0", 0.25, 1.4, 1.2);
    self.headicon = "";
    if (isdefined(self.infection_overlay)) {
        self.infection_overlay destroy();
    }

    self scripts\bots\_types::loadZomStats(type);
    self.maxHealth = int(self.maxHealth * level.dif_zomHPMod);

    self.health = self.maxHealth;

    self.isDoingMelee = false;

    self.alertLevel = 0; // Has this zombie been alerted?
    self.myWaypoint = undefined;
    self.underway = false;
    self.quake = false;

    self takeallweapons();

    self spawn(self.origin, self.angles);

    self detachall();
    self setmodel("body_hellknight");

    self setclientdvar("cg_thirdperson", 1);

    wait 0.05;

    self scripts\bots\_types::loadAnimTree(type);
    self scripts\bots\_types::loadZomModel(type);

    self FreezeControls(true);

    self.mover = spawn("script_origin", self.origin);
    self.mover.origin = self.origin;
    self.mover.angles = self.angles;

    self updateHealthHud(1);

    wait 0.05;

    self thread createKillZombieObjective();
    self linkto(self.mover);
    self scripts\bots\_bot::idle();
    self thread scripts\bots\_bots::zomMain();

    ent = self scripts\bots\_bot::closestTarget();
    if (isdefined(ent)) {
        self scripts\bots\_bots::zomSetTarget(ent.origin);
    }
}


/**
 * @brief Creates an objective to kill a teammate that has become a zombie
 *
 * @returns nothing
 */
createKillZombieObjective()
{
    log("trace", "msg|in _infection::createKillZombieObjective()||");

    self endon("disconnect");
    /// We can't endon "death" because it gets emmitted whan a player-zombie is killed
    //self endon("death");

    self.zombieObjectiveIndex = getNextAvailableObjectiveIndex();
    // Bail if there aren't any available indexes
    if (self.zombieObjectiveIndex == -1) {return;}

    objective_add(self.zombieObjectiveIndex, "active", self.origin, "compass_waypoint_kill");
    objective_team(self.zombieObjectiveIndex, "allies"); //sets the team who can view the icon
    objective_onEntity(self.zombieObjectiveIndex, self); //binds an icon to an entity position

    self thread deleteKillZombieObjective();
}

/**
 * @brief Deletes a kill zombie objective
 *
 * @returns nothing
 */
deleteKillZombieObjective()
{
    log("trace", "msg|in _infection::deleteKillZombieObjective()||");

    self endon("disconnect");
    /// We can't endon "death" because it gets emmitted whan a player-zombie is killed
    //self endon("death");

    /// FIXED: Once you have been a zombie, this loop will run every time a
    /// player-zombie is killed, which causes runtime errors after you have
    /// already been killed, as your self.zombieObjectiveIndex is out of range.
    /// the isZombie flag should fix this.
    isZombie = true; // flag to ensure loop only runs once

    while(isZombie) {
        log("debug", "msg|Waiting for signal no_longer_a_zombie for " + self.name + "||");
        self waittill("no_longer_a_zombie");
        log("signal", "msg|Caught signal no_longer_a_zombie for " + self.name + "||");
        if (self.zombieObjectiveIndex == -1) {return;}

        objective_state(self.zombieObjectiveIndex, "empty"); // "done" is apprently invalid, despite Zeroy's documentation
        objective_delete(self.zombieObjectiveIndex);
        // mark index as available
        level.objectiveIndexAvailability[self.zombieObjectiveIndex] = 1;
        self.zombieObjectiveIndex = -1;
        isZombie = false;
    }
}

/**
 * @brief Gets the next available index in the range of legal indexes
 * The range of legal indexes is [0,15]; this is Activision's limitation, not ours.
 *
 * @returns integer The next available index, or -1 if there is no available index
 */
getNextAvailableObjectiveIndex()
{
    log("trace", "msg|in _infection::getNextAvailableObjectiveIndex()||");

    for (index=0; index<level.objectiveIndexAvailability.size; index++) {
        if (level.objectiveIndexAvailability[index] == 1) {
            level.objectiveIndexAvailability[index] = 0; // mark it as unavailable
            return index;
        }
    }
    return -1;
}

