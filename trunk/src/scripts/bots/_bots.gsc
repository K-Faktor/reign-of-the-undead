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

#include scripts\include\waypoints;
#include scripts\include\entities;
#include scripts\include\physics;
#include scripts\include\hud;

#include scripts\bots\_bot;
#include scripts\include\utility;
#include scripts\include\int_stack;

init()
{
    debugPrint("in _bots::init()", "fn", level.nonVerbose);

    precache();

    // runtime errors on maps with no waypoints.  Test: mp_4nuketown
    // same map has Error: Could not load stringtable "waypoints/mp_4nuketown_wp.csv".

    // runtime errors on maps with no waypoints.  Test: mp_ancient_final_wp
    // same map has Error: Could not load stringtable "waypoints/mp_ancient_final_wp.csv".
    // no such path/file in the *.iwd.  In the *.ff?

        // Error: Could not load stringtable "waypoints/mp_ancient_final_wp.csv".

        // ******* script runtime error *******
        // type undefined is not a float: (file 'scripts/include/waypoints.gsc', line 804)
        //         x = randomFloatRange(level.waypointMinX, level.waypointMaxX);
        //                                 *
        // Error: called from:
        // (file 'scripts/include/waypoints.gsc', line 934)
        //         origin = random3dPoint(useMapExtents);   // if true, generate points within 3D volume covered by waypoints
        //                 *
        // Error: called from:
        // (file 'scripts/include/waypoints.gsc', line 66)
        //     nearestWaypointsTest(100, true);
        //     *
        // Error: called from:
        // (file 'scripts/bots/_bots.gsc', line 51)
        //     scripts\include\waypoints::initializeWaypoints();
        //     *
        // Error: called from:
        // (file 'scripts/server/_server.gsc', line 124)
        //     thread scripts\bots\_bots::init();

    scripts\include\waypoints::initializeWaypoints();

    if (getDvarInt("use_flexible_slots") != 1) {level.useFlexibleSlots = false;}
    else {level.useFlexibleSlots = true;}

    // temp disable flexible slot system until we get it working as well as possible.
    // There are unresolvable issues where we can't reconnect a bot that was kicked
    // unless there has been a full server restart.  This means we can remove bots
    // at will, but we are severely limited in adding them back in.
    level.useFlexibleSlots = false;

    level.bots = [];
    level.availableBots = [];           // stack

    level.botSpawnpointsQueue = [];     // filled circular queue
    level.nextBotSpawnpointPointer = 0; // pointer to the 'next' position in botSpawnpointsQueue
    level.botSpawnpoints = [];          // bot spawnpoints. data in botSpawnpointsQueue is index of spawnpoint in this array

    level.botsAlive = 0;
    level.zomInterval = .2;
    level.zomSpeedScale = .2/level.zomInterval;
    level.zomPreference = 64 * 64;
    level.zombieSightDistance = 2048;
    level.zomIdleBehavior = "";
    level.zomTarget = "player_closest";
    level.loadBots = 1;
    level.botsLoaded = false;
    level.zomTargets = [];
    level.slowBots = 1;
    level.burningZombieDemeritSize = getDvarInt("surv_burning_zombie_demerit_size");

    level.botMeleeRange = 70;
    level.meleeRangeSquared = level.botMeleeRange * level.botMeleeRange;
    level.pursuitRange = 200;
    level.pursuitRangeSquared = level.pursuitRange * level.pursuitRange;

    wait 1;
    if (level.loadBots) {
        // this is a server restart, so create bots
        noticePrint("Calling to load " + level.dvar["bot_count"] + " bots.");
        instantiateBots(level.dvar["bot_count"]);
    } else {
        // this is a map restart, so existing bots will reconnect
        if (level.useFlexibleSlots) {resetFlexibleSlots();}
    }

    scripts\bots\_types::initZomTypes();
    scripts\bots\_types::initZomModels();

    level.botsLoaded = true;
    thread monitorBotSlots();
    initMovementCache();
    computeMotions();
    printMovementCacheDistribution();
}


