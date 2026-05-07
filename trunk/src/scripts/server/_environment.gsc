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

#include scripts\include\entities;
#include scripts\include\utility;

init()
{
    log("trace", "msg|in _environment::init()||");

    precache();

    level.blur = level.dvar["env_blur"];
    wait .25;

    if (level.dvar["env_ambient"]) {
        AmbientStop(0);
    }
    if (level.dvar["env_fog"]) {
        setExpFog(level.dvar["env_fog_start_distance"], level.dvar["env_fog_half_distance"], level.dvar["env_fog_red"]/255, level.dvar["env_fog_green"]/255, level.dvar["env_fog_blue"]/255, 0);
    }
    resetVision(0);
}

precache()
{
    log("trace", "msg|in _environment::precache()||");

    level.lightning_fx = loadfx("weather/lightning");
    level.ember_fx = loadfx("fire/emb_burst_a");
}


/**
 * @brief Returns the default vison mode
 *
 * @returns string Either "rotu" or the name of the map
 */
getDefaultVision()
{
    log("trace", "msg|in _environment::getDefaultVision()||");

    if (level.dvar["env_override_vision"]) {return "rotu";}
    else {return getDvar("mapname");}
}


/**
 * @brief Sets the current blur level when a player connects
 *
 * @returns nothing
 */
onPlayerConnect()
{
    log("trace", "msg|in _environment::onPlayerConnect()||");

    self setclientdvar("r_blur", level.blur);
}


/**
 * @brief Sets a new blur level on all players
 *
 * @param blur float Motion blur fraction [0, 1]
 *
 * @returns nothing
 */
updateBlur(blur)
{
    log("trace", "msg|in _environment::updateBlur()||");

    level.blur = blur;
    for (i=0; i<level.players.size; i++) {
        level.players[i] setclientdvar("r_blur", level.blur);
    }
}


/**
 * @brief Sets a new blur level on all players over time
 *
 * @param blur float Motion blur fraction [0, 1]
 * @param time float Duration to change the blur over
 *
 * @returns nothing
 */
setBlur(blur, time)
{
    log("trace", "msg|in _environment::setBlur()||");

    change = (blur - level.blur) / (time + 1);
    for (i=0; i<=time; i++) {
        updateBlur(level.blur + change);
        wait 1;
    }
}


/**
 * @brief Sets a new global environment FX
 *
 * @param fxType string the name of the FX type
 *
 * @returns nothing
 */
setGlobalFX(fxType)
{
    log("trace", "msg|in _environment::setGlobalFX()||");

    switch (fxType) {
        case "lightning":
            thread lightningFX();
            break;
        case "lightning_boss":
            thread lightningBossFX();
            break;
        case "ember":
            thread emberFX();
            break;
    }
}


/**
 * @brief Plays ember FX at random waypoints, or at random spawnpoints if no waypoints in map
 *        Used for burning, burning_dog, burning_tank, and inferno special waves
 *
 * @returns nothing
 */
emberFX()
{
    log("trace", "msg|in _environment::emberFX()||");

    level endon("global_fx_end");
    while(1) {
        // Some legacy maps (e.g. mp_surv_overrun) seem to not use waypoints, so level.wp.size is zero.
        // In these cases, we just get a random spawn point and use that for the origin
        if (level.wp.size < 9) {
            index = randomInt(level.botSpawnpoints.size);
            origin = level.botSpawnpoints[index].origin;
        } else {
            origin = level.wp[randomint(level.wp.size)].origin;
        }
        playfx(level.ember_fx, origin);
        Earthquake(0.25, 2, origin, 512);
        wait 0.2 + randomfloat(0.2);
    }
}


/**
 * @brief Plays lightning FX & thunder sounds, used for tank special wave
 *
 * @returns nothing
 */
lightningFX()
{
    log("trace", "msg|in _environment::lightningFX()||");

    level endon("global_fx_end");
    while (1) {
        if (level.playerspawns == "") {
            spawn = getRandomTdmSpawn();
        } else {
            spawn = getRandomEntity(level.playerspawns);
        }
        // play lightning every iteration, play one of two sounds on all players 50% of the time
        playfx(level.lightning_fx, spawn.origin);
        r = randomint(4);
        for (i=0; i<level.players.size; i++) {
            if (r == 0) {
                level.players[i] playlocalsound("amb_thunder1");
            }
            if (r == 1) {
                level.players[i] playlocalsound("amb_thunder2");
            }
        }
        wait 1 + randomfloat(2);
    }
}


