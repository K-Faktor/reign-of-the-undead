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

#include scripts\include\int_stack;
#include scripts\include\matrix;
#include scripts\include\waypoints;
#include scripts\include\utility;
#include scripts\include\physics;

/**
 * @brief Creates a bot
 *
 * @returns boolean Whether the bot was instantiated
 */
instantiate()
{
    debugPrint("in _bot::instantiate()", "fn", level.nonVerbose);

    bot = addTestClient();

    if (!isDefined(bot)) {
        warnPrint("Failed to instantiate a bot!");
        wait 0.5;
        return false;
    }

    // Wait a tiny bit so the test client is actually valid before threading
    wait 0.05;

    initialize(bot);
    return true;
}

/**
 * @brief Initializes a bot so it can be used for zombies
 *
 * @param bot The bot to initialize
 *
 * @return boolean assumes the bot was properly initialized
 */
initialize(bot)
{
    debugPrint("in _bot::initialize()", "fn", level.nonVerbose);

    bot.isBot = true;
    bot.hasSpawned = false;
    bot.readyToBeKilled = false;
    bot.spawnPoint = undefined;

    // Extra safety - wait until the bot is really connected
    limit = 40;   // ~2 seconds max
    while (!isDefined(bot) || !isDefined(bot.pers) || !isDefined(bot.pers["team"]))
    {
        if (limit <= 0)
        {
            warnPrint("Bot failed to connect in time!");
            return false;
        }
        wait 0.05;
        limit--;
    }

    bot.sessionteam = "axis";
    bot.pers["team"] = "axis";
    wait 0.1;

    bot setStat(512, 100); // Yes we are indeed a bot
    bot setrank(255, 0);

    // when we want to move the bot, we link it to this entity, then move the
    // entity, and the bot gets taken along for the ride.
    bot.mover = spawn("script_model", (0,0,0));
    if (level.zombieAiDevelopment) {
        // [un]filled queue of movement orders, i.e. params for the moveTo() function
        bot.movement = spawnStruct();
        bot.movement.first = 0;
        bot.movement.next = 0;
        bot.movement.last = 0;
        bot.movement.orders = [];
        bot.speed = 0;
        // we assume one order every 0.05s, for 0.2s until we reevaluate movement,
        // but may need more orders to accomodate falling on maps like farthouse
        // for (i=0; i<20; i++) { // 1s of movement
        for (i=0; i<10; i++) { // 0.5s of movement, reduced because ran out of variables
            order = spawnStruct();
            order.origin = (0,0,0);
            order.time = 0; //s
            order.angles = (0,0,0);
            bot.movement.orders[i] = order;
        }
        bot.isFollowingWaypoints = false;
    }

    bot.index = level.bots.size;
    makeBotAvailable(bot);
    level.bots[bot.index] = bot;   
    return true;
}

/**
 * @brief Reconnects a bot when the map is restarted without a server restart
 *
 * @returns nothing
 */
reconnect(bot)
{
    debugPrint("in _bot::reconnect()", "fn", level.nonVerbose);

    initialize(bot);
}

/**
 * @brief Removes bots from the game
 *
 * @param botsToRemove array Indices of bots to remove from the game
 *
 * @returns nothing
 */
remove(botsToRemove)
{
    debugPrint("in _bot::remove()", "fn", level.nonVerbose);

    // move the bots to be removed to the end of the array
    for (i=0; i<botsToRemove.size; i++) {
        if (botsToRemove[i] == level.bots.size - 1) {
            // bot is already the last element, just undefine it
            bot = level.bots[level.bots.size - 1];
            level.bots[level.bots.size - 1] = undefined;
            kick(bot getEntityNumber());  // cheating bots! :-) really a temp ban
            continue;
        } else {
            // copy last bot into botToBeRemoved's index, then undefine the last element
            level.bots[botsToRemove[i]] = level.bots[level.bots.size - 1];
            level.bots[botsToRemove[i]].index = botsToRemove[i]; // update the bot's index
            bot = level.bots[level.bots.size - 1];
            level.bots[level.bots.size - 1] = undefined;
            kick(bot getEntityNumber()); // cheating bots! :-)
        }
    }
    // now update availableBots to ensure their indices are correct
    for (i=0; i<level.availableBots.size; i++) {
        level.availableBots[i] = level.bots[level.availableBots[i]].index;
    }
}

/**
 * @brief Makes a bot available for use as a zombie
 *
 * @param bot struct The bot to make available for use
 *
 * @returns nothing
 */
makeBotAvailable(bot)
{
    debugPrint("in _bot::makeBotAvailable()", "fn", level.fullVerbosity);

    // push the bot's index onto the availableBots stack
    level.availableBots[level.availableBots.size] = bot.index;
}

/**
 * @brief Plays a sound on a bot, such as death and attack sounds
 *
 * @param delay float The time, in seconds, to wait before playing the sound
 * @param sound string The base name of the sound, xom_death, zom_attack, etc
 * @param random integer The integer to concatenate with \c sound to determine the sound to play
 *
 * @returns nothing
 */
playSoundOnBot(bot, delay, sound, random)
{
    debugPrint("in _bot::playSoundOnBot()", "fn", level.fullVerbosity);

    if (delay > 0) {
        bot endon("death");
        wait delay;
    }
    // concatenate sound name: zom_death1, zom_attack6, etc
    sound = sound + random;
    if (isAlive(bot)) {bot playsound(sound);}
}

/**
 * @brief Give rank and upgrade points to players that damaged a zombie but didn't kill it
 *
 * @param killer entity The player that finally killed the zombie
 *
 * @returns nothing
 */
giveAssists(bot, killer)
{
    debugPrint("in _bot::giveAssists()", "fn", level.highVerbosity);

    for (i=0; i<bot.damagedBy.size; i++) {
        struct = bot.damagedBy[i];
        if (isdefined(struct.player)) {
            if (struct.player.isActive && struct.player != killer) {
                struct.player.assists ++;
                if (struct.damage > 400) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist5");
                    struct.player thread scripts\players\_players::incUpgradePoints(10*level.rewardScale);
                } else if (struct.damage > 200) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist4");
                    struct.player thread scripts\players\_players::incUpgradePoints(7*level.rewardScale);
                } else if (struct.damage > 100) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist3");
                    struct.player thread scripts\players\_players::incUpgradePoints(5*level.rewardScale);
                } else if (struct.damage > 50) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist2");
                    struct.player thread scripts\players\_players::incUpgradePoints(3*level.rewardScale);
                } else if (struct.damage > 25) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist1");
                    struct.player thread scripts\players\_players::incUpgradePoints(3*level.rewardScale);
                } else if (struct.damage > 0) {
                    struct.player thread scripts\players\_rank::giveRankXP("assist0");
                    struct.player thread scripts\players\_players::incUpgradePoints(2*level.rewardScale);
                }
            }
        }
    }
    bot.damagedBy = undefined;
}

/**
 * @brief Sets the animation for a zombie by changing the zombie's weapon
 *
 * @param type string The name of the animation type
 *
 * @returns nothing
 */
setAnimation(bot, type)
{
    // 6th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (isDefined(bot.animation[type])) {
        bot.animWeapon = bot.animation[type];
        bot TakeAllWeapons();
        bot.pers["weapon"] = bot.animWeapon;
        bot giveweapon(bot.pers["weapon"]);
        bot givemaxammo(bot.pers["weapon"]);
        bot setspawnweapon(bot.pers["weapon"]);
        bot switchtoweapon(bot.pers["weapon"]);
    }
}

/**
 * @brief Puts a zombie in idle mode, i.e. just standing there
 *
 * @returns nothing
 */
idle(bot)
{
    debugPrint("in _bot::idle()", "fn", level.fullVerbosity);

    bot setAnimation(bot, "stand");
    bot.cur_speed = 0;
    bot.alertLevel = 0;
    bot.status = 0;
    //iprintlnbold("IDLE!");
}

search(bot)
{
    debugPrint("in _bot::search()", "fn", level.fullVerbosity);

    bot endon("dying");
    bot endon("disconnect");
    bot endon("death");
    level endon("game_ended");

    if (level.zombieAiDevelopment) {
        // look for a target, if we find one, head towards it and end function
        // if we don't find one, head towards a random waypoint
        bot.status = 0;
    } else {
        bot.status = 0;
    }
    //iprintlnbold("SEARCHING!");
}

getPath(bot)
{
    debugPrint("in _bot::getPath()", "fn", level.fullVerbosity);

    // iPrintLnBold("getting path");

    bot endon("dying");
    bot endon("disconnect");
    bot endon("death");
    level endon("game_ended");

    if ((bot.status == 3) || (bot.status == 4)) { // pursuing or melee
        return botPathfindTargetHistory(bot);
    }
    if (level.waypointsInvalid) {
        return botPathfindVisualNav(bot);
    } else {
        return botPathfindWaypointsNew(bot);
    }

}

// Returns the human-readable name of the BOT state as a string
botStateToString(state) {
    switch(state)
    {
        case 0:         return "IDLE"; // Idle
        case 1:    return "SEARCHING"; // Wandering, no target, low alert
        case 2:     return "STALKING"; // Trying to get/keep target in sight, medium alert
        case 3:     return "PURSUING"; // Target in sight, high alert
        case 4:        return "MELEE"; // In melee range and attacking
        case 5:      return "STUNNED"; // Hit by thundergun / stunned
        case 6:    return "REACQUIRE_TARGET"; // Lost sight, going to last known position
        case 7:         return "DEAD"; // Dead
        case 8:   return "VICTORIOUS"; // Successfully killed target, standing over it
        case 9:      return "RECYCLE"; // ready to recycle
        default:                     return "UNKNOWN_STATE_" + state;
    }
}

changeState(bot, newState) {
    bot.previousStatus = bot.status;
    bot.status = newState;
    // how many control ticks has the bot been in this state?
    // each tick is level.zomInterval second, i.e. 0.2 seconds, or 4 frames.
    bot.stateTickCount = 0;
    noticePrint("Bot " + bot.index + " " + botStateToString(bot.previousStatus) + " --> " + botStateToString(bot.status));

    bot notify("state_changed");
}