precache()
{
    debugPrint("in _bots::precache()", "fn", level.nonVerbose);

    // precache the weapons used for animations
    precacheItem("bot_zombie_walk_mp");
    precacheItem("bot_zombie_stand_mp");
    precacheItem("bot_zombie_run_mp");
    precacheItem("bot_zombie_melee_mp");
    precacheItem("bot_dog_idle_mp");
    precacheItem("bot_dog_run_mp");
    precacheItem("defaultweapon_mp");

    // precache the xmodels we use for zombies
    precacheModel("tag_origin");
    precacheModel("izmb_zombie1_body");
    precacheModel("izmb_zombie2_body");
    precacheModel("izmb_zombie2_head");
    precacheModel("izmb_zombie3");
    precacheModel("body_complete_sp_zakhaevs_son");
    precacheModel("bo_quad");
    precacheModel("cyclops");
    precacheModel("body_complete_sp_vip");
    precacheModel("body_complete_sp_russian_farmer");
    precacheModel("german_sheperd_dog");
    precacheModel("body_hellknight");
    precacheModel("cyclops");

    // precache the shellshocks we use
    precacheShellShock("boss");
    precacheShellShock("toxic_gas_mp");

    // load the fx we use for zombies into memory
    level.explodeFX     = loadFx("explosions/pyromaniac");
    level.burningFX     = loadFx("fire/firelp_med_pm");
    level.burningDogFX  = loadFx("fire/firelp_small_pm_rotu");
    level.toxicFX       = loadFx("misc/toxic_gas");
    level.soulFX        = loadFx("misc/soul");
    level.goundSpawnFX  = loadFx("misc/ground_rising");
    level.soulspawnFX   = loadFx("misc/soulspawn");
}

/**
 * @brief Instantiates the requested number of bots
 *
 * @param botCount integer The number of bots to create
 *
 * @returns nothing
 */
instantiateBots(botCount)
{
    debugPrint("in _bots::instantiateBots()", "fn", level.nonVerbose);

    failedCount = 0;    // The number of bots we ultimately failed to create
    attemptCount = 0;
    attemptLimit = 3;   // The maximum number of times to try to create a single bot

    for (i=0; i<botCount; i++) {
        if (!instantiate()) {
            attemptCount++;
            if (attemptCount <= attemptLimit) {
                i--;
                continue;
            } else {
                failedCount++;
                attemptCount = 0;
            }
        } else {attemptCount = 0;}
        if (i % 10 == 0) {wait 0.05;} // breathing room
    }

    if (failedCount != 0) {
        errorPrint("Failed to load " + failedCount + " of " + botCount + " bots.");
    }

    level notify("bots_loaded");
}

/**
 * @brief Finds available bots, then deletes them to free up slots for human players
 *
 * @param botCount integer The number of bots to delete
 *
 * @returns nothing
 */
deleteBots(botCount)
{
    debugPrint("in _bots::deleteBots()", "fn", level.fullVerbosity);

    botsToRemove = [];

    // pop the bots we want to remove off the available stack
    while (botsToRemove.size - 1 < botCount) {
        bot = undefined;
        while (!isDefined(bot)) {
            wait 0.1;
            bot = availableBot();
            noticePrint("trying to pop a bot off the stack so we can delete it.");
        }
        botsToRemove[botsToRemove.size] = bot.index;
    }

    remove(botsToRemove);
}

/**
 * @brief Add/Removes bot slots to optimize use of server slots
 *
 * @returns nothing
 */
monitorBotSlots()
{
    debugPrint("in _bots::monitorBotSlots()", "fn", level.fullVerbosity);

    level endon("game_ended");

    if (!level.useFlexibleSlots) {return;}

    totalSlots = getDvarInt("ui_maxclients");
    maxBots = getDvarInt("max_bots");                           // never have more bots than this
    maxPlayers = getDvarInt("max_players");                     // never have more than this many slots for players
    minOpenPlayerSlots = getDvarInt("min_open_player_slots");   // try to keep this many open slots for players
    tolerance = getDvarInt("slot_tolerance");                   // Do nothing if botDelta is +/- tolerance

    while (1) {
        level waittill("wave_finished");
        wait 3;

        playersCount = level.players.size;
        botCount = level.bots.size;

        playersGoal = (playersCount + minOpenPlayerSlots);
        // never more player slots than spec'd
        if (playersGoal > maxPlayers) {playersGoal = maxPlayers;}

        botCountGoal = totalSlots - playersGoal;
        // never more bots than spec'd
        if (botCountGoal > maxBots) {botCountGoal = maxBots;}

        botDelta = botCountGoal - botCount;

        if (botDelta >= tolerance) {
            // add bots
            noticePrint("Flexible Slot System: Adding " + botDelta + " bots.");
            instantiateBots(botDelta);
        } else if (botDelta <= (-1 * tolerance)) {
            // remove bots
            noticePrint("Flexible Slot System: Removing " + (-1 * botDelta) + " bots.");
            deleteBots(botDelta);
        }
    }
}
/**
 * @brief Resets bot count to bot_count dvar when a map is reloaded without a server restart
 *
 * @returns nothing
 */
resetFlexibleSlots()
{
    debugPrint("in _bots::resetFlexibleSlots()", "fn", level.fullVerbosity);

    botCount = getDvarInt("bot_count");

    botDelta = botCount - level.bots.size;
    if (botDelta < 0) {
        // remove bots
        noticePrint("Flexible Slot System: Removing " + (botDelta * -1) + " bots.");
        deleteBots(botDelta * -1);
    } else if (botDelta > 0) {
        // add bots
        noticePrint("Flexible Slot System: Adding " + botDelta + " bots.");
        instantiateBots(botDelta);
    }
}

