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
    log("trace", "msg|in _traps::init()||");

    precache();

    if (isDefined(level.mapTraps)) {
        for (i=0; i<level.mapTraps.size; i++) {
            trap = level.mapTraps[i];
            hintString = "Press [USE] to activate the " + trap.text + " trap! (^1" + trap.cost + "^7)";
            level scripts\players\_usables::addUsable(trap.trigger, "trap", hintString, 96);
            if (trap.type == "central") {centralTrapBat(trap);}
        }
    }
}

precache()
{
    log("trace", "msg|in _traps::precache()||");

    level.fireTrapFx = loadfx("fire/firelp_med_pm_nodistort");
    level.electricTrapFx = loadfx("explosions/sparks_d");
}

/**
 * @brief Starts a trap
 *
 * @param trap struct The trap to start
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
startTrap(trap)
{
    log("trace", "msg|in _traps::startTrap()||");

    // self is activating player

    trap.isBeingUsed = true;
    switch (trap.type) {
        case "central":
            self centralTrap(trap);
            break;
        case "rotating":
            self rotatingTrap(trap);
            break;
        case "spike":
            self spikeTrap(trap);
            break;
        case "fire":
            self fireTrap(trap);
            break;
        case "electric":
            self electricTrap(trap);
            break;
    }
    trap.isBeingUsed = false;
}

/**
 * @brief Kills zombies when they trigger an active trap
 *
 * @param activatingPlayer entity The player that activated the trap
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
watchTrap(activatingPlayer)
{
    log("trace", "msg|in _traps::watchTrap()||");

    // self is the trap
    activatingPlayer endon("disconnect");
    self endon("stop_trap");

    doDamage = false;

    while (isDefined(self.killTrigger)) {
        self.killTrigger waittill("trigger", triggeringEntity);

        if (!triggeringEntity.isBot) {
            if (triggeringEntity.isZombie) {
                // traps kill player-zombies
                doDamage = true;
            } else {
                wait 0.05;
                continue;
            }
        } else if ((triggeringEntity.type != "boss") &&
                   (triggeringEntity.type != "many_bosses") &&
                   (triggeringEntity.type != "cyclops"))
        {
            // traps damage all bots except bosses and cyclops
            doDamage = true;
        }

        // ensure our trigger is bounceless, only kill a zombie if it has been at least
        // 1000 ms since they were last killed
        now = getTime();
        if (!isDefined(triggeringEntity.lastTrapKilledTime)) {triggeringEntity.lastTrapKilledTime = now - 1250;}
        if (now - triggeringEntity.lastTrapKilledTime < 1000) {
            doDamage = false;
            continue;
        }

        if (doDamage) {
            triggeringEntity.lastTrapKilledTime = now;
            if (triggeringEntity.isBot) {
                // suicide() sets the parameters to _bot::killed() wrong, so we just
                // ensure we do enough damage to kill the bot
                iDamage = triggeringEntity.maxHealth + 300;
                // if (isDefined(triggeringEntity.name)) {log("dev", "msg|" + self.type + " trap attempting to damage " + triggeringEntity.name + " at " + now + "||");}
                triggeringEntity scripts\bots\_bots::Callback_BotDamage(self.trigger, activatingPlayer, iDamage, 0, "MOD_MELEE", self.type, (0,0,0), (0,0,0), "head", 0);
            } else {
                iDamage = triggeringEntity.maxHealth + 300;
                triggeringEntity scripts\players\_players::onPlayerDamage(self.trigger, activatingPlayer, iDamage, 0, "MOD_MELEE", self.type, (0,0,0), (0,0,0), "head", 0);
            }
            doDamage = false;
        }
    }
}

/**
 * @brief Better compile reflections for central type trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
centralTrapBat(trap)
{
    log("trace", "msg|in _traps::centralTrapBat()||");

    trap.bat moveZ(-80, 1);
}

/**
 * @brief Controller for a central trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
centralTrap(trap)
{
    log("trace", "msg|in _traps::centralTrap()||");

    // self is activating player
    trap.activator PlaySound("shield_on");
    trap.activator moveZ(-10, 1);
    trap.bat moveZ(72, 1);
    wait 5;
    trap.bat rotateYaw(10800, 30);
    trap.base rotateYaw(10800, 30);
    trap.base playLoopSound("rotating");
    trap.killTrigger = spawn("trigger_radius", trap.bat.origin, 0, 172, 172);
    trap thread watchTrap(self);
    wait 25;
    trap.base StopLoopSound();
    wait 5;
    // stop watching trap trigger when it stops rotating
    trap.killTrigger = undefined;
    trap notify("stop_trap");
    wait 5;

    // reset trap
    trap.activator moveZ(10, 1);
    trap.bat moveZ(-72, 1);
    trap.activator PlaySound("shield_off");
    wait 2;
}

/**
 * @brief Controller for a rotating trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
rotatingTrap(trap)
{
    log("trace", "msg|in _traps::rotatingTrap()||");

    trap.activator PlaySound("shield_on");

    trap.activator moveZ(-12, 1);
    wait 1;
    trap.death playLoopSound("rattle");
    wait 0.1;
    trap.killTrigger = spawn("trigger_radius", trap.death.origin, 0, 250, 128);
    trap thread watchTrap(self);
    trap.death rotatePitch(7200, 20);

    wait 20;

    trap.death StopLoopSound();
    wait 0.1;
    trap.killTrigger = undefined;
    trap notify("stop_trap");
    trap.activator PlaySound("shield_off");
    trap.activator moveZ(12, 1);
    wait 1;
}

/**
 * @brief Controller for a spike trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
spikeTrap(trap)
{
    log("trace", "msg|in _traps::spikeTrap()||");

    trap.activator PlaySound("shield_on");

    trap.activator moveZ(-12, 1);
    wait 1;

    for (i=0; i<10; i++) {
        trap.death PlaySound("pneumatic");
        trap.death moveZ(32, 1);
        trap.killTrigger = spawn("trigger_radius", trap.death.origin, 0, 70, 70);
        trap thread watchTrap(self);
        wait 2;
        trap.death moveZ(-32, 1);
        trap.killTrigger = undefined;
        trap notify("stop_trap");
        wait 2;
    }

    trap.activator PlaySound("shield_off");
    trap.activator moveZ(12, 1);
    wait 1;
}

/**
 * @brief Controller for a fire trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
fireTrap(trap)
{
    log("trace", "msg|in _traps::fireTrap()||");

    trap.activator PlaySound("shield_on");

    trap.activator rotateYaw(360, 1);
    wait 1;

    trap.killTrigger = spawn("trigger_radius", trap.death.origin, 0, 32, 32);
    trap thread watchTrap(self);

    fx1 = PlayLoopedFX(level.fireTrapFx, 1, trap.fire1.origin);
    fx2 = PlayLoopedFX(level.fireTrapFx, 1, trap.fire2.origin);
    fx3 = PlayLoopedFX(level.fireTrapFx, 1, trap.fire3.origin);
    fx4 = PlayLoopedFX(level.fireTrapFx, 1, trap.fire4.origin);
    trap.fire1 PlayLoopSound("fire_metal_large");
    trap.death moveZ(48, 1);
    trap.activator rotateYaw(360, 1);

    wait 15;
    trap.killTrigger = undefined;
    trap notify("stop_trap");
    trap.death moveZ(-48, 1);
    trap.activator rotateYaw(-360, 1);

    fx1 delete();
    fx2 delete();
    fx3 delete();
    fx4 delete();
    trap.fire1 StopLoopSound();
    trap.activator PlaySound("shield_off");
    wait 1;
}

/**
 * @brief Controller for an electric trap
 *
 * @param trap struct The central trap to run
 *
 * @returns nothing
 * @since RotU 2.2.3
 */