// called from _bots::spawZombie():  bot thread scripts\bots\_bot::botMain(bot);
botMain(bot)
{
    // no function entrance debugging, main loop
    bot endon("disconnect");
    bot endon("death");
    level endon("game_ended");

    wait 1.2; // wait until bot is standing up before he starts to move
    // how many control ticks has the bot been alivee?
    // each tick is level.zomInterval second, i.e. 0.2 seconds, or 4 frames.
    bot.tickCount = 0;
    bot.stateTickCount = 0;
    botSpawnedAndStalking = 0;
    bot.previousStatus = 0; // initialize previousStatus so we can detect status changes in the loop and print them for debugging
    while (1) {
        if (bot.tickCount > 10000) {bot.tickCount = 0;}             // overflow protection
        if (bot.stateTickCount > 10000) {bot.stateTickCount = 0;}   // overflow protection

        bot.tickCount++;
        if (bot.tickCount > 2000) {
            noticePrint("Bot " + bot.index + " bailing on main loop.");
            break;
        }
        if (bot.status > 2) {noticePrint("bot.status: " + bot.status);}
        switch (bot.status) {
            case 0: // BOT_STATE_IDLE
                bot.stateTickCount++;

                // bot has been idle 10 seconds
                if (bot.stateTickCount % 50 == 0) {}

                // set state searching
                bot changeState(bot, 1); // BOT_STATE_SEARCHING
                bot.alertLevel = 100;
                setSpeed(bot);
                iPrintLnBold("Bot " + bot.index + " Idle --> Searching");
                break;
            case 1: // BOT_STATE_SEARCHING
                // search now, and every second thereafter
                if (bot.stateTickCount % 5 == 0) {
                    bot.stateTickCount++;
                    // find a target                    
                    if (!isDefined(bot.targetedPlayer)) {
                        bot bestTarget(bot);  // sets bot.bestTarget & bot.closestTarget
                    // if (!isDefined(bot.bestTarget)) {
                        // wander towards bot.closestTarget, but keep searching
                        // bot thread doWander(bot);
                        // bot thread wander(bot);
                        bot thread wander(bot);
                        iPrintLnBold("Searching towards " + bot.targetedPlayer.name);
                    } else {
                        // bot.targetedPlayer = bot.bestTarget;  // temp hack, think we have 2 variables for the same things indifferent parts of the code
                        // setTargetedPlayer(bot.bestTarget);

                        // set state searching
                        bot changeState(bot, 2); // BOT_STATE_STALKING
                        iPrintLnBold("Bot " + bot.index + " Searching --> Stalking " + bot.targetedPlayer.name);
                    }
                } else {
                    bot.stateTickCount++;
                }
                break;
            case 2: // BOT_STATE_STALKING
                if ((!level.autoMapTestDone) && (level.autoMapTesting)) {
                    level.autoMapTestDone = true;
                    fmt = "msg|A zombie(bot) player spawned.||botSpawnedAndStalking|true:b||";
                    log("automaptest", sprintfLog(fmt, ""));
                    iPrintLnBold("Auto Map Test: COMPLETED");
                }  
                // stalk now, until state changes
                if (bot.stateTickCount == 0) {
                    bot.stateTickCount++;
                    noticePrint("Bot " + bot.index + " Stalking " + bot.bestTarget.name + " pos: " + bot.bestTarget.origin);
                    bot thread wander(bot);
                } else {
                    bot.stateTickCount++;
                }

                // canWeSeeTarget() if no, set state reacquire target; break;
                // checkForBetterTarget() // every Nth iteration
                // if not found, break;  keep stalking current target
                // if found, stalk new target
                break;
            case 3: // BOT_STATE_PURSUING
                // canWeSeeTarget() if no, set state reacquire target; break;
                // checkForBetterTarget() // every Nth iteration
                // if not found, break;  keep pursuing current target
                // if found, pursue new target
                break;
            case 4: // BOT_STATE_MELEE
                break;
            case 5: // BOT_STATE_STUNNED
                // wait until stun duration is over, then set state searching
                break;
            case 6: // BOT_STATE_REACQUIRE
                // move to last known target position
                // if at last known position, look for target
                // canWeSeeTarget() if no, canWeSeeAnyTarget()? if no, set state searching.
                // if yes, set state to stalking | pursuing depending on distance to target
                break;
            case 7: // BOT_STATE_DEAD
                // do nothing, wait for respawn.  might have to wait for body to decompose
                break;
            case 8: // BOT_STATE_VICTORIOUS
                // play groan; then set state idle
                break;
            case 9: // BOT_STATE_RECYCLE
                // likely reinit and respawn
                break;
                default:
                bot.status = 9; // BOT_STATE_IDLE 
                
        }

        wait level.zomInterval;  // set to 0.2 seconds, or 4 frames.
        // wait: seconds, where the server runs 20 frames per second.  Therefore,
        // `wait 1` pauses execution for 1 second (20 frames),
        // `wait 0.05` pauses for 1 frame
    }
}

// controls bot movement across the map
wander(bot)
{
    debugPrint("in _bot::wander()", "fn", level.fullVerbosity);

    bot endon("dying");
    bot endon("disconnect");
    bot endon("death");
    bot endon("alerted");
    bot endon("found_target");
    bot endon("state_changed");
    level endon("game_ended");

    if (level.waypointsInvalid)
    {
        noticePrint("Waypoints Invalid - using old wandering method");
        // TODO: old direct wandering fallback
        return;
    }

    stackEmptyCount = 0;
    while (1)
    {
        // Get a fresh path if our stack is empty
        if (!isDefined(bot.pathStack) || bot.pathStack isEmpty()) {
            stackEmptyCount++;
            getPath(bot);                    // This loads bot.pathStack internally
            // bot.pathStack print("New path loaded");
            if (stackEmptyCount >= 3) {wait 0.5;}
        }

        if (isDefined(bot.nextWp) && (bot.myWaypoint == bot.nextWp)) {
            // both the bot & the player have the same closest waypoint in common
            // if the map has sparse waypoints, either not too many, or a very large map,
            // the player and the zombie might still be quite far away from each other.
            dis = distanceSquared(bot.origin, bot.targetedPlayer.origin);
            if (dis < level.meleeRangeSquared) {
                noticePrint("In melee range");
            }
            if (dis < level.pursuitRangeSquared) {
                noticePrint("In pursuit range");
                // enter pursuit mode
            }
        }

        if (!(bot.pathStack isEmpty())) {
            stackEmptyCount = 0;
            // Process ONE waypoint per iteration
            bot.nextWp = bot.pathStack pop();

            bot.pathType = pathType(bot.myWaypoint, bot.nextWp);

            // === Handle different path types ===
            if (bot.pathType == level.PATH_CLAMPED) {
                bot clamped(bot);
                bot executeMovementQueue(bot);
            } else if (bot.pathType == level.PATH_TELEPORT) {
                bot teleport(bot);
            } else if (bot.pathType == level.PATH_MANTLE) {
                if ((!(bot.pathStack isEmpty())) &&
                    (pathType(bot.nextWp, bot.pathStack peek()) == level.PATH_FALL))
                {
                    bot.pathType = level.PATH_MANTLE_OVER;
                    bot mantleOver(bot);
                } else {
                    bot mantle(bot);
                    bot executeMovementQueue(bot);
                }
            } else if (bot.pathType == level.PATH_LADDER && bot.isBipedal) {
                bot ladder(bot);
                bot executeMovementQueue(bot);
            } else if (bot.pathType == level.PATH_NORMAL) {
                bot normalPath(bot);           // removed "thread" for now
                bot executeMovementQueue(bot);
            } else if (bot.pathType == level.PATH_FALL) {
                bot fall(bot);
            } else if (bot.pathType == level.PATH_JUMP) {
                bot jump(bot);
            } else {
                // fallback
                bot normalPath(bot);
                bot executeMovementQueue(bot);
            }

            bot.myWaypoint = bot.nextWp;
        }
        wait 0.05;   // Give the engine breathing room - very important
    }
}


setSpeed(bot)
{
    if ((bot.alertLevel >= 200 && (!bot.walkOnly || bot.quake)) || bot.sprintOnly) {
        bot run(bot);

//         if (level.dvar["zom_dominoeffect"]) {
//             thread alertZombies(bot.origin, 480, 5, self);
//         }
    } else {bot walk(bot);}
}

run(bot)
{
    // Do *not* put a function entrance debugPrint statement here!

    bot.motionType = level.BOT_RUN;
    bot setAnimation(bot, "sprint");
    bot.cur_speed = bot.runSpeed;
    bot.speed = bot.runSpeed;
    if (bot.quake) {Earthquake(0.25, .3, bot.origin, 380);}
}

walk(bot)
{
    // Do *not* put a function entrance debugPrint statement here!

    bot.motionType = level.BOT_WALK;
    bot setAnimation(bot, "walk");
    bot.cur_speed = bot.walkSpeed;
    bot.speed = bot.walkSpeed;
    if (bot.quake) {Earthquake(0.17, .3, bot.origin, 320);}
}

teleport(bot)
{
    // Do *not* put a function entrance debugPrint statement here!

    bot endon("dying");
    bot endon("disconnect");
    bot endon("death");
    level endon("game_ended");

    if (bot.isFollowingWaypoints) {
        // since we are following waypoints, we assume no solid objects or obstructions
        noticePrint("Teleport!");
        iPrintLnBold("Teleport!");

        direction = vectorNormalize(level.Wp[bot.nextWp].origin - level.Wp[bot.myWaypoint].origin);
        facing = vectorToAngles(direction);
        bot setPlayerAngles(facing);
        bot.mover.origin = level.Wp[bot.nextWp].origin;
    }
}

/// climbing up a ladder.  bipeds only
ladder(bot)
{
    // Do *not* put a function entrance debugPrint statement here!

    bot endon("dying");
    bot endon("disconnect");
    bot endon("death");
    level endon("game_ended");

    if (bot.isFollowingWaypoints) {
        // since we are following waypoints, we assume no solid objects or obstructions
        noticePrint("Ladder!");
        iPrintLnBold("Ladder!");

        bot.motionType = level.BOT_CLIMB;
        bot.speed = int((bot.walkSpeed + bot.runSpeed) / 2);
        bot setAnimation(bot, "sprint");

        facing = undefined;
        if (level.Wp[bot.nextWp].origin[2] > level.Wp[bot.myWaypoint].origin[2]) {
            // going up
            if (isDefined(level.Wp[bot.myWaypoint].upAngles)) {
                facing = level.Wp[bot.myWaypoint].upAngles;
//                 iPrintLnBold("Using .upAngles!");
            }
        } else {
            // going down
            if (isDefined(level.Wp[bot.myWaypoint].downAngles)) {
                facing = level.Wp[bot.myWaypoint].downAngles;
//                 iPrintLnBold("Using .downAngles!");
            }
        }
        if (!isDefined(facing)) {
            direction = vectorNormalize(level.Wp[bot.nextWp].origin - level.Wp[bot.myWaypoint].origin);
            facing = vectorToAngles(direction);
//             iPrintLnBold("Using computed angles!");
        }

        distance = distance(level.Wp[bot.myWaypoint].origin, level.Wp[bot.nextWp].origin);
        time = distance / bot.speed;

        bot setPlayerAngles(facing);
        bot.mover moveTo(level.Wp[bot.nextWp].origin, time, 0, 0);
        bot.mover waittill("movedone");

        bot setSpeed();
        /// @todo while devPlayer is on ladder, save getPlayerAngles().  Put this in .angles for both "ladder" waypoints
    } else {
        // not following waypoints
    }
}

/// climbing up a wall and falling down the other side of the wall
mantleOver(bot)
{
    bot endon("dying");
    bot endon("disconnect");
    bot endon("death");
    level endon("game_ended");

    if (bot.isFollowingWaypoints) {
        noticePrint("Mantle Over!");
        iPrintLnBold("Mantle Over!");
        // since we are following waypoints, we assume no solid objects or obstructions

        if (bot.speed <= 150) {speed = 100;}
        else if (bot.speed <= 250) {speed = 200;}
        else {speed = 300;}
        mantleMovement = cachedMovement(bot.myWaypoint, bot.nextWp, level.MANTLE_SPEED);
        lastWp = bot.pathStack peek();
        fallMovement = cachedMovement(bot.nextWp, lastWp, speed);
        if ((isDefined(mantleMovement)) && (isDefined(fallMovement))) {
            // use the first motion from mantle
            bot setPlayerAngles(mantleMovement.motions[0].facing);
            bot.mover moveTo(mantleMovement.motions[0].position, mantleMovement.motions[0].time, 0, 0);
            bot.mover waittill("movedone");

            // combine second mantle motion and first fall motion
            from = mantleMovement.motions[0].position;
            to = fallMovement.motions[0].position;
            distance = distance(from, to);
            if (speed == 0) {speed = 10;} // temp div by zero protection
            time = distance / speed;
            warnPrint("768: Divide by Zero: (time, distance, speed): " + time + " " + distance + " " + speed);
            bot.mover moveTo(to, time, 0, 0);
            bot.mover waittill("movedone");

            // do all remaining fall motions
            for (i=1; i<fallMovement.motions.size; i++) {
                if (fallMovement.motions[i].type == "to") {
                    bot setPlayerAngles(fallMovement.motions[i].facing);
                    bot.mover moveTo(fallMovement.motions[i].position, fallMovement.motions[i].time, 0, 0);
                    bot.mover waittill("movedone");
                } else if (fallMovement.motions[i].type == "gravity") {
                    bot setPlayerAngles(fallMovement.motions[i].facing);
                    bot.mover moveGravity(fallMovement.motions[i].velocity, fallMovement.motions[i].time);
                    bot.mover waittill("movedone");
                }
            }
            bot.myWaypoint = bot.nextWp;
            bot.nextWp = lastWp;
            bot.pathStack pop();
            self postFall(fallMovement.closest);
            return;
        } else {
            // cache miss!
            noticePrint("Motion cache miss (from, to, speed): (" + bot.myWaypoint + ", " + bot.nextWp + ", " + speed + ")");
            // treat it as a mantle path as a fail-safe
            bot mantle(bot);
            bot executeMovementQueue(bot);
            bot.myWaypoint = bot.nextWp;
        }
    }
}