/**
 * @brief Finds a bot that is available for spawning
 *
 * @returns struct The bot, or undefined if no bot is available for spawning
 */
availableBot()
{
    debugPrint("in _bots::availableBot()", "fn", level.fullVerbosity);

    // noticePrint("level.availableBots.size: " + level.availableBots.size);
    if (level.availableBots.size == 0) {
        if (false) {
            // for debugging.  this usually only happens when we all of our bot slots are
            // already zombies, but the game would make more zombies if we had more slots
            spawnedBots = 0;
            for (i=0; i<level.bots.size; i++) {
                if (level.bots[i].hasSpawned) {spawnedBots++;}
            }
            warnPrint("No available bots! Already " + spawnedBots + " alive.");
        }
        return undefined;
    } else {
        // pop a bot off the stack and return it
        bot = level.bots[level.availableBots[level.availableBots.size - 1]];
        level.availableBots[level.availableBots.size - 1] = undefined;
        bot.hasSpawned = true;
        return bot;
    }
}

/**
 * @brief Spawns a zombie into the game
 *
 * @param zombieType string The type of zombie to spawn
 * @param spawnpoint struct A struct containing the position and angles for spawning the zombie
 * @param bot struct The bot to use for this zombie
 *
 * @returns bot The spawned zombie
 */
spawnZombie(zombieType, spawnpoint, bot)
{
    debugPrint("in _bots::spawnZombie()", "fn", level.fullVerbosity);

    if (!isDefined(bot)) {
//         noticePrint("asking for a bot so we can spawn a zombie");
        bot = availableBot();
        if (!isDefined(bot)) {return undefined;}
    }

    bot.readyToBeKilled = false;
    bot.hasSpawned = true;
    bot.currentTarget = undefined;
    bot.targetPosition = undefined;
    bot.type = zombieType;
    // bot.pathNodes = [];
    bot.pathStack = scripts\include\int_stack::new();
    bot.myWaypoint = undefined;
    bot.smoothedPath = undefined;
    bot.goalWp = undefined;
    bot.nextWp = undefined;
    if (level.zombieAiDevelopment) {
        bot.movement.first = 0;
        bot.movement.last = 0;
    }

    bot.team = bot.pers["team"];
    bot.sessionteam = bot.team;
    bot.sessionstate = "playing";
    bot.spectatorclient = -1;
    bot.killcamentity = -1;
    bot.archivetime = 0;
    bot.psoffsettime = 0;
    bot.statusicon = "";

    bot scripts\bots\_types::loadZomStats(bot.type);

    bot.maxHealth = int(bot.maxHealth * level.dif_zomHPMod);
    bot.health = bot.maxHealth;
    bot.isDoingMelee = false;
    bot.damagedBy = [];

    bot.alertLevel = 0; // Has this zombie been alerted?
    bot.myWaypoint = undefined;
    bot.underway = false;
    bot.canTeleport = true;
    bot.quake = false;

    bot scripts\bots\_types::loadAnimTree(bot.type);

    bot.animWeapon = bot.animation["stand"];
    bot TakeAllWeapons();
    bot.pers["weapon"] = bot.animWeapon;
    bot giveweapon(bot.pers["weapon"]);
    bot givemaxammo(bot.pers["weapon"]);
    bot setspawnweapon(bot.pers["weapon"]);
    bot switchtoweapon(bot.pers["weapon"]);

    // Generate random angle between -180 and 180
    randomAngle = randomIntRange(-180, 181);   // 181 because range is exclusive on the upper bound
    if (isDefined(spawnpoint.angles)) {
        // randomize existing spawnpoint angles
        angle = spawnpoint.angles + (0, randomAngle, 0);        
        bot spawn(spawnpoint.origin, angle);
        // bot spawn(spawnpoint.origin, spawnpoint.angles); // 2.2.2
    } else {
        // randomize spawnpoint angle
        bot spawn(spawnpoint.origin, (0, randomAngle, 0));
        // bot spawn(spawnpoint.origin, (0,0,0)); // 2.2.2
    }

    level.botsAlive++;
    wait 0.05;

    bot scripts\bots\_types::loadZomModel(bot.type);
    bot freezeControls(true);

    bot.mover.origin = bot.origin;
    bot.mover.angles = bot.angles;

    bot.incdammod = 1;
    if ((bot.type != "tank" && bot.type != "boss") ||
        (level.dvar["zom_spawnprot_tank"]))
    {
        if (level.dvar["zom_spawnprot"]) {
            bot.incdammod = 0;
            bot thread endZombieSpawnProtection(level.dvar["zom_spawnprot_time"], level.dvar["zom_spawnprot_decrease"]);
        }
    }

    wait 0.05;
    bot scripts\bots\_types::onSpawn(bot.type);
    bot linkto(bot.mover);
    bot thread fixStuck();
    bot idle(bot);
    if (level.zombieAiDevelopment) {
        bot.runSpeed = bot.runSpeed * 5;    // scale to seconds
        bot.walkSpeed = bot.walkSpeed * 5;  // scale to seconds
        // bot thread main();
        // bot thread botMain();
        bot thread scripts\bots\_bot::botMain(bot);
    } else {
        bot thread zomMain();
    }
    bot thread groan(bot);
    bot.readyToBeKilled = true;

    return bot;
}