/**
 * @brief Plays lightning FX & thunder sounds. Used for boss, many_bosses, cyclops special waves
 *
 * @returns nothing
 */
lightningBossFX()
{
    log("trace", "msg|in _environment::lightningBossFX()||");

    level endon("global_fx_end");
    wait 15;
    while (1) {
        if (level.playerspawns == "") {
            spawn = getRandomTdmSpawn();
        } else {
            spawn = getRandomEntity(level.playerspawns);
        }
        // play lightning every iteration, play one of two sounds on all players 66% of the time
        playfx(level.lightning_fx, spawn.origin);
        wait .2;
        setVision("thunder", .2);
        setExpFog(999999, 9999999, 0, 0, 0, .2);
        r = randomint(3);
        for (i=0; i<level.players.size; i++) {
            if (r == 0) {
                level.players[i] playlocalsound("amb_thunder1");
            } else if (r == 1) {
                level.players[i] playlocalsound("amb_thunder2");
            }
        }
        wait 0.2;
        setVision("boss", .1);
        setExpFog(512, 1024, 0, 0, 0, .1);
        wait 2 + randomfloat(2);
    }
}


/**
 * @brief Sets a named fog filter for the map
 *
 * @param name string The name of the fog to apply
 * @param time float How long to fade the transition in
 *
 * @returns nothing
 */
setFog(name, time)
{
    log("trace", "msg|in _environment::setFog()||");

    switch (name) {
        case "toxic":
            setExpFog( 256, 1024, 0.2, 0.4, 0.2, time);
            break;
        case "boss":
            setExpFog( 512, 1024, 0, 0, 0, time);
            break;
        default:
            if (level.dvar["env_fog"]) {
                setExpFog(level.dvar["env_fog_start_distance"], level.dvar["env_fog_half_distance"], level.dvar["env_fog_red"]/255, level.dvar["env_fog_green"]/255, level.dvar["env_fog_blue"]/255, time);
            } else {
                setExpFog(999999, 9999999, 0, 0, 0, time);
            }
            break;
    }
}


/**
 * @brief Sets a named vision filter for the map
 *
 * @param name string The name of the vision to apply
 * @param time float How long to fade the transition in
 *
 * @returns nothing
 */
setVision(name, time)
{
    log("trace", "msg|in _environment::setVision()||");

    level.vision = name;
    visionSetNaked(name, time);
}


/**
 * @brief Resets vision to the level default
 *
 * @param time float How long to fade the transition in
 *
 * @returns nothing
 */
resetVision(time)
{
    log("trace", "msg|in _environment::resetVision()||");

    level.vision = getDefaultVision();
    visionSetNaked(level.vision, time);
}


/**
 * @brief Plays a new ambient sound track with optional fade-in.
 *
 * This is a wrapper around the native `AmbientPlay()` function.
 * Only one ambient track can play at a time — calling this will replace the previous one.
 *
 * @param alias     string   The sound alias (from your soundaliases CSV) to play as ambient.
 * @param fadeTime  float    Fade-in duration in seconds (how long it takes to reach full volume).
 *                           Common values: 0-2 (quick), 3-8 (smooth crossfade). Defaults depend on the engine.
 *
 * @returns void
 */
setAmbient(alias, fadeTime)
{
    log("trace", "msg|in _environment::setAmbient()||");

    if (level.dvar["env_ambient"]) {
        if (!isdefined(fadeTime)) {
            fadeTime = 0;
        }
        AmbientStop(0);
        AmbientPlay(alias, fadeTime);
    }
}


/**
 * @brief Stops the currently playing ambient sound with an optional fade-out.
 *
 * This is a wrapper around the native `AmbientStop()` function.
 *
 * @param time   float   Fade-out duration in seconds. If undefined, defaults to 10.
 *                       Common values: 0 (instant), 1-3 (quick), 5-15 (smooth).
 *
 * @returns void
 */
stopAmbient(time)
{
    log("trace", "msg|in _environment::stopAmbient()||");

    if (!isdefined(time)) {time = 10;}
    AmbientStop(time);
}