/// climbing up a short wall or crate.
mantle(bot)
{
    // Do *not* put a function entrance debugPrint statement here!

    bot endon("dying");
    bot endon("disconnect");
    bot endon("death");
    level endon("game_ended");

    speed = level.MANTLE_SPEED;
    movement = cachedMovement(bot.myWaypoint, bot.nextWp, speed);
    if (isDefined(movement)) {
        // execute!
        for (i=0; i<movement.motions.size; i++) {
            if (movement.motions[i].type == "to") {
                bot setPlayerAngles(movement.motions[i].facing);
                bot.mover moveTo(movement.motions[i].position, movement.motions[i].time, 0, 0);
                bot.mover waittill("movedone");
            }
        }
        return;
    } else {
        // cache miss!
        noticePrint("Motion cache miss (from, to, speed): (" + bot.myWaypoint + ", " + bot.nextWp + ", " + speed + ")");
        // treat it as a clamped path as a fail-safe
        bot clamped(bot);
        bot executeMovementQueue(bot);
        bot.myWaypoint = bot.nextWp;
    }
}

/**
 * @brief Moves a bot along a waypoint link line, regardless of any other factors.
 *
 * Used rarely for edge cases in maps where normal movement, mantling, and climbing
 * ladders isn't enough.
 *
 * @returns nothing
 */
clamped(bot)
{
    debugPrint("in _bot::clamped()", "fn", level.fullVerbosity);

    bot endon("dying");
    bot endon("disconnect");
    bot endon("death");
    level endon("game_ended");

    if (bot.isFollowingWaypoints) {
        noticePrint("Clamped!");
        // since we are following waypoints, we assume no solid objects or obstructions

        /** This is the code we would like to apply to the bots, but Activision's
         * bug thwarts us.  Internally, setPlayerAngles() treats all players as if
         * they were bipedal and zeros out the z-coordinate of the direction vector.
         * The result is that players are always oriented vertically, regardless of
         * our wishes--we would prefer if quadrapeds followed the ground plane instead
         * of being vertical.
         *
         * Since setPlayerAngles() doesn't work properly, this code is commented
         * out, but left here in the hopes that I can eventually find a work-around.
         *
         * @code
         *  to = level.Wp[bot.nextWp].origin;
         *  from = level.Wp[bot.myWaypoint].origin;
         *  if (bot.isBipedal) {
         *      to = to * (1,1,0);
         *      from = from * (1,1,0);
         *  }
         *  direction = vectorNormalize(to - from);
         *
         * @endcode
         */
        direction = vectorNormalize(level.Wp[bot.nextWp].origin - level.Wp[bot.myWaypoint].origin);
        facing = vectorToAngles(direction);
        distance = distance(level.Wp[bot.myWaypoint].origin, level.Wp[bot.nextWp].origin);
        time = distance / bot.speed;
        self enqueueMovement(level.Wp[bot.nextWp].origin, time, facing);
    } else {
        noticePrint("In clamped(), but .isFollowingWaypoints is false!");
    }
}

/**
 * @brief Draws a local right-handed coordinate system
 *
 * @param direction vector The unit vector specifing the direction for the x-axis
 * determine the direction with \code
 * direction = vectorNormalize(endPoint - bot.origin);
 * \endcode
 *
 * The x-axis is drawn in red, the y-axis in green, and the z-axis in blue.  The
 * origin for the local coordinate system is placed at bot.origin.
 * @depends matrix.gsc must be included, and only works in dev mode where the line()
 * function is available.
 *
 * @returns nothing
 */
devDrawLocalCoordinateSystem(bot, direction, origin)
{
    debugPrint("in _bot::devDrawLocalCoordinateSystem()", "fn", level.nonVerbose);

    bot endon("hide_coordinate_system");

    if (!isDefined(origin)) {origin = bot.origin;}

    // standard basis vectors in world coordinate system
    i = (1,0,0);
    j = (0,1,0);
    k = (0,0,1);

    // [i|j|k]Prime are the basis vectors for the rotated coordinate system
    iPrime = direction;
    kPrime = vectorNormalize((origin + (0,0,25)) -  origin);
    kPrime = kPrime * -1;
    u = zeros(3,1);
    setValue(u,1,1,iPrime[0]);  // x
    setValue(u,2,1,iPrime[1]);  // y
    setValue(u,3,1,iPrime[2]);  // z
    v = zeros(3,1);
    setValue(v,1,1,kPrime[0]);  // x
    setValue(v,2,1,kPrime[1]);  // y
    setValue(v,3,1,kPrime[2]);  // z
    // i cross -k to get the real j
    jPrimeM = matrixCross(u, v);
    jPrime = vectorNormalize((value(jPrimeM,1,1), value(jPrimeM,2,1), value(jPrimeM,3,1)));
    w = zeros(3,1);
    setValue(w,1,1,jPrime[0]);  // x
    setValue(w,2,1,jPrime[1]);  // y
    setValue(w,3,1,jPrime[2]);  // z
    // now i cross j to get the real k
    kPrimeM = matrixCross(u, w);
    kPrime = vectorNormalize((value(kPrimeM,1,1), value(kPrimeM,2,1), value(kPrimeM,3,1)));

    while (1) {
        line(origin, origin + (iPrime * 30), decimalRgbToColor(255,0,0), false, 25);
        line(origin, origin + (jPrime * 30), decimalRgbToColor(0,255,0), false, 25);
        line(origin, origin + (kPrime * 30), decimalRgbToColor(0,0,255), false, 25);
        wait 0.05;
    }
}

jump(bot)
{
    iPrintLnBold("Jump!");
    noticePrint("Jump!");

    speed = 10; // in jump() case, an arbitrary number we used in calculating hash
    movement = cachedMovement(bot.myWaypoint, bot.nextWp, speed);
    if (isDefined(movement)) {
        // execute!
        for (i=0; i<movement.motions.size; i++) {
            if (movement.motions[i].type == "to") {
                bot setPlayerAngles(movement.motions[i].facing);
                bot.mover moveTo(movement.motions[i].position, movement.motions[i].time, 0, 0);
                bot.mover waittill("movedone");
            } else if (movement.motions[i].type == "gravity") {
                bot setPlayerAngles(movement.motions[i].facing);
                bot.mover moveGravity(movement.motions[i].velocity, movement.motions[i].time);
                bot.mover waittill("movedone");
            }
        }
        return;
    } else {
        // cache miss!
        noticePrint("Motion cache miss (from, to, speed): (" + bot.myWaypoint + ", " + bot.nextWp + ", " + speed + ")");
        // treat it as a clamped path as a fail-safe
        self clamped();
        self executeMovementQueue();
        bot.myWaypoint = bot.nextWp;
    }
}

fall(bot)
{
    iPrintLnBold("Fall!");
    noticePrint("Fall!");

    if (bot.speed <= 150) {speed = 100;}
    else if (bot.speed <= 250) {speed = 200;}
    else {speed = 300;}
    movement = cachedMovement(bot.myWaypoint, bot.nextWp, speed);
    if (isDefined(movement)) {
        // execute!
        for (i=0; i<movement.motions.size; i++) {
            if (movement.motions[i].type == "to") {
                bot setPlayerAngles(movement.motions[i].facing);
                bot.mover moveTo(movement.motions[i].position, movement.motions[i].time, 0, 0);
                bot.mover waittill("movedone");
            } else if (movement.motions[i].type == "gravity") {
                bot setPlayerAngles(movement.motions[i].facing);
                bot.mover moveGravity(movement.motions[i].velocity, movement.motions[i].time);
                bot.mover waittill("movedone");
            }
        }
        self postFall(movement.closest);
        return;
    } else {
        // cache miss!
        noticePrint("Motion cache miss (from, to, speed): (" + bot.myWaypoint + ", " + bot.nextWp + ", " + speed + ")");
        // treat it as a clamped path as a fail-safe
        self clamped();
        self executeMovementQueue();
        bot.myWaypoint = bot.nextWp;
    }
}

postFall(bot, closest)
{
    // Asking: does the closest wp exist in bot.pathStack?
    // but we aren't doing anything with it, regardless
    // potentialNodes = bot.pathNodes;
    // potentialNodes[potentialNodes.size] = bot.nextWp;
    // for(i=0; i<closest.size; i++) {
    //     noticePrint("Closest: " + i +":"+ closest[i]);
    //     for (j=0; j<potentialNodes.size; j++) {
    //         if (closest[i] == potentialNodes[j]) {
    //             noticePrint(closest[i] + " found in potentialNodes");
    //         }
    //     }
    // }

    bot.pathStack print("postFall() initial path: ");
    noticePrint(bot, "bot.origin: " + bot.origin);

    nearestWp = nearestWaypoints(bot.origin, 1)[0];
    if (nearestWp == bot.goalWp) {
        // just move to goalWp, and invalidate pathStack
        distance = distance(bot.origin, level.Wp[bot.goalWp].origin);
        direction = vectorNormalize(level.Wp[bot.goalWp].origin - bot.origin);
        facing = vectorToAngles(direction);
        time = distance / bot.speed;
        self enqueueMovement(level.Wp[bot.goalWp].origin, time, facing);
        self executeMovementQueue();
        bot.myWaypoint = bot.goalWp;
        bot.pathStack empty();
        return;
    }

    // invalidate any waypoints up to nearestWp
    while ((bot.pathStack size() > 0) && (bot.pathStack peek() != nearestWp)) {
        // remove all wp not equal tp nearestWp, until nearestWp is top of stack, or stack is empty
        bot.pathStack pop();
    }

    if (bot.pathStack isEmpty()) {
        // we need a new path
//         iPrintLnBold("post-fall: getting a new path");
        if (nearestWp == bot.goalWp) {
            // No path exists from one point the the *same* point
            bot.status = 0; // for now, go idle
            warnPrint("994: Temp: Went idle; already at goal Waypoint.");
            return;
        }
        bot.pathStack pushMany(AStarNew(bot.myWaypoint, bot.targetWp));
        noticePrint("998: A* call (bot, myWaypoint, bot.goalWp): (" + bot.name + ", " + bot.myWaypoint + ", " + bot.goalWp + ")");
        bot.pathStack print("1000: bot " + bot.index + " postFall path");
    }

    // decide which of the remaining nodes to go to, and how to get there
    // do we go to nearestWp, or to a point on a waypoint link to one of
    // the waypoints in pathStack?
    testWp = bot.pathStack peek();
    directDistance = distance(bot.origin, level.Wp[testWp].origin);
    linkDistance = distance(level.Wp[nearestWp].origin, level.Wp[testWp].origin);
    if (directDistance < linkDistance) {
        // we are already closer to the next pathnode than if we were at nearestWp
        // if we have a clear path to the next pathnode, go there directly
        trace = bulletTrace(bot.origin + (0,0,20), level.Wp[testWp].origin + (0,0,20), false, self);
        if (trace["fraction"] == 1) {
            noticePrint("post-fall: moving directly to testWp");
            distance = distance(bot.origin, level.Wp[testWp].origin);
            time = distance / bot.speed;
            facing = vectorToAngles(level.Wp[testWp].origin - bot.origin);
            self enqueueMovement(level.Wp[testWp].origin, time, facing);
            self executeMovementQueue();
            bot.nextWp = testWp;
            bot.pathStack pop();
            bot.myWaypoint = bot.nextWp;
            return;
        } else {
            // else if we have a clear path to the nearest point on the link line, go there
            // and then to the next pathnode
            vectorToLine = vectorFromLineToPoint(level.Wp[bot.nextWp].origin, level.Wp[testWp].origin, bot.origin) * -1;
            linePosition = bot.origin + vectorToLine;
            trace = bulletTrace(bot.origin + (0,0,20), linePosition + (0,0,20), false, self);
            if (trace["fraction"] == 1) {
                // we have a clear path
                // move to line
                noticePrint("post-fall: moving testWp via nearest point on link line");
                distance = distance(bot.origin, linePosition);
                time = distance / zeroGuard(bot.speed, 30, "_bot::postFall() line 1033 bot.speed");
                facing = vectorToAngles(vectorToLine);
                self enqueueMovement(linePosition, time, facing);

                // move to waypoint
                distance = distance(linePosition, level.Wp[testWp].origin);
                time = distance / zeroGuard(bot.speed, 30, "_bot::postFall() line 1039 bot.speed");
                facing = vectorToAngles(level.Wp[testWp].origin - level.Wp[bot.nextWp].origin);
                self enqueueMovement(level.Wp[testWp].origin, time, facing);
                self executeMovementQueue();
                bot.nextWp = testWp;
                bot.pathStack pop();                
                bot.myWaypoint = bot.nextWp;
                return;
            }
        }
    }

    // go to nearestWp
    noticePrint("post-fall: moving directly to nearestWp: " + nearestWp);
    distance = distance(bot.origin, level.Wp[nearestWp].origin);
    time = distance / zeroGuard(bot.speed, 30, "_bot::postFall() line 1054 bot.speed");
    facing = vectorToAngles(level.Wp[nearestWp].origin - bot.origin);
    self enqueueMovement(level.Wp[nearestWp].origin, time, facing);
    self executeMovementQueue();
    bot.pathStack pop();        
    bot.nextWp = nearestWp;
    bot.myWaypoint = bot.nextWp;
    bot.pathStack print("post-fall path: ");
    noticePrint("testWp: " + testWp);
}