/**
 * @brief Ends zombie spawn invincibility after a time, or over time
 *
 * @param time integer The time in seconds
 * @param decrease boolean Decrease gradually over time?
 *
 * @returns nothing
 */
endZombieSpawnProtection(time, decrease)
{
    debugPrint("in _bots::endZombieSpawnProtection()", "fn", level.highVerbosity);

    self endon("death");

    if (decrease) {
        for (i=0; i<10; i++) {
            wait time/10;
            self.incdammod += .1;
        }
    } else {
        wait time;
        self.incdammod = 1;
    }
}

// BOTS MAIN

Callback_BotDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
    debugPrint("in _bots::Callback_BotDamage()", "fn", level.fullVerbosity);

    if(!self scripts\bots\_types::onDamage(self.type, sMeansOfDeath, sWeapon, iDamage, eAttacker))
    {
        return;
    }
    self.alertLevel += 200;

    if ((isdefined(eAttacker)) && (isplayer(eAttacker))) {
        if (eAttacker.curClass=="armored") {
            if (sMeansOfDeath=="MOD_MELEE") {
                if (iDamage>self.health) {
                    eAttacker scripts\players\_abilities::rechargeSpecial(self.health/25);
                } else {
                    eAttacker scripts\players\_abilities::rechargeSpecial(iDamage/25);
                }
            }
        }
        if (eAttacker.curClass=="scout" && sHitLoc=="head" && sMeansOfDeath != "MOD_MELEE") {
            eAttacker scripts\players\_abilities::rechargeSpecial(iDamage/40);
        }
        // Medic's Transfusion primary ability
        if ((eAttacker.curClass == "medic") && (eAttacker.transfusion) && (distance(eAttacker.origin, self.origin) < 48)) {
            health = int(0.15 * iDamage);
            eAttacker.health += health;
            if (eAttacker.health > eAttacker.maxHealth) {eAttacker.health = eAttacker.maxHealth;}
            eAttacker updateHealthHud(eAttacker.health/eAttacker.maxHealth);
        }

        if(!isDefined(self.incdammod)) {
            debugPrint("BUG: self.incdammod not set; setting to 1 for : " + self.name, "val");
            self.incdammod = 1;
        }
        iDamage = int(iDamage * eAttacker scripts\players\_abilities::getDamageModifier(sWeapon, sMeansOfDeath, self, iDamage) * self.incdammod);

//         eAttacker notify("damaged_bot", self);
        eAttacker notify("damaged_bot", self, sMeansOfDeath);

        eAttacker scripts\players\_damagefeedback::updateDamageFeedback(0);
        if (self.isBot) {self thread addToAssist(eAttacker, iDamage);}
    }

    if (self.sessionteam == "spectator") {return;}

    if (!isDefined(vDir)) {iDFlags |= level.iDFLAGS_NO_KNOCKBACK;}

    if(!(iDFlags & level.iDFLAGS_NO_PROTECTION)) {
        if(iDamage < 1) {iDamage = 1;}

//         // for debugging many_bosses damage bugs
//         if ((isDefined(level.waveType)) && (level.waveType == "many_bosses")) {
//             if (isDefined(eAttacker.name)) {attackerName = eAttacker.name;}
//             else {attackerName = "N/A";}
//             noticePrint("finishPlayerDamage(," + attackerName + "," + iDamage + ",N/A," + sMeansOfDeath + "," + sWeapon + ",,,,)");
//         }
        self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
    }
}

/**
 * @brief Keeps track of damage done to zombie so we can give assist credit when zombie is finally killed
 *
 * @param player entity The player doing the damage
 * @param damage integer The amount of damage this player just did to this zombie
 *
 * @returns nothing
 */
