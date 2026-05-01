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

    level.lighting_fx = loadfx("weather/lightning");
    level.ember_fx = loadfx("fire/emb_burst_a");
}

getDefaultVision()
{
    log("trace", "msg|in _environment::getDefaultVision()||");

    if (level.dvar["env_override_vision"]) {return "rotu";}
    else {return getDvar("mapname");}
}

onPlayerConnect()
{
    log("trace", "msg|in _environment::onPlayerConnect()||");

    self setclientdvar("r_blur", level.blur);
}

updateBlur(blur)
{
    log("trace", "msg|in _environment::updateBlur()||");

    level.blur = blur;
    for (i=0; i<level.players.size; i++) {
        level.players[i] setclientdvar("r_blur", level.blur);
    }
}

setBlur(blur, time)
{
    log("trace", "msg|in _environment::setBlur()||");

    change = (blur - level.blur) / (time + 1);
    for (i=0; i<=time; i++) {
        updateBlur(level.blur + change);
        wait 1;
    }
}

setGlobalFX(fxtype)
{
    log("trace", "msg|in _environment::setGlobalFX()||");

    switch (fxtype) {
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
        Earthquake( 0.25, 2, origin, 512);
        wait .2 + randomfloat(.2);
    }
}

lightningFX()
{
    log("trace", "msg|in _environment::lightningFX()||");

    level endon("global_fx_end");
    while(1) {
        if (level.playerspawns == "") {
            spawn = getRandomTdmSpawn();
        } else {
            spawn = getRandomEntity(level.playerspawns);
        }
        playfx(level.lighting_fx, spawn.origin);
        r = randomint(4);
        for (i=0; i<level.players.size; i++){
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

lightningBossFX()
{
    log("trace", "msg|in _environment::lightningBossFX()||");

    level endon("global_fx_end");
    wait 15;
    while(1) {
        if (level.playerspawns == "") {
            spawn = getRandomTdmSpawn();
        } else {
            spawn = getRandomEntity(level.playerspawns);
        }
        playfx(level.lighting_fx, spawn.origin);
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
                setExpFog( level.dvar["env_fog_start_distance"], level.dvar["env_fog_half_distance"], level.dvar["env_fog_red"]/255, level.dvar["env_fog_green"]/255, level.dvar["env_fog_blue"]/255, time);
            } else {
                setExpFog( 999999, 9999999, 0, 0, 0, time);
            }
            break;
    }
}


/**
 * @brief Sets a named vision filter for the map
 *
 * @param name string The name of the vision ao apply
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

resetVision(time)
{
    log("trace", "msg|in _environment::resetVision()||");

    level.vision = getDefaultVision();
    visionSetNaked(level.vision, time);
}

setAmbient(ambient)
{
    log("trace", "msg|in _environment::setAmbient()||");

    if (level.dvar["env_ambient"]) {
        AmbientStop(0);
        AmbientPlay(ambient, 15);
    }
}

stopAmbient(time)
{
    log("trace", "msg|in _environment::stopAmbient()||");

    if (!isdefined(time)) {time = 10;}
    AmbientStop(time);
}