/*
 * @brief Protects against 'Divide By Zero' errors
 *
 * @param divisor numeric The number you are dividing by
 * @param replacement numeric The number to use if the divisor is zero
 * @param reference string Reference to the offending code,
 *   such as "_bot::postFall() line 1055 bot.speed"
 *
 * @returns integer A non-zero number, either \c replacement or 1
 */
zeroGuard(divisor, replacement, reference) {
    if (!isDefined(divisor)) {return undefined;} // don't make things worse
    if (divisor == 0) {
        errorPrint("DivideByZero: " + reference);
        if (replacement == 0) { // What the hell, man!
            ret = 1;
        } else {ret = replacement;}
    } else {ret = divisor;}
    return ret;
}

getOnPath(bot)
{
    directDistance = distance(bot.origin, level.Wp[bot.nextWp].origin);
    testWp = bot.pathStack peek();
    pathDistance = distance(level.Wp[bot.nextWp].origin, level.Wp[testWp].origin);
    pathQueued = false;
    if (directDistance < pathDistance) {
        // if we went to nextWp, we would actually be getting farther from the subsequent node
        vectorToLine = vectorFromLineToPoint(level.Wp[bot.nextWp].origin, level.Wp[testWp].origin, bot.origin) * -1;
        linePosition = bot.origin + vectorToLine;
        trace = bulletTrace(bot.origin + (0,0,20), linePosition + (0,0,20), false, self);
        if (trace["fraction"] == 1) {
            // we have a clear path
            // move to line
            distance = distance(bot.origin, linePosition);
            // divide by zero guards
            time = distance / bot.speed;
            facing = vectorToAngles(vectorToLine);
            self enqueueMovement(linePosition, time, facing);

            // move to waypoint
            distance = distance(linePosition, level.Wp[testWp].origin);
            // divide by zero guards
            time = distance / bot.speed;
            facing = vectorToAngles(level.Wp[testWp].origin - level.Wp[bot.nextWp].origin);
            self enqueueMovement(level.Wp[testWp].origin, time, facing);
            pathQueued = true;
        }
    }
    if (!pathQueued) {
        // move directly to first waypoint
        distance = distance(bot.origin, level.Wp[bot.myWaypoint].origin);
        // divide by zero guards
        time = distance / bot.speed;
        facing = vectorToAngles(level.Wp[bot.myWaypoint].origin - bot.origin);
        enqueueMovement(level.Wp[bot.myWaypoint].origin, time, facing);
    }
    // executeMovement() ???
    bot.pathStack pop();
}

/*
 * @brief Draws a scaled unit vector in the direction of the velocity vector
 *
 * @param v_0 vector Initial velocity vector
 * @param r_0 vector Initial position vector
 *
 * @depends map must be in developer mode
 */
drawVelocity(v_0, r_0)
{
    from = r_0;
    to = r_0 + (vectorNormalize(v_0) * 30);
    while (1) {
        line(from, to, decimalRgbToColor(255,0,0), false, 25);
        wait 0.05;
    }
}

/*
 * @brief Draws a line between two points
 *
 * @param from vector Position vector to start the line, i.e. r_i
 * @param to vector Position vector to start the line, i.e. r_f
 *
 * @depends map must be in developer mode
 */
drawLine(from, to)
{
    while (1) {
        line(from, to, decimalRgbToColor(0,0,128), false, 25);
        wait 0.05;
    }
}

/**
 * Reflects a vector v over a surface with normal n.
 *
 * @param v The incident vector (e.g. velocity or direction)
 * @param n The surface normal vector (should ideally be normalized)
 * @return The reflected vector
 *
 * This implements the standard reflection formula:
 *     r = v - 2 * dot(n, v) * n
 */
reflect(v, n)
{
    if (!isDefined(v) || !isDefined(n))
        return (0,0,0);

    d = vectorNormalize(v);                    // Incident direction (unit vector)
    return d - 2 * vectorDot(n, d) * n;
}

computeMantle(from, to, mover, movement)
{
    direction = vectorNormalize(level.Wp[to].origin - level.Wp[from].origin);
    facing = vectorToAngles(direction);
    deltaZ = level.Wp[to].origin[2] - level.Wp[from].origin[2];
    position = level.Wp[from].origin + (0,0,deltaZ);
    time = deltaZ / level.MANTLE_SPEED;
    motion = spawnStruct();
    motion.type = "to";
    motion.position = position;
    motion.time = time;
    motion.facing = facing;
    movement.motions[movement.motions.size] = motion;

    distance = distance(position, level.Wp[to].origin);
    time = distance / level.MANTLE_SPEED;
    motion = spawnStruct();
    motion.type = "to";
    motion.position = level.Wp[to].origin;
    motion.time = time;
    motion.facing = facing;
    movement.motions[movement.motions.size] = motion;

    return movement;
}

computeJump(from, to, mover, movement)
{
    // compute initial velocity, v_0, for our fall
    direction = level.Wp[to].origin - level.Wp[from].origin;
    direction = direction * (1,1,0);
    direction = vectorNormalize(direction);
    direction = direction + (0,0,1); // jump at 45 degree angle

    // treat as a 2-d problem in the plane of the jump
    // assume: point mass, constant g, no resistive forces
    // given: r, r_0, g, and v_0_hat
    // req'd: s_0, t
    r_0 = level.Wp[from].origin;
    r = level.Wp[to].origin;
    v_0_hat = vectorNormalize(direction);
    g = getDvarInt("g_gravity");     // acceleration due to gravity

    // x, y are in the plane of the jump, *not* world coordinates
    x_displacement = distance((r[0],r[1],0), (r_0[0],r_0[1],0));
    y_displacement = r[2] - r_0[2];
    D = (2 * (x_displacement - y_displacement)) / g;
    if (D < 0) {
        // no real solutions
        errorPrint("No real solution(s).  Solution(s) are imaginary!");
        // hack to ensure a cache miss, so the impossible jump will be treated as
        // a clamped path
        movement.speed = 100;
        return movement;
    }
    t = sqrt(D);
    s_0 = x_displacement / (0.707107 * t); // 0.707107 is sin(45 degrees)
    v_0 = s_0 * v_0_hat;

    t_0 = int(t / 0.05) * 0.05;
    finalStepTime = t - t_0;
    facing = vectorToAngles(v_0);
    motion = spawnStruct();
    motion.type = "gravity";
    motion.velocity = v_0;
    motion.time = t;
    motion.facing = facing;
    movement.motions[movement.motions.size] = motion;

    if (finalStepTime > 0) {
        motion = spawnStruct();
        motion.type = "to";
        motion.position = r;
        motion.time = finalStepTime;
        motion.facing = facing;
        movement.motions[movement.motions.size] = motion;
    }
    return movement;
}

/**
 * @brief Pre-computes ballistic motion in R^3
 *
 * We assume a point mass, located at r_0, no resistive forces, and
 * a constant acceleration due to gravity.
 *
 * With a game-standard acceleration due to gravity of (0,0,-800) units * s^(-2),
 * one distance unit equals 0.4829 inches or 1.227 cm.
 *
 * @param v_0_hat vector The initial velocity unit vector
 * @param r_0 vector The inital position vector.  r_0 *must* be at the actual edge
 *              of a surface, or ballistic motion will hit the very spot we are
 *              standing at.
 * @param s_0 integer The inital speed
 * @param mover entity Unneeded?
 * @param movement struct The movement struct we will cache
 * @param recurseCount integer The number of recursions thus far
 * @param drawPath boolean draw the parabolic path?
 *
 * @returns struct The movement to cache
 */
computeBallistic(v_0_hat, r_0, s_0, mover, movement, recurseCount, drawPath)
{
//     noticePrint("(v_0_hat, r_0, s_0): " + v_0_hat + ", " + r_0 + ", " + s_0);
    onGround = false;
    if (!isDefined(recurseCount)) {recurseCount = 0;}
    if (!isDefined(drawPath)) {drawPath = false;}

    r = (0,0,0);                                // position at time t
    v = (0,0,0);                                // velocity at time t
    s = 0;                                      // speed at time t
    g = (0,0,getDvarInt("g_gravity") * -1);     // acceleration due to gravity, assume constant

    v_0 = s_0 * v_0_hat;
    facing = vectorToAngles(v_0_hat);

    // for this motion, find impact time with resolution of +/- 0.05s
    t = 0;
    r_last = r_0;
    v_last = v_0;
    s_last = s_0;
    trace = undefined;
    while (1) {
        t = t + 0.05;
        r = r_0 + (v_0 * t) + (0.5 * g * t * t);
        if (drawPath) {thread drawLine(r_last, r);}
        trace = bulletTrace(r_last, r, false, mover);
        if (trace["fraction"] != 1) {
            break; // we would hit the ground if we did this
        }
        r_last = r;
    }
    t = t - 0.05 - 0.005;
    // repeat the last segment with time resolution of +/- 0.005s
    while (1) {
        t = t + 0.005;
        r = r_0 + (v_0 * t) + (0.5 * g * (t * t));
        trace = bulletTrace(r_last, r, false, mover);
        if (trace["fraction"] != 1) {
            // we would hit the ground if we did this, so save final speed for last step
            v = v_0 + (g * (t - 0.005));
            s = distance((0,0,0), v);
            s_last = s;
            if (drawPath) {thread drawLine(r_last, trace["position"]);}
            break;
        }
        if (drawPath) {thread drawLine(r_last, r);}
        r_last = r;
    }
    position = trace["position"];
    distance =  distance(r_last, position);
    t_epsilon = distance / s_last;
    t_0 = t - 0.005 + t_epsilon;
    t = int(t_0 / 0.05) * 0.05;
    finalStepTime = t_0 - t;
    mover.origin = position;
    motion = spawnStruct();
    motion.type = "gravity";
    motion.velocity = v_0;
    motion.time = t;
    motion.facing = facing;
    motion.position = position;
    movement.motions[movement.motions.size] = motion;

    normal = trace["normal"];
    if (normal[2] <= 0.15) {
        // we hit a nearly vertical surface like a wall
        testPosition = position + (-2 * v_0_hat);
    } else {
        testPosition = position;
    }
    ground = findGround(testPosition);
    deltaZ = abs(position[2] - ground[2]);
    if (deltaZ <= 0.5) { // close enough!
        position = ground;
        onGround = true;
    }

    mover.origin = position;
    if (finalStepTime > 0) {
        motion = spawnStruct();
        motion.type = "to";
        motion.position = position;
        motion.time = finalStepTime;
        motion.facing = vectorToAngles(facing);
        movement.motions[movement.motions.size] = motion;
    }
    if (!onGround) {
        // approximation in lieu of momemtum calculations
        v_0_hat = reflect(v, trace["normal"]);
        s_1 = s_last * .25; // hitting the wall/ceiling takes 75% of our velocity
        if (recurseCount < 3) {
            recurseCount++;
            movement = computeBallistic(v_0_hat, position, s_1, mover, movement, recurseCount, drawPath);
        } else {
            noticePrint("Recursion limit reached, only using first ballistic trajectory.");
            /// When recursion limit is reached, just use the first moveGravity segment
            /// For example, sometimes we wind up inside a pallet, bouncing back and forth
            /// against the inside surfaces of pallet slats.
            // keep move to edge, first gravity movement, and final step movement (if it exists)
            for (i = movement.motions.size - 1; i > 2; i--) {
                movement.motions[i] = undefined;
            }
            if (movement.motions[2].type == "gravity") {movement.motions[2] = undefined;}
        }
    }
    return movement;
}