addToAssist(player, damage)
{
    debugPrint("in _bots::addToAssist()", "fn", level.fullVerbosity);

    for (i=0; i<self.damagedBy.size; i++) {
        if (self.damagedBy[i].player == player) {
            self.damagedBy[i].damage += damage;
            return;
        }
    }
    struct = spawnstruct();
    self.damagedBy[self.damagedBy.size] = struct;
    struct.player = player;
    struct.damage = damage;
}


// // Returns the human-readable name of the BOT state as a string
// botStateToString(state) {
//     switch(state)
//     {
//         case 0:         return "IDLE"; // Idle
//         case 1:    return "SEARCHING"; // Wandering, no target, low alert
//         case 2:     return "STALKING"; // Trying to get/keep target in sight, medium alert
//         case 3:     return "PURSUING"; // Target in sight, high alert
//         case 4:        return "MELEE"; // In melee range and attacking
//         case 5:      return "STUNNED"; // Hit by thundergun / stunned
//         case 6:    return "REACQUIRE_TARGET"; // Lost sight, going to last known position
//         case 7:         return "DEAD"; // Dead
//         case 8:   return "VICTORIOUS"; // Successfully killed target, standing over it
//         case 9:      return "RECYCLE"; // ready to recycle
//         default:                     return "UNKNOWN_STATE_" + state;
//     }
// }

// botMain()
// {
//     // no function entrance debugging, main loop
//     self endon("disconnect");
//     self endon("death");
//     level endon("game_ended");

//     wait 1.2; // wait until bot is standing up before he starts to move
//     count = 0;
//     self.previousStatus = 9; // initialize previousStatus so we can detect status changes in the loop and print them for debugging
//     while (1) {
//         count++;
//         if (count > 100) {
//             noticePrint("Bot " + self.index + " bailing on main loop.");
//             break;
//         }
//         switch (self.status) {
//             case 9: // BOT_STATE_IDLE
//                 // set state searching
//                 self.status = 0; // BOT_STATE_SEARCHING
//                 self.previousStatus = 9;
//                 self.alertLevel = 100;
//                 setSpeed();
//                 noticePrint("Bot " + self.index + " Idle --> Searching");
//                 iPrintLnBold("Bot " + self.index + " Idle --> Searching");
//                 break;
//             case 0: // BOT_STATE_SEARCHING
//                 bestTarget();  // sets self.bestTarget & self.closestTarget
//                 if (!isDefined(self.bestTarget)) {
//                     // wander towards self.closestTarget, but keep searching
//                     iPrintLnBold("Searching towards " + self.closestTarget.name);
//                 } else {
//                     self.targetedPlayer = self.bestTarget;  // temp hack, think we have 2 variables for the same things indifferent parts of the code
//                     setTargetedPlayer(self.bestTarget);
//                     self.status = 1; // BOT_STATE_STALKING;
//                     noticePrint("Bot " + self.index + " Searching --> Stalking " + self.bestTarget.name);
//                     iPrintLnBold("Bot " + self.index + " Searching --> Stalking " + self.bestTarget.name);
//                     // iPrintLnBold("Targeting: " + self.bestTarget.name);
//                 }
//                 doWander();
//                 // findNewTarget()
//                 // if not found, break;  keep searching wandering randomly
//                 // if found, set state stalking
//                 break;
//             case 1: // BOT_STATE_STALKING
//                 noticePrint("Bot " + self.index + " Stalking " + self.bestTarget.name);
//                 // canWeSeeTarget() if no, set state reacquire target; break;
//                 // checkForBetterTarget() // every Nth iteration
//                 // if not found, break;  keep stalking current target
//                 // if found, stalk new target
//                 break;
//             case 2: // BOT_STATE_PURSUING
//                 // canWeSeeTarget() if no, set state reacquire target; break;
//                 // checkForBetterTarget() // every Nth iteration
//                 // if not found, break;  keep pursuing current target
//                 // if found, pursue new target
//                 break;
//             case 5: // BOT_STATE_REACQUIRE
//                 // move to last known target position
//                 // if at last known position, look for target
//                 // canWeSeeTarget() if no, canWeSeeAnyTarget()? if no, set state searching.
//                 // if yes, set state to stalking | pursuing depending on distance to target
//                 break;
//             case 4: // BOT_STATE_STUNNED
//                 // wait until stun duration is over, then set state searching
//                 break;
//             case 3: // BOT_STATE_MELEE
//                 break;
//             case 6: // BOT_STATE_DEAD
//                 // do nothing, wait for respawn.  might have to wait for body to decompose
//                 break;
//             case 7: // BOT_STATE_VICTORIOUS
//                 // play groan; then set state idle
//                 break;
//             case 8: // BOT_STATE_RECYCLE
//                 // likely reinit and respawn
//                 break;
//                 default:
//                 self.status = 9; // BOT_STATE_IDLE 
                
//         }