electricTrap(trap)
{
    log("trace", "msg|in _traps::electricTrap()||");

    trap.activator PlaySound("shield_on");
    trap.activator moveZ(-2.5, 1);
    trap.death moveZ(64, 1);
    trap.killTrigger = spawn("trigger_radius", trap.death.origin, 0, 16, 16);
    trap thread watchTrap(self);

    for (i=0; i<10; i++) {
        fx1 = PlayLoopedFX(level.electricTrapFx, 1, trap.elec1.origin);
        fx2 = PlayLoopedFX(level.electricTrapFx, 1, trap.elec2.origin);
        trap.elec1 PlaySound("electric");
        wait 1;
        fx1 delete();
        fx2 delete();

        fx3 = PlayLoopedFX(level.electricTrapFx, 1, trap.elec3.origin);
        fx4 = PlayLoopedFX(level.electricTrapFx, 1, trap.elec4.origin);
        trap.elec3 PlaySound("electric");
        wait 1;
        fx3 delete();
        fx4 delete();

        fx5 = PlayLoopedFX(level.electricTrapFx, 1, trap.elec5.origin);
        fx6 = PlayLoopedFX(level.electricTrapFx, 1, trap.elec6.origin);
        trap.elec5 PlaySound("electric");
        wait 1;
        fx5 delete();
        fx6 delete();
    }

    trap.killTrigger = undefined;
    trap notify("stop_trap");
    trap.activator moveZ(2.5, 1);
    trap.death moveZ(-64, 1);
    trap.activator PlaySound("shield_off");
    wait 1;
}