computeMotions()
{
    mover = spawn("script_model", (0,0,0));

    for (i=0; i<level.WpCount; i++) {
        if (level.Wp[i].type == "fall") {
            for (j=0; j<level.Wp[i].linkedCount; j++) {
                linkedID = level.Wp[i].linked[j].ID;
                if (pathType(i, linkedID) == level.PATH_FALL) {
                    // a falling path
//                     noticePrint("found fall path from " + i + " to " + linkedID);
                    edge = findFallEdge(i, linkedID);
                    if (isDefined(edge.position)) {
                        distance = distance(level.Wp[i].origin, edge.position);
                        speed = 100;
                        for (k=0; k<3; k++) {
                            movement = spawnStruct();
                            movement.type = level.PATH_FALL;
                            movement.from = i;
                            movement.to = linkedID;
                            movement.speed = speed;
                            movement.motions = [];
                            if (speed == 0) {speed = 10;} // temp div by zero protection                            
                            t = distance / speed;
                            warnPrint("1455: (time, distance, speed): " + t + " " + distance + " " + speed);
                            motion = spawnStruct();
                            motion.type = "to";
                            motion.position = edge.position;
                            motion.time = t;
                            motion.facing = vectorToAngles(edge.direction);
                            movement.motions[movement.motions.size] = motion;
                            movement = computeBallistic(edge.direction, edge.position, speed, mover, movement, 0, true);
                            movement.finalPosition = movement.motions[movement.motions.size - 1].position;
                            /// @todo ensure the path is clear to these waypoints
                            movement.closest = nearestWaypoints(movement.finalPosition, 4);
                            cacheMovement(movement);
                            speed = speed + 100;
                        }
                    }
                }
            }
        } else if (level.Wp[i].type == "mantle") {
            for (j=0; j<level.Wp[i].linkedCount; j++) {
                linkedID = level.Wp[i].linked[j].ID;
                if (pathType(i, linkedID) == level.PATH_MANTLE) {
                    speed = level.MANTLE_SPEED; // HACK
                    movement = spawnStruct();
                    movement.type = level.PATH_MANTLE;
                    movement.from = i;
                    movement.to = linkedID;
                    movement.speed = speed;
                    movement.motions = [];
                    movement = computeMantle(i, linkedID, mover, movement);
                    cacheMovement(movement);

                    /// @todo for every movement.type == level.PATH_MANTLE in cache,
                    /// see if there is a movement.type == level.PATH_FALL where
                    /// the mantle movement.to == the fall movement.from.
                    /// these are the level.PATH_MANTLE_OVER we want to cache

                    // also, the reversed path is a level.PATH_FALL
//                     noticePrint("found fall (mantle down) path from " + linkedID + " to " + i);
                    edge = findFallEdge(linkedID, i);
                    if (isDefined(edge.position)) {
                        distance = distance(level.Wp[i].origin, edge.position);
                        speed = 100;
                        for (k=0; k<3; k++) {
                            movement = spawnStruct();
                            movement.type = level.PATH_FALL;
                            movement.from = linkedID;
                            movement.to = i;
                            movement.speed = speed;
                            movement.motions = [];
                            if (speed == 0) {speed = 10;} // temp div by zero protection
                            t = distance / speed;
                            warnPrint("1506: Divide by zero: (time, distance, speed): " + t + " " + distance + " " + speed);
                            motion = spawnStruct();
                            motion.type = "to";
                            motion.position = edge.position;
                            motion.time = t;
                            motion.facing = vectorToAngles(edge.direction);
                            movement.motions[movement.motions.size] = motion;
                            movement = computeBallistic(edge.direction, edge.position, speed, mover, movement, 0, false);
                            movement.finalPosition = movement.motions[movement.motions.size - 1].position;
                            /// @todo ensure the path is clear to these waypoints
                            movement.closest = nearestWaypoints(movement.finalPosition, 3);
                            cacheMovement(movement);
                            speed = speed + 100;
                        }
                    }
                }
            }
        } else if (level.Wp[i].type == "jump") {
            for (j=0; j<level.Wp[i].linkedCount; j++) {
                linkedID = level.Wp[i].linked[j].ID;
                if (pathType(i, linkedID) == level.PATH_JUMP) {
//                     noticePrint("found jump path from " + i + " to " + linkedID);
                    speed = 10;
                    movement = spawnStruct();
                    movement.type = level.PATH_JUMP;
                    movement.from = i;
                    movement.to = linkedID;
                    movement.speed = speed;
                    movement.motions = [];
                    movement = computeJump(i, linkedID, mover, movement);
                    cacheMovement(movement);
                }
            }
        }
    }
}

initMovementCache()
{
    // see http://planetmath.org/goodhashtableprimes for primes
    n = 193;    // cache size, prime.  good primes: 53, 97, 193, 389
    level.movementCache = [];
    for (i=0; i<n; i++) {
        level.movementCache[i] = [];
    }
}

cacheMovement(movement)
{
    debugPrint("in _bots::cacheMovement()", "fn", level.nonVerbose);

    hash = movementCacheHash(movement.from, movement.to, movement.speed);
    level.movementCache[hash][level.movementCache[hash].size] = movement;
}

printMovementCacheDistribution()
{
    // prob not needed for DEPLOY
    // noticePrint("bot: printing movement cache");
    for (i=0; i<level.movementCache.size; i++) {
        count = level.movementCache[i].size;
        // noticePrint("1497: bot: " + i + ":" + count);
    }
}

cachedMovement(from, to, speed)
{
    hash = movementCacheHash(from, to, speed);

    for (i=0; i<level.movementCache[hash].size; i++) {
        if ((level.movementCache[hash][i].from == from) &&
            (level.movementCache[hash][i].to == to) &&
            (level.movementCache[hash][i].speed == speed))
        {
            return level.movementCache[hash][i];
        }
    }
    return undefined;
}

movementCacheHash(from, to, speed)
{
    debugPrint("in _bots::movementCacheHash()", "fn", level.nonVerbose);

    // see http://planetmath.org/goodhashtableprimes for primes
    n = 193;    // cache size, prime.  good primes: 53, 97, 193, 389

    // large-ish prime numbers
    p1 = 196613;
    p2 = 393241;
    p3 = 786433;

    hash = xor(xor((from * p1), (to * p2)), (speed * p3)) % n;
    if (hash < 0) {hash = hash * -1;}
    return hash;
}

xor(a, b)
{
    a = int(a);
    b = int(b);
    n = 1;
    result = 0;
    while (a != 0 || b != 0) {
        mod = ((a - b) % 2);
        if (mod < 0) {mod = mod * -1;}
        result += n * mod;
        a = int(a / 2);
        b = int(b / 2);
        n = int(n * 2);
    }
    return result;
}

printMovement(movement)
{
    if (!isDefined(movement)) {
        errorPrint("movement is undefined!");
        return;
    }

    if (movement.type == level.PATH_FALL) {
        noticePrint("movement.type: " + movement.type);
        noticePrint("Movement (from, to, speed): (" + movement.from + ", " + movement.to + ", " + movement.speed + ")");
        for (i=0; i<movement.motions.size; i++) {
            if (movement.motions[i].type == "to") {
                noticePrint("motion: moveTo(" + movement.motions[i].position + ", " + movement.motions[i].time + ", " + movement.motions[i].facing + ")");
            } else if (movement.motions[i].type == "gravity") {
                noticePrint("motion: moveGravity(" + movement.motions[i].velocity + ", " + movement.motions[i].time + ", " + movement.motions[i].facing + ")");
            }
        }
    }
}

findFallEdge(fromWp, toWp)
{
    trace = bulletTrace(level.Wp[fromWp].origin + (0,0,5), level.Wp[fromWp].origin + (0,0,-5), false, self);
    if (trace["fraction"] == 1) {
        // do nothing, needed to inspect "normal"
    }
    kPrime = trace["normal"];
    iPrime = vectorNormalize(level.Wp[toWp].origin - level.Wp[fromWp].origin);
    u = zeros(3,1);
    setValue(u,1,1,iPrime[0]);  // x
    setValue(u,2,1,iPrime[1]);  // y
    setValue(u,3,1,iPrime[2]);  // z
    v = zeros(3,1);
    setValue(v,1,1,kPrime[0]);  // x
    setValue(v,2,1,kPrime[1]);  // y
    setValue(v,3,1,kPrime[2]);  // z
    // i cross k to get j
    jPrimeM = matrixCross(u, v);
    jPrime = vectorNormalize((value(jPrimeM,1,1), value(jPrimeM,2,1), value(jPrimeM,3,1)));
    w = zeros(3,1);
    setValue(w,1,1,jPrime[0]);  // x
    setValue(w,2,1,jPrime[1]);  // y
    setValue(w,3,1,jPrime[2]);  // z
    // k cross j to get real i
    iPrimeM = matrixCross(v, w);
    iPrime = vectorNormalize((value(iPrimeM,1,1), value(iPrimeM,2,1), value(iPrimeM,3,1)));

    direction = iPrime;

    to = level.Wp[fromWp].origin - (0,0,1);
    from = to + (30 * direction);
    trace = bulletTrace(from, to, false, self);
    if (trace["fraction"] == 1) {
        // we couldn't find the edge!
        /// This is probably very bad!
        noticePrint("could not find edge!");
        return undefined;
    } else {
        position = trace["position"] + (0,0,1);
    }

    edge = spawnStruct();
    edge.position = position;
    edge.direction = direction;
    return edge;
}

toEnglishPathType(pathType)
{
    if (pathType == level.PATH_MANTLE) {
        return "mantle";
    } else if (pathType == level.PATH_LADDER) {
        return "ladder";
    } else if (pathType == level.PATH_CLAMPED) {
        return "clamped";  //  stay on exactly on the line
    } else if (pathType == level.PATH_FALL) {
        return "fall";
    } else if (pathType == level.PATH_TELEPORT) {
        return "teleport";
    } else if (pathType == level.PATH_JUMP) {
        return "jump";
    } else {
        return "normal";
    }
}