//         wait level.zomInterval;  // set to 0.2 seconds, or 4 frames.
//         // wait: seconds, where the server runs 20 frames per second.  Therefore,
//         // `wait 1` pauses execution for 1 second (20 frames),
//         // `wait 0.05` pauses for 1 frame
//     }
// }



zomMain()
{
    debugPrint("in _bots::zomMain()", "fn", level.veryHighVerbosity);

    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    self.lastTargetWp = -2;
    self.nextWp = -2;
    //self.intervalScale = 1;
    update = 0;

    while (1) {
        switch (self.status) {
            case "idle":
                // loops through player array once, it calls zomGoTriggered if it
                // can see the player. If it can't see any players, it does nothing
                zomWaitToBeTriggered();
                switch(level.zomIdleBehavior) {
                    case "magic":
                        if (update==5) {
                            if (level.zomTarget != "") {
                                if (level.zomTarget == "player_closest") {
                                    ent = self closestTarget();
                                    if (isDefined(ent)) {
                                        self zomSetTarget(ent.origin);
                                    }
                                } else {
                                    self zomSetTarget(getRandomEntity(level.zomTarget).origin);
                                }
                            } else {
                                ent = self closestTarget();
                                if (isdefined(ent)) {self zomSetTarget(ent.origin);}
                            }
                            update = 0;
                        } else {
                            update++;
                        }
                        break;
                } // end switch(level.zomIdleBehavior)
                break;
            case "triggered":
                if ((isDefined(self.bestTarget)) && ((update==10) || (self.bestTarget.isDown))) {  // find new target when current target goes down
                    self.bestTarget = zomGetBestTarget();
                    update = 0;
                } else {update++;}
                if (isdefined(self.bestTarget)) {
                    self.lastMemorizedPos = self.bestTarget.origin;
                    if (!checkForBarricade(self.bestTarget.origin)) {
                        if (distance(self.bestTarget.origin, self.origin) < self.meleeRange) {
                            self thread zomMoveLockon(self.bestTarget, self.meleeTime, self.meleeSpeed);
                            self melee();
                            //doWait = false;
                        } else {
                            zomMovement();
                            self zomMoveTowards(self.bestTarget.origin);
                            //doWait = false;
                        }
                    } else {
                        self melee();
                    }
                } else {
                    self search();
                }
                break;
            case "searching":
                zomWaitToBeTriggered();
                if (isdefined(self.lastMemorizedPos)) {
                    if (!checkForBarricade(self.lastMemorizedPos)) {
                        if (distance(self.lastMemorizedPos, self.origin) > 48) {
                            zomMovement();
                            self zomMoveTowards(self.lastMemorizedPos);
                            //doWait = false;
                        } else {
                            self.lastMemorizedPos = undefined;
                        }
                    } else {
                        self melee();
                    }
                }
                else {idle();}
                break;
            case "stunned":
                wait 1.25;
                idle();
            break;
        }

        //if (doWait)
        wait level.zomInterval;
    }
}

zomGetBestTarget()
{
    debugPrint("in _bots::zomGetBestTarget()", "fn", level.fullVerbosity);

    if (!isDefined(self.currentTarget)) {
        for (i=0; i<level.players.size; i++) {
            player = level.players[i];
            if (canSeeTarget(player)) {
                self.currentTarget = player;
                return player;
            }
            wait 0.05;
        }
        // if zombie can't see any players, just grab the closest player
        ent = self closestTarget();
        if (isDefined(ent)) {
            self zomSetTarget(ent.origin);
            return ent;
        }
    } else {
        if (!canSeeTarget(self.currentTarget)) {
            self.currentTarget = undefined;
            return undefined;
        }

        targetdis = distancesquared(self.origin, self.currentTarget.origin) - level.zomPreference;
        for (i=0; i<level.players.size; i++) {
            player = level.players[i];
            if (!isDefined(player)) {continue;}
            if (distancesquared(self.origin, player.origin) < targetdis) {
                if (canSeeTarget(player)) {
                    self.currentTarget = player;
                    return player;
                }
            }
        }
        return self.currentTarget;
    }
}

zomMovement()
{
    // 12th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    self.cur_speed = 0;

    if ((self.alertLevel >= 200 && (!self.walkOnly || self.quake)) || self.sprintOnly ) {
        self run();

        if (level.dvar["zom_dominoeffect"]) {
            thread alertZombies(self.origin, 480, 5, self);
        }
    } else {self walk();}
}

zomGoTriggered()
{
    debugPrint("in _bots::zomGoTriggered()", "fn", level.absurdVerbosity);

    self.status = "triggered";
    //self.update = 10;
    self.bestTarget = zomGetBestTarget();
    //iprintlnbold("TRIGGERED!");
}

