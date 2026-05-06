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


/**
 * @brief Starts a ragdoll animation after a fixed 100ms delay
 *
 * @param body entity A clone of the player/bot's body for the ragdoll
 * @param sHitLoc string The location of the hit
 * @param vDir vector The direction the damage is from
 * @param sWeapon string The weapon used to inflict the damage
 * @param eInflictor entity The entity that causes the damage.(e.g. a turret)
 * @param sMeansOfDeath string The method of death
 *
 * @returns nothing
 */
delayStartRagdoll(body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath)
{
    log("trace", "msg|in physics::delayStartRagdoll()||");

    if (isDefined(body)) {
        deathAnim = body getcorpseanim();
        if (animhasnotetrack(deathAnim, "ignore_ragdoll")) {return;}
    }

    wait(0.1);

    // @todo game_extremeragdoll dvar isn't in cfg files
    // @todo need to search for all dvars used in code nit spec'd in cfg files
    if (level.dvar["game_extremeragdoll"]) {
        if (!isDefined(vDir)) {vDir = (0,0,0);}

        if (!isDefined(body.origin)) {
            // If body.origin isn't defined, it isn't a player or bot, so we don't have to worry about ragdoll
            return;
        }
        explosionPos = body.origin + (0, 0, getHitLocHeight(sHitLoc));
        explosionPos -= vDir * 20;
        // thread debugLine(body.origin + (0,0,(explosionPos[2] - body.origin[2])), explosionPos);
        explosionRadius = 10;
        explosionForce = .75;
        if ((sMeansOfDeath == "MOD_IMPACT") || (sMeansOfDeath == "MOD_EXPLOSIVE") ||
            (isSubStr(sMeansOfDeath, "MOD_GRENADE")) || (isSubStr(sMeansOfDeath, "MOD_PROJECTILE")) ||
            (sHitLoc == "head") || (sHitLoc == "helmet"))
        {
            explosionForce = 2.5;
        }

        body startragdoll(1);
        wait .05;

        if (!isDefined(body)) {return;}

        // apply extra physics force to make the ragdoll go crazy
        physicsExplosionSphere(explosionPos, explosionRadius, explosionRadius / 2, explosionForce);
        return;
    } else {
        // normal ragdoll
        if (!isDefined(body)) {return;}
        if (body isRagDoll()) {return;}

        deathAnim = body getcorpseanim();
        startFrac = 0.35;

        if (animhasnotetrack(deathAnim, "start_ragdoll")) {
            times = getnotetracktimes(deathAnim, "start_ragdoll");
            if (isDefined(times)) {startFrac = times[0];}
        }

        waitTime = startFrac * getanimlength(deathAnim);
        wait(waitTime);

        if (isDefined(body)) {
            println("Ragdolling after " + waitTime + " seconds");
            body startragdoll(1);
        }
    }
}


/**
 * @brief Returns the height of the hit location
 *
 * @param sHitLoc string The location of the hit
 *
 * @returns integer the height of the hit location
 */
getHitLocHeight(sHitLoc)
{
    log("trace", "msg|in physics::getHitLocHeight()||");

    switch (sHitLoc) {
        case "helmet":
        case "head":
        case "neck":
            return 60;
        case "torso_upper":
        case "right_arm_upper":
        case "left_arm_upper":
        case "right_arm_lower":
        case "left_arm_lower":
        case "right_hand":
        case "left_hand":
        case "gun":
            return 48;
        case "torso_lower":
            return 40;
        case "right_leg_upper":
        case "left_leg_upper":
            return 32;
        case "right_leg_lower":
        case "left_leg_lower":
            return 10;
        case "right_foot":
        case "left_foot":
            return 5;
    }
    return 48;
}


/**
 * @brief Does a physics trace (finding ground) from origin to origin - drop
 *
 * @param origin vector The initial position
 * @param drop numeric deltaZ added to origin; the end test position for the trace
 *
 * @returns vector The position vector where it found the ground
 */
dropPlayer(origin, drop)
{
    // 7th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    return playerPhysicsTrace(origin, origin + (0,0,-1 * drop));
}


/**
 * @brief Scalar multiplication of a vector
 *
 * @param v vector The vector to scale
 * @param s numeric The scalar to scale the vector by
 *
 * @returns vector The scaled vector
 */
vectorscale(v, s)
{
    log("trace", "msg|in physics::vectorscale()||");

    return v * s;
}