pathType(fromWp, toWp)
{
    // don't spin out on errors
    if (!isDefined(fromWp)) {return undefined;}
    if (!isDefined(toWp)) {return undefined;}

    if (fromWp == toWp) {
        errorPrint("fromWp equals toWp (" + fromWp + "), there cannot be a path type!");
    }

    // almost always true, so check it first
    if ((level.Wp[fromWp].type == "stand") && (level.Wp[toWp].type == "stand")) {
        return level.PATH_NORMAL;
    }
    else if (level.Wp[fromWp].type == "mantle") {
        deltaZ = level.Wp[toWp].origin[2] - level.Wp[fromWp].origin[2];
        distance = distance2D(level.Wp[fromWp].origin, level.Wp[toWp].origin);
        if ((deltaZ >= level.MANTLE_MIN_Z) && (deltaZ <= level.MANTLE_MAX_Z) && (distance < level.MANTLE_MAX_DISTANCE)) {
            // we only mantle up, never down
            return level.PATH_MANTLE;
        }
    } else if ((level.Wp[fromWp].type == "ladder") && (level.Wp[toWp].type == "ladder")) {
        return level.PATH_LADDER;
    } else if ((level.Wp[fromWp].type == "clamped") && (level.Wp[toWp].type == "clamped")) {
        return level.PATH_CLAMPED;
    } else if ((level.Wp[fromWp].type == "clamped") && (level.Wp[toWp].type == "ladder")) {
        return level.PATH_CLAMPED;
    } else if (level.Wp[toWp].type == "mantle") {
        deltaZ = abs(level.Wp[toWp].origin[2] - level.Wp[fromWp].origin[2]);
        distance = distance2D(level.Wp[fromWp].origin, level.Wp[toWp].origin);
        if ((deltaZ >= level.MANTLE_MIN_Z) && (deltaZ <= level.MANTLE_MAX_Z) && (distance < level.MANTLE_MAX_DISTANCE)) {
            // fall off wall/crate towards the mantle waypoint
            return level.PATH_FALL;
        }
    } else if ((level.Wp[fromWp].type == "teleport") && (level.Wp[toWp].type == "teleport")) {
        return level.PATH_TELEPORT;
    } else if ((level.Wp[fromWp].type == "fall") && (level.Wp[toWp].type == "stand")) {
        deltaZ = level.Wp[toWp].origin[2] - level.Wp[fromWp].origin[2];
        if (deltaZ < -50) {
            return level.PATH_FALL;
        }
    } else if ((level.Wp[fromWp].type == "stand") && (level.Wp[toWp].type == "fall")) {
        deltaZ = level.Wp[toWp].origin[2] - level.Wp[fromWp].origin[2];
        if (deltaZ > 50) {
            /// this will be invalid path, as we can't fall up, but I need to fix A*
            /// first so it won't return a solution that includes these links.
            /// For now, just treat it as a clamped path.
            return level.PATH_CLAMPED;
        }
    } else if ((level.Wp[fromWp].type == "jump") && (level.Wp[toWp].type == "jump")) {
        return level.PATH_JUMP;
    }
    return level.PATH_NORMAL;
}

/**
 * @brief Stuns a zombie
 *
 * An effect of the thundergun
 *
 * @returns nothing
 */
stun(bot)
{
    debugPrint("in _bot::stun()", "fn", level.fullVerbosity);

    // no stunning in final wave!
    if (level.currentWave < level.totalWaves) {
        bot setAnimation(bot, "stand");
        bot.cur_speed = 0;
        bot.alertLevel = 0;
        bot.status = 5;
        //iprintlnbold("STUNNED!");
    }
}

groan(bot)
{
    debugPrint("in _bot::groan()", "fn", level.veryHighVerbosity);

    bot endon("death");
    bot endon("disconnect");

    if (bot.soundType == "dog") {return;}

    while (1) {
        if (bot.isDoingMelee == false) {
            if (bot.alertLevel == 0) {
                // Do nothing
            } else if (bot.alertLevel < 200) {
                bot playSoundOnBot(bot, randomfloat(.5), "zom_walk", randomint(7));
            } else {
                bot playSoundOnBot(bot, randomfloat(.5), "zom_run", randomint(6));
            }
        }
        wait 3 + randomfloat(3);
    }
}

canSeeTarget(bot, target)
{
    // 4th most-called function (6% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (!isDefined(target)) {return false;}
    if (!target.isObj) {
        if (!target.isAlive) {return false;}
        if (!target.isTargetable) {return false;}
    }

    if (!target.visible) {return false;}

    distance = distance(bot.origin, target.origin);
    if (distance > level.zombieSightDistance) {return false;}

    // unit vectors
    forwardVector = anglesToForward(self getplayerangles());
    targetVector = vectorNormalize(target.origin-bot.origin);
    dot = vectorDot(forwardVector, targetVector);

    // target is in the area we can see by turning our head
    if(dot > -0.5) {
        // do a trace to see if we can see the target
        if (!target.isObj) {
            // player
            trace = bullettrace(self getEye(), target getEye(), false, self);
        } else {
            trace = bullettrace(self getEye(), target.origin + (0,0,20), false, self);
        }
        /// @todo do a trace like isPathClear()
        if (trace["fraction"] == 1) {
            // no obstructions
            return true;
        } else {
            if (isDefined(trace["entity"])) {
                if (trace["entity"] == target) {
                    // we hit something, but it was our target, so no problem
                    return true;
                }
            }
            //line(bot.origin + (0,0,68), trace["position"], (1,0,0));
            return false;
        }
    }
    return false;
}


/// normal movement path from one waypoint to another, not a chain of waypoints
/*
* @brief Moves a bot from one normal waypoint to another normal one
*
* Enqueues as many movement animation frames as it takes to move from current
* waypoint to next waypoint, at the current speed, with each frame being about
* 18 inches of movement.
*
* @returns nothing
* @depends: bot.speed, bot.myWaypoint, bot.nextWp, level.Wp, level.BOT_MOVE_DISTANCE
*/
normalPath(bot)
{
    if (bot.isFollowingWaypoints) {
        noticePrint("In normalPath(), .isFollowingWaypoints is true");
        // since we are following waypoints, we assume no solid objects or obstructions

        // make animation frame such that frame distance is about 18 inches.
        frameCount = int(level.BOT_MOVE_DISTANCE / bot.speed / 0.05);
        if (frameCount == 0) {frameCount = 1;}
        deltaA = abs(level.BOT_MOVE_DISTANCE - (bot.speed * (0.05 * frameCount)));
        deltaB = abs(level.BOT_MOVE_DISTANCE - (bot.speed * (0.05 * (frameCount + 1))));
        if (deltaB < deltaA) {
            frameCount++; // this is closer to 18 units than frameCount
        }
        frameDistance = bot.speed * (0.05 * frameCount);

        direction = vectorNormalize(level.Wp[bot.nextWp].origin - level.Wp[bot.myWaypoint].origin);
        facing = vectorToAngles(direction);

        // position = level.Wp[bot.myWaypoint].origin;
        position = bot.origin;
        distance = distance(level.Wp[bot.myWaypoint].origin, level.Wp[bot.nextWp].origin);
        noticePrint("frameDistance: " + frameDistance + " distance: " + distance);
        count = 0;
        while (distance > frameDistance) {
            count++;
            distance = distance - frameDistance;
            position = position + (direction * frameDistance);
            position = self findGround(position);
            time = frameCount * 0.05;
            bot enqueueMovement(bot, position, time, facing);
        }
        noticePrint(count + " movements enqueued.");
        time = distance / bot.speed;
    } else {
        noticePrint("In computeMovement(), but .isFollowingWaypoints is false!");
    }
}

// @todo algorithm to smooth the corners at waypoints, so we don't have to turn sharply at each waypoint.
//   Something like a bezier curve where the derivatives into and out of the waypoint
//   are equal.  Should be used if the waypoints are all about same z coordinate, so we don't
//   do this at steep slopes or stairs, and if the angle between points is obtuse, so we dont
//   wind up moving through an obstruction.

// We need 3 type of zombie pathfinding:
// 1) Follow waypoints.
// 2) When no waypoints, visual navigation.
// 3) Follow target's position history.
validateWaypoint(bot, wp, label) {
    if (wp < 0) {
        if ((wp == -1) ||  // we never got past this init value
            (wp == -2) ||  // we hit our own corpse
            (wp == -4))    // returned waypoint index exceeds array bounds
        {
            errorPrint(label + " " + wp);
            return undefined;
        } else if (wp == -3) { // no visible waypoints from our position
            // this can happen if we are inside an object we shouldn't be in,
            // like a shipping container
            wp = nearestWaypoints(bot.origin, 1)[0];
            if (wp < 0) {
                errorPrint("bot.myWaypoint: " + wp);
                return undefined;
            }
        }
    }
    return wp;
}    

botPathfindWaypointsNew(bot) {
    // Follow waypoints pathfinding
    bot.isFollowingWaypoints = true;
    if (!isdefined(bot.myWaypoint)) {
        // bot just spawned from _bots::spawnZombie()
        wait 1;
    }    
    if (!isdefined(bot.pathStack)) {
        warnPrint("bot.pathStack is undefined. Should had been defined at spawning.");
        return;
    }
    if (bot.pathStack isEmpty()) {
        // I need myWaypoint, and a targetWp (which means I need a target)
        if (!isDefined(bot.targetedPlayer)) {
            bot bestTarget(bot);
        }
        bot.myWaypoint = nearestWaypoints(bot.origin, 1)[0];
        bot.targetWp = nearestWaypoints(bot.targetedPlayer.origin, 1)[0];
        if (bot.myWaypoint == bot.targetWp) {
            noticePrint("At target!"); // we should be melee'ing before we get here
            return;
        } else {
            bot.pathStack pushMany(AStarNew(bot.myWaypoint, bot.targetWp));
            bot.pathStack print("2045: bot " + bot.index + " initialization path");
            if (bot.pathStack isEmpty()) {
                warnPrint("bot.pathStack is undefined, we couldn't find a path. Would be a BUG.");
                debugPrint("Call was AStarNew(" + bot.myWaypoint + ", " + bot.targetWp + ")");
                return;
            }
            // save the target wp we used for the A* call
            // may be useful to detect a dirty bot.pathStack
            bot.previousAStarCallTargetWp =  bot.targetWp;
        }
    }
}

botPathfindVisualNav(target_position) {
    // Visual navigation pathfinding (no waypoints)
    // We can probbaly fake this by creating two pseudo waypoints, then using the same
    // code as botPathfindWaypoints().  
}
botPathfindTargetHistory(target_position) {
    // Follow target's position history pathfinding
    // We'll save a circular queue of the target's positions over the last 3 seconds,
    // then follow that queue as quickly as bot speed will allow, so we are following
    // the target's position history, not their current position.  This should be pretty
    // good at handling obstacles, and if we lose sight of target, we can still get to where
    // we lost sight and look for them.
}

/**
 * @brief Moves a zombie to/towards a desired position
 *
 * @param goalPosition vector The desired new position of the zombie
 * @param speed integer ??? How fast the zombie should move
 *
 * @returns nothing
 */
moveToPoint(bot, goalPosition, speed)
{
    // 8th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    iprintlnbold("in moveToPoint()");
    dis = distance(bot.mover.origin, goalPosition);

    if (dis < speed) {speed = dis;}
    else {speed = speed * level.zomSpeedScale;}

    targetDirection = vectorToAngles(VectorNormalize(goalPosition - bot.mover.origin));
    step = anglesToForward(targetDirection) * speed ;

    bot SetPlayerAngles(targetDirection);

    // tentative new position for zombie
    newPos = bot.mover.origin + step + (0,0,40);
    // find ground level below tentative new position
    dropNewPos = dropPlayer(newPos, 200);
    if (isDefined(dropNewPos)) {
        newPos = (dropNewPos[0], dropNewPos[1], bot compareZ(bot, goalPosition[2], dropNewPos[2]));
    }
    if (true) {
        noticePrint("(dis, speed, step): " + dis + ", " + speed + ", " + step);
        // draw a line from current position to new position, for debugging purposes
        line(bot.mover.origin + (0,0,40), newPos, (1,0,0));
    }
    // now actually move the zombie to the new position
    bot.mover moveto(newPos, level.zomInterval, 0, 0);
}
compareZ(bot, goalPositionZ, dropNewZ)
{
    // 9th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    deltaZ = dropNewZ - bot.origin[2];
    limit = 60; //30
    if (deltaZ > limit) {
        // new position would be more than 30 units higher than current position
        if (goalPositionZ > dropNewZ) {
            // goalPositionZ is even higher, limit delta height to 'limit' units
            return bot.origin[2] + limit;
        } else {return goalPositionZ;}
    }
    if (deltaZ < -1 * limit) {
        // new position would be more than 30 units lower than current position
        if (goalPositionZ < dropNewZ) {
            // dropNewZ is even lower, np
            return dropNewZ;
        } else {return goalPositionZ;}
    }
    // deltaZ is +/- limit units of current height, so just return the new height
    return dropNewZ;
}