zomWaitToBeTriggered()
{
    // 17th most-called function (1% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    debugPrint("Zombie at " + self.origin + " checking for players", "val");
    for (i=0; i<level.players.size; i++) {
        player = level.players[i];
        debugPrint("Checking player " + player.name + " at " + player.origin + ", distance: " + distance(self.origin, player.origin), "val");
        if (self canSeeTarget(player)) {
            debugPrint("Zombie can see player " + player.name + ", triggering!", "val");
            self zomGoTriggered();
            break;
        } else {
            debugPrint("Zombie cannot see player " + player.name, "val");
        }
    }
}

/**
 * @brief Gets the position of the top of the player based on their stance
 *
 * @returns tuple The origin of the top of the player
 */
getPlayerHeight()
{
    // 16th most-called function (1% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    switch (self getStance()) {
    case "stand":
        return self.origin + (0,0,68);
    case "crouch":
        return self.origin + (0,0,40);
    case "prone":
        return self.origin + (0,0,22);
    }
}

zomMoveTowards(target_position)
{
    // 13th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    self endon("disconnect");
    self endon("death");
    self endon("dying");

    if (level.waypointsInvalid) {
        // this map either has no waypoints, or they are bad so we aren't using them
        moveToPoint(target_position, self.cur_speed);
    } else {
        if (!isDefined(self.lastAStarTargetWp)) {self.lastAStarTargetWp = -1;}
        if (!isDefined(self.lastAStarWp)) {self.lastAStarWp = -1;}

        if (!isDefined(self.myWaypoint)) {
//             self.myWaypoint = nearestWaypoint(self.origin, true, self);
            self.myWaypoint = nearestWaypoints(self.origin, 1)[0];
        }

//         targetWp = nearestWaypoint(target_position, true, self.bestTarget);
        targetWp = nearestWaypoints(target_position, 1)[0];

        self.myWaypoint = validateWaypoint(self.myWaypoint, "myWaypoint");
        targetWp = validateWaypoint(targetWp, "targetWp");

        // both are vaild
        if ((self.myWaypoint) && (targetWp)) {
            debugPrint("myWaypoint: " + self.myWaypoint + " targetWp: " + targetWp, "val");
        }

        if (targetWp == self.myWaypoint) {
            // we are already at the closest waypoint, just move to target
            moveToPoint(target_position, self.cur_speed);
            self.underway = false;
            self.myWaypoint = undefined;
        } else {
            if ((self.previousAStarCallTargetWp != targetWp) ||     // our target wp has changed since our last A* call
//                 (self.myWaypoint != self.lastAStarWp) ||    // our current wp is not the waypoint we were supposed to go to
                (self.pathStack isEmpty()))                 // we are out of path nodes
            {
                // invalidate the pathStack and get a fresh stack from A*
                if (self.previousAStarCallTargetWp != targetWp) {noticePrint(self.name + ": self.lastAStarTargetWp != targetWp");}
                if (self.myWaypoint != self.lastAStarWp) {noticePrint(self.name + ": self.myWaypoint != self.lastAStarWp");}
                if (self.pathStack isEmpty()) {noticePrint(self.name + ": self.pathStack is empty");}
                noticePrint("A* call (bot, myWaypoint, targetWp): (" + self.name + ", " + self.myWaypoint + ", " + targetWp + ")");
                self.pathStack pushMany(AStarNew(self.myWaypoint, self.targetWp));
                self.previousAStarCallTargetWp = targetWp;
            } else {
                level.savedAStarCalls++;
            }
            // pop the next wp to head towards off the stack
            nextWp = self.pathStack pop();
            self.previousAStarCallTargetWp = nextWp;

            self.nextWp = nextWp;
            self.underway = true;

            if ((targetWp == nextWp) &&
                (distanceSquared(target_position, self.origin) <= distanceSquared(level.Wp[nextWp].origin, self.origin)))
            {
                // we are close enough to target_position to go directly there, ignoring waypoints
                moveToPoint(target_position, self.cur_speed);
                self.isFollowingWaypoints = false;
                self.underway = false;
                self.myWaypoint = undefined;
            } else {
                moveToPoint(level.Wp[nextWp].origin, self.cur_speed);
                self.isFollowingWaypoints = true;
                if (distance(level.Wp[nextWp].origin, self.origin) <  64) {
                    self.underway = false;
                    self.myWaypoint = nextWp;
                }
            }
        }
    }
}

zomMoveLockon(player, time, speed)
{
    debugPrint("in _bots::zomMoveLockon()", "fn", level.veryHighVerbosity);

    intervals = int(time / level.zomInterval);
    for (i=0; i<intervals; i++) {
        if (!isDefined(player)) {continue;}
        if (!isDefined(self)) {continue;}
        dis = distance(self.origin, player.origin);
        if (dis > 48) {
            pushOutDir = VectorNormalize((self.origin[0], self.origin[1], 0)-(player.origin[0], player.origin[1], 0));
            self moveToPoint(player.origin + pushOutDir * 32, speed);
            self pushOutOfPlayers();
        }
        targetDirection = vectorToAngles(VectorNormalize(player.origin - self.origin));
        self SetPlayerAngles(targetDirection);
        wait level.zomInterval;
    }
}

pushOutOfPlayers() // ON SELF
{
    debugPrint("in _bots::pushOutOfPlayers()", "fn", level.absurdVerbosity);

    //push out of other players
    //players = level.players;
    players = getentarray("player", "classname");
    for (i=0; i<players.size; i++) {
        player = players[i];
        if (player == self || !isalive(player)) {continue;}
        self thread pushout(player.origin);
    }
    for (i=0; i <level.dynamic_barricades.size; i++) {
        if (isdefined(level.dynamic_barricades[i])) {
            if (level.dynamic_barricades[i].hp > 0) {
                self thread pushout(level.dynamic_barricades[i].origin);
            }
        }
    }
}

pushout(org)
{
    // 18th most-called function (1% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    linkObj = self.mover;
    distance = distance(org, linkObj.origin);
    minDistance = 28;
    if (distance < minDistance) {
        pushOutDir = VectorNormalize((linkObj.origin[0], linkObj.origin[1], 0)-(org[0], org[1], 0));
        pushoutPos = linkObj.origin + (pushOutDir * (minDistance-distance));
        linkObj.origin = (pushoutPos[0], pushoutPos[1], self.origin[2]);
    }
}

zomAreaDamage(range)
{
    debugPrint("in _bots::zomAreaDamage()", "fn", level.lowVerbosity);

    for (i=0; i<=level.players.size; i++) {
        target = level.players[i];
        if (isdefined(target) && isalive(target)) {
            distance = distance(self.origin, target.origin);
            if (distance < range ){
                target.isPlayer = true;
                //target.damageCenter = self.Mover.origin;
                target.entity = target;
                target damageEnt(
                    self, // eInflictor = the entity that causes the damage (e.g. a claymore)
                    self, // eAttacker = the player that is attacking
                    int(self.damage*level.dif_zomDamMod), // iDamage = the amount of damage to do
                    "MOD_EXPLOSIVE", // sMeansOfDeath = string specifying the method of death (e.g. "MOD_PROJECTILE_SPLASH")
                    self.pers["weapon"], // sWeapon = string specifying the weapon used (e.g. "claymore_mp")
                    self.origin, // damagepos = the position damage is coming from
                    //(0,self GetPlayerAngles()[1],0) // damagedir = the direction damage is moving in
                    vectorNormalize(target.origin-self.origin)
                );
            }
        }
    }
}

zomSetTarget(target)
{
    debugPrint("in _bots::zomSetTarget()", "fn", level.highVerbosity);

    //wait .5;
    //self.targetPosition = getentarray(target, "targetname")[0].origin;
    //self.alertLevel = 1;
    self search();
    self.lastMemorizedPos = target;
}

checkForBarricade(targetposition)
{
    // 11th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!
    debugPrint("in _bots::checkForBarricade()", "fn", level.lowVerbosity);

    for (i=0; i<level.barricades.size; i++) {
        ent = level.barricades[i];
        if (self isTouching(ent) && ent.hp > 0) {
            fwdDir = vectorNormalize(targetposition-self.origin);
            dirToTarget = vectorNormalize(ent.origin-self.origin);
            dot = vectorDot(fwdDir, dirToTarget);
            if (dot > 0 && dot < 1) {return 1;}
        }
    }
    for (i=0; i<level.dynamic_barricades.size; i++) {
        ent = level.dynamic_barricades[i];
        if ((distance(self.origin, ent.origin) < 48) && (ent.hp > 0)) {
            fwdDir = vectorNormalize(targetposition-self.origin);
            dirToTarget = vectorNormalize(ent.origin-self.origin);
            dot = vectorDot(fwdDir, dirToTarget);
            if (dot > 0 && dot < 1) {return 1;}
        }
    }
    return 0;
}

alertZombies(origin, distance, alertPower, ignoreEnt)
{
    // 14th most-called function (1.5% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    for (i=0; i < level.bots.size; i++) {
        if (isDefined(ignoreEnt)) {
            if (level.bots[i] == ignoreEnt) {continue;}
        }
        dist = distance(origin, level.bots[i].origin);
        if (dist < distance) {
            zombie = level.bots[i];
            if (isalive(zombie) && isdefined(zombie.status)) {
                zombie.alertLevel += alertPower;
                if (zombie.status == "idle") {zombie search();}
            }
        }
    }
}