// chase target.  Given array of target's positions over last 3 seconds,
// move to the closest one to you, then follow the same position history
// as your target, as fast as you can.  If you get with melee range, attack target.
// If you lose sight of target, go to the last place you saw them, then search for them.
// If you can then see them, pursue them again.  If you can't see them,
// un-target them, go back to wander(), and look for a new target.  If you
//find a new target, stalk them.
pursue(bot) {}



// IDEA:
// toxic (crawlers), when they get within melee range, they launch
// themselves at your head, do melee damage, and make a toxic cloud (w/o them dying).
// Don't let 'em get close!
jumpMelee() {}


// probably deprecated for waypoints pathfinding
findPathToTarget(bot)
{
    debugPrint("in _bot::findPathToTarget()", "fn", level.highVerbosity);

    if (bot.isFollowingWaypoints) {
        // since we are following waypoints, we assume no solid objects or obstructions
        distance = bot.speed * 0.05;
        targetVector = vectorNormalize(level.Wp[bot.nextWp].origin - bot.origin);
        position = bot.origin + (targetVector * distance);
        position = self findGround(position);
        deltaZ = position[2] - bot.origin[2];
        if (deltaZ >= 0) { // going up
        } else { // going down
            if (deltaZ > distance * -1) {
                // just walk
            } else {
                // we need to fall!
            }
        }
    } else {
        speed = bot.cur_speed * 5; // assume spec'd speeds are per 0.2s, not per second, so scale them
        maxDistance = speed * 0.2;
        maxStepDistance = maxDistance / 4;
        noticePrint("speed: " + speed + " maxDistance: " + maxDistance + " maxStepDistance: " + maxStepDistance);
        distance = distance(bot.origin, bot.targetedPlayer.origin);
        trace = bulletTrace(bot.origin + (0,0,20), bot.targetedPlayer.origin + (0,0,20), false, bot.targetedPlayer);
        if ((trace["fraction"] == 1) ||
            ((isDefined(trace["entity"])) && (trace["entity"] == bot.targetedPlayer)))
        {
            // we generally have a straight path to the target
            facingVector = anglesToForward(self getPlayerAngles());
            targetVector = vectorNormalize(bot.targetedPlayer.origin - bot.origin);
            origin = bot.origin;
            for (i=0; i<4; i++) {
                position = origin + (targetVector * maxStepDistance);
                position = self findLinearPath(origin, position, maxStepDistance);
                if (bot.isBipedal) {
                    // bipeds should always be vertical
                    facing = vectorToAngles(targetVector * (1,1,0)); // zero out the z-component
                } else {
                    // non-bipeds should always be parallel to the ground surface
                    facing = vectorToAngles(targetVector);
                }
//                 iPrintLnBold("enqueueing movement: " + position);
                self enqueueMovement(position, 0.05, facing);
                origin = position;
            }
        } else {
            // no straight path to target
        }
    }
}

findLinearPath(origin, destination, distance)
{
    debugPrint("in _bot::findLinearPath()", "fn", level.highVerbosity);

    position = self findGround(destination);
    if (isPathNavigable(origin, position)) {
        // really requires system of two equations in 2 variables, maxStepDistance and findGround
        positionVector = vectorNormalize(position - origin);
        position = origin + (positionVector * distance);
        position = self findGround(position);
        return position;
    } else {
        iPrintLnBold("Path not navigable!");
    }
    /// hack
    return position;
}

// map must be in developer mode for line() function
isPathNavigable(bot, origin, destination)
{
    debugPrint("in _bot::isPathNavigable()", "fn", level.highVerbosity);

    // assume the mapmaker didn't put a waypoint link through a solid object
    if (bot.isFollowingWaypoints) {return true;}

    from = (destination[0], destination[1], origin[2]);
    levelVector = vectorNormalize(from - origin);
    targetVector = vectorNormalize(destination - origin);
    dot = vectorDot(levelVector, targetVector);
    if (dot >= 0.5) {
        // path from origin to destination is +/- 45 degrees
        return true;
    } else {
        // maybe we need to jump, climb, or find an alternate route
        iPrintLnBold("dot: " + dot);
        red = decimalRgbToColor(255,0,0);
        blue = decimalRgbToColor(0,0,255);
        /// probably a step up or a step down, cliff, low wall
        while (1) {
            line(from + (0,0,30), origin + (0,0,30), red, false, 25); // levelVector
            line(destination + (0,0,30), origin + (0,0,30), blue, false, 25); // targetVector
            wait 0.5;
        }
        return false;
    }

    /// @todo implement rest of isPathNavigable()
    return true;
}

// @todo make this a stack
enqueueMovement(bot, origin, time, facing)
{
    debugPrint("in _bot::enqueueMovement()", "fn", level.highVerbosity);

    // add capacity to queue, if needed
    if (bot.movement.last == bot.movement.orders.size) {
        // our queue is too small!  Add ten more spots
        for (i=bot.movement.last; i<bot.movement.last + 10; i++) {
            order = spawnStruct();
            order.origin = (0,0,0);
            order.time = 0; //s
            order.angles = (0,0,0);
            bot.movement.orders[i] = order;
        }
    }
//     noticePrint("enqueueing movement: (" + origin + ", " + time + ", " + facing + ")");
//     noticePrint("size, first, last: (" + bot.movement.orders.size + ", " + bot.movement.first + ", " + bot.movement.last + ")");
    // insert the movement order into the queue
    bot.movement.orders[bot.movement.last].origin = origin;
    bot.movement.orders[bot.movement.last].time = time;
    bot.movement.orders[bot.movement.last].angles = facing;
    bot.movement.last++;
}

findGround(position)
{
    debugPrint("in _bot::findGround()", "fn", level.highVerbosity);

    // if input param is undef, no point spinning the server
    if (!isDefined(position)) {return undefined;}

    top = position + (0,0,50);
    bottom = position + (0,0,-9500); // large value for farthouse and other mouse-scale maps
    count = 0;

//     thread drawLine(top, bottom);

    trace = undefined;
    direction = vectorNormalize(bottom - top);
    ignoreEntity = self;

    while ((top != bottom) && (count < 10)) {
        count++;
        trace = bulletTrace(top, bottom, false, ignoreEntity);
        if (trace["fraction"] == 1) {return trace["position"];} // long way down!
        else {
            if (!isDefined(trace["entity"])) { // we hit something we shouldn't ignore
                return trace["position"];
            } else {
                // if we hit something we should ignore, try to get past it
                if (((isDefined(trace["entity"].isCorpse)) && (trace["entity"].isCorpse)) ||        // ignore corpses
                    ((isDefined(trace["entity"].isBot)) && (trace["entity"].isBot)) ||              // ignore other bots
                    ((isDefined(trace["entity"].isBarrel)) && (trace["entity"].isBarrel)) ||        // ignore barrels
                    ((isDefined(trace["entity"].isBarricade)) && (trace["entity"].isBarricade)) ||  // ignore barricades
                    ((isDefined(trace["entity"].isTurret)) && (trace["entity"].isTurret)) ||        // ignore defense turrets
                    ((isDefined(trace["entity"].isTeleporter)) && (trace["entity"].isTeleporter)))  // ignore teleporters
                {
                    if (trace["fraction"] < 0.01) {
                        distance = distanceSquared(trace["position"], bottom);
                        if (distance < 9) {
                            // close enough!
                            return 1;
                        } else if (distance > 225) {
                            // if we are more than 15 units from 'to', add 15 units to try and get past this corpse
                            ignoreEntity = trace["entity"];
                            top = trace["position"] + (15 * direction);
                        } else if (distance > 81) {
                            ignoreEntity = trace["entity"];
                            top = trace["position"] + (9 * direction);
                        } else {
                            ignoreEntity = trace["entity"];
                            top = trace["position"] + (3 * direction);
                        }
                    } else {
                        ignoreEntity = trace["entity"];
                        top = trace["position"];
                    }
                } else {
                    // hit an entity we shouldn't ignore
                    return trace["position"];
                }
            }
        }
    }
    // we somehow failed to find the ground!
    errorPrint("Failed to find the ground!");
    return position;
}

bestTarget(bot)
{
    debugPrint("in _bot::bestTarget(bot)", "fn", level.highVerbosity);

    closestDis = 1000000000;
    closestVisDis = 1000000000;
    closestPlayer = undefined;
    closestVisiblePlayer = undefined;
    for (i=0; i<level.players.size; i++) {
        player = level.players[i];
        if (!isDefined(player)) {continue;}
        if ((isDefined(player.isTargetable)) && (!player.isTargetable)) {continue;}
        if (player.isAlive) {
            // noticePrint("2604: playerName: " + player.name);
            dis = distanceSquared(bot.origin, player.origin);
            if (dis < closestDis) {
                closestDis = dis;
                closestPlayer = player;
            }
            if (bot canSeeTarget(bot, player)) {
                // iPrintLnBold("Bot can see: " + player.name);
                if (dis < closestVisDis) {
                    closestVisDis = dis;
                    closestVisiblePlayer = player;
                }
            }
        }
    }
    if (isdefined(closestVisiblePlayer)) {
        // iPrintLnBold("Best target: " + closestVisiblePlayer.name);
        bot.targetedPlayer = closestVisiblePlayer;
        bot.bestTarget = closestVisiblePlayer;
    } else if (isDefined(closestPlayer)) {
        // iPrintLnBold("No visible targets, closest target: " + closestPlayer.name);
        bot.targetedPlayer = closestPlayer;
        bot.bestTarget = closestPlayer;
    } else {
        // iPrintLnBold("No player targets!");
        return undefined;
    }
}

closestTarget()
{
    debugPrint("in _bot::closestTarget()", "fn", level.highVerbosity);

    targets = self sortTargetsByDistance();
    if (!isDefined(targets[0])) {return undefined;}

    return targets[0].player;
}

sortTargetsByDistance(bot)
{
    debugPrint("in _bot::sortTargetsByDistance()", "fn", level.highVerbosity);

    players = level.players;
    data = [];
    for (i=0; i<players.size; i++) {
        player = players[i];
        if (!isDefined(player)) {continue;}
        if ((isDefined(player.isTargetable)) && (!player.isTargetable)) {continue;}
        if (player.isAlive) {
            temp = spawnStruct();
            temp.player = player;
            temp.distance = distanceSquared(bot.origin, player.origin);
            // ordered insert by distance
            first = 0;
            j = data.size;
            while ((j > first) && (temp.distance < data[j-1].distance)) {
                data[j] = data[j-1];
                j--;
            }
            data[j] = temp;
        }
    }
    return data;
}

// deprecated??
main(bot)
{
    debugPrint("in _bot::main()", "fn", level.highVerbosity);

    bot endon("disconnect");
    bot endon("death");
    level endon("game_ended");

    wait 1.2; // wait until bot is standing up before he starts to move
    target = bestTarget(bot);
    bot.targetedPlayer = target;
    self watchTargetedPlayer();
    iPrintLnBold("Targeting " + bot.targetedPlayer.name);
    bot.cur_speed = bot.walkSpeed;
//     bot.speed = bot.walkSpeed * 5; // assume current speeds are spec'd per 0.2s
//     bot.speed = bot.walkSpeed;
    //     self thread executeMovementQueue();
    self wander();
}

/// execute the queued movement orders
executeMovementQueue(bot)
{
    bot endon("state_changed");    

    debugPrint("in _bot::executeMovementQueue()", "fn", level.highVerbosity);
    noticePrint("2533: in _bot::executeMovementQueue()");

    bot endon("disconnect");
    bot endon("death");
    bot endon("movement_invalidated");

    if (bot.movement.first == bot.movement.last) {
        noticePrint("2540: Bot " + bot.index + " No movements queued; nothing to do.");
        return;
    }

    if (isdefined(bot.bestTarget)) {movingToName = bot.bestTarget.name;}
    else {movingToName = bot.closestTarget.name;}
    noticePrint("2624: Target waypoint position for player: " + movingToName + " " + level.Wp[bot.targetWp].origin);

    // noticePrint("Moving!");
    // iPrintLnBold("Moving to target " + bot.targetedPlayer.name);
    // iPrintLnBold("Moving to target " + movingToName);
    initialPosition = bot.origin;  // where the bot is before we start moving
    while (bot.movement.first != bot.movement.last) {
        bot.lastPosition = bot.mover.origin; // needed to compute initial velocity for ballistic()
        position = bot.movement.orders[bot.movement.first].origin;
        time = bot.movement.orders[bot.movement.first].time;
        if (time <= 0) {
            // movement.orders queue is initialized with 20 items, with 0 time, and two (0,0,0) positions
            // usually a bug if you get here
            noticePrint("2560: time <= 0: : " + time + " size: " + bot.movement.orders.size);
            break;
        }
        angles = bot.movement.orders[bot.movement.first].angles;
        /// it always takes one full frame after motion for bot.mover.origin to be updated
        if (!isDefined(initialPosition)) {
            beginStep = bot.mover.origin;
        } else {
            beginStep = initialPosition;
            initialPosition = undefined;
        }
        beginStep = bot.mover.origin;
        bot setPlayerAngles(angles);
        bot.mover moveTo(position, time, 0, 0); // internally-threaded
        bot.mover waittill("movedone");
        endStep = bot.mover.origin;
        noticePrint("2563: Bot " + bot.index + " Step Pos (from, to): " + beginStep + " -> " + endStep);
        bot.movement.first++;
    }
    // we have executed all the queued movement orders, so reset the queue
    bot.movement.first = 0;
    bot.movement.last = 0;

    wait 0.05;
}

/**
 * @brief Watch targeted player for events that should make us find a new target
 *
 * @returns nothing
 */
watchTargetedPlayer(bot)
{
    debugPrint("in _bot::watchTargetedPlayer()", "fn", level.highVerbosity);

    bot endon("disconnect");
    bot endon("death");

    self thread onTargetedPlayerDeath();
    /// @todo also on disconnect, change class, death (boom), join spectator

}

/**
 * @brief When a targeted player goes down, invalidate the target so we can get a new one
 *
 * @returns nothing
 */
onTargetedPlayerDeath(bot)
{
    debugPrint("in _bot::onTargetedPlayerDeath()", "fn", level.highVerbosity);

    bot endon("disconnect");
    bot endon("death");
    bot endon("target_invalidated");

    bot.targetedPlayer waittill("downed");
    self notify("target_invalidated");
}

/**
 * @brief When a targeted player is invalidated, find a new target
 *
 * @returns nothing
 */
newTarget(bot)
{
    debugPrint("in _bot::newTarget()", "fn", level.highVerbosity);

    bot endon("disconnect");
    bot endon("death");

    while (1) {
        self waittill("target_invalidated");

        target = bestTarget(bot);
        bot.targetedPlayer = target;
        self watchTargetedPlayer();
    }
}

/**
 * @brief Simple setter for use from _bots:: to set the targetedPlayer
 *
 * @returns nothing
 */
setTargetedPlayer(bot, playerToTarget)
{
    debugPrint("in _bot::setTargetedPlayer()", "fn", level.highVerbosity);

    bot.targetedPlayer = playerToTarget;
}

/**
 * @brief Performs a melee attack on a player
 *
 * @returns nothing
 */
melee(bot)
{
    debugPrint("in _bot::melee()", "fn", level.veryHighVerbosity);

    bot endon("disconnect");
    bot endon("death");
    bot endon("target_invalidated");

    bot.movementType = "melee";
    bot setAnimation(bot, "melee");
    wait .6;

    if (bot.quake) {Earthquake( 0.25, .2, bot.origin, 380);}

    if (isAlive(self)) {
        bot damage(bot, level.botMeleeRange);
        bot playSoundOnBot(bot, 0, "zom_attack", randomint(8));
    }
    wait .6;

    bot setAnimation(bot, "stand");
}

/**
 * @brief Decides whether to infect a player or not
 *
 * @param chance float The percentage chance of this type of zombie infecting a player
 *
 * @returns nothing
 */
infect(bot, chance)
{
    debugPrint("in _bot::infect()", "fn", level.medVerbosity);

    if (bot.infected) {return;}

    chance = bot.infectionMP * chance;
    if (randomfloat(1) < chance) {
        self thread scripts\players\_infection::goInfected();
    }
}

damage(bot, meleeRange)
{
    debugPrint("in _bot::damage()", "fn", level.highVerbosity);

    meleeRangeSquared = meleeRange * meleeRange;
    damage = int(bot.damage * level.dif_zomDamMod);

    // damage player
    targets = self sortTargetsByDistance();
    if (targets.size == 0) {
        // all players are down, or not targetable (like in admin menu)
    }
    for (i=0; i<targets.size; i++) {
        target = targets[i].player;
        distance = targets[i].distance; // a squared distance
        if (distance < meleeRangeSquared) {
            fwdDir = anglesToForward(self getPlayerAngles());
            dirToTarget = vectorNormalize(target.origin - bot.origin);
            dot = vectorDot(fwdDir, dirToTarget);
            if (dot > .5) {
                target.isPlayer = true;
                target.entity = target;
                target scripts\include\entities::damageEnt(self, self, damage,
                                 "MOD_MELEE", bot.pers["weapon"], bot.origin, dirToTarget);
                self scripts\bots\_types::onAttack(bot.type, target);
                if (level.dvar["zom_infection"]) {target infect(bot.infectionChance);}
                // only damage the first suitable player we find
                break;
            }
        } else {
            // no other player targets within range
            break;
        }
    }

    // damage a barricade
    for (i=0; i<level.barricades.size; i++) {
        barricade = level.barricades[i];
        distance = distance2d(bot.origin, barricade.origin);
        range = meleeRange * 2;
        if (distance < range) {
            barricade thread scripts\players\_barricades::doBarricadeDamage(damage);
            break;
        }
    }

    // damage a dynamic barricade
    for (i=0; i<level.dynamic_barricades.size; i++) {
        barricade = level.dynamic_barricades[i];
        distance = distance2d(bot.origin, barricade.origin);
        if (distance < meleeRange) {
            barricade thread scripts\players\_barricades::doBarricadeDamage(damage);
            break;
        }
    }
}

fixStuck(bot)
{
    debugPrint("in _bot::fixStuck()", "fn", level.highVerbosity);

    if (!isDefined(bot)) {return;}

    bot endon("dying");
    bot endon("disconnect");
    bot endon("death");
    level endon("game_ended");

    lastX = undefined;
    lastY = undefined;
    skipCount = 0;

    while ((!isDefined(bot.readyToBeKilled)) || (!bot.readyToBeKilled)) {
        wait 0.1;
    }

    while (1) {
        wait 10;
        // stuck bots may be jumping up and down, so ignore z coordinate
        currentX = bot.origin[0];
        currentY = bot.origin[1];
        if (!isDefined(lastX)) {
            lastX = currentX;
            lastY = currentY;
            continue;
        } else if ((lastX == currentX) && (lastY == currentY)) {
            // If our current target isn't visible (i.e. stealth or admin menu),
            // and is close to us, don't consider ourself to be stuck
            if ((isDefined(bot.currentTarget)) && (!bot.currentTarget.visible)) {
                distance = distanceSquared(bot.origin, bot.currentTarget.origin);
                if (distance < 15625) {  // 125 units
                    skipCount++;
                    if (skipCount < 6) {continue;}  // consider us stuck if the target is invisible for too long
                }
            }
            skipCount = 0;
            warnPrint("Fixing potentially stuck bot at " + bot.origin + " on map " + getdvar("mapname"));
            // we are stuck!  Move us to a random spawnpoint
            spawnpoint = scripts\gamemodes\_survival::randomSpawnpoint();
            bot.mover.origin = spawnpoint.origin;
            bot.mover.angles = spawnpoint.angles;
            bot.myWaypoint = undefined;
            search();
            // update last
            lastX = spawnpoint.origin[0];
            lastY = spawnpoint.origin[1];
        } else {
            // update last
            lastX = currentX;
            lastY = currentY;
        }
    }
}

// from callback, so self here is the bot
killed(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
    debugPrint("in _bot::killed()", "fn", level.veryHighVerbosity);

    //self unlink();
    self notify("dying");

    if (self.sessionteam == "spectator") {return;}

    if (sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE") {
        sMeansOfDeath = "MOD_HEAD_SHOT";
    }

    if (level.dvar["zom_orbituary"]) {
        obituary(self, attacker, sWeapon, sMeansOfDeath);
    }

    self.sessionstate = "dead";

    isBadKill = false;

    if (isplayer(attacker) && attacker != self) {  // this supposed to, and used to, mean the attacker is a player && the attacker wasn't the one killed
        if ((self.type == "burning") ||
            (self.type == "burning_dog") ||
            (self.type == "burning_tank"))
        {
            // No demerits if weapon is claymore or defense turrets, since player
            // has no control over when it detonates/fires
            switch (sWeapon) {
                case "claymore_mp":     // Fall through
                case "turret_mp":
                case "none":            // minigun and grenade turrets are "none"
                    // Do nothing
                break;
                default:
                    players = level.players;
                    noticePrint(players.size);
                    for (i=0; i<players.size; i++) {
                        if (!isDefined(players[i])) {continue;}
                        if (players[i].isBot) {continue;}
                        noticePrint(players[i].name);
                        if (attacker != players[i]) { // if attacker is not iteration player
                            if ((!players[i].isDown) &&     // if iteration player isn't down && was close enough to be damaged due to attacker
                                (distance(self.origin, players[i].origin) < 150)) {
                                noticePrint(attacker.name + " hurt " + players[i].name + " by killing an exploding zombie.");
                                attacker thread scripts\players\_rank::increaseDemerits(level.burningZombieDemeritSize, "burning");
                                isBadKill = true;
                            }
                        }
                    }
                    break;
            }
        }
        if (!isBadKill) {
            // No credit for kills that hurt teammates
            attacker.kills++;

            attacker thread scripts\players\_rank::giveRankXP("kill");
            attacker thread scripts\players\_spree::checkSpree();

            if (attacker.curClass=="stealth") {
                attacker scripts\players\_abilities::rechargeSpecial(10);
            }
            attacker scripts\players\_players::incUpgradePoints(10*level.rewardScale);
            giveAssists(self, attacker);
        }
    }

    corpse = self scripts\bots\_types::onCorpse(self.type);
    if (self.soundType == "zombie") {
        self playSoundOnBot(self, 0, "zom_death", randomint(6));
    }

    if (corpse > 0) {
        if (self.type=="toxic") {
            deathAnimDuration = 20;
        }

        body = self clonePlayer(deathAnimDuration);
        body.isCorpse = true;

        if (corpse > 1) {
            thread scripts\include\physics::delayStartRagdoll( body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath );
        }
    } else {
//         self setOrigin((0,0,-10000));
    }
    self setOrigin((0,0,-10000));
    self unlink();

    level.dif_killedLast5Sec++;

    wait 1;
    self.hasSpawned = false;
    level.botsAlive -= 1;

    makeBotAvailable(self);
//     noticePrint("zombie killed, making bot available");
    level notify("bot_killed");
}
