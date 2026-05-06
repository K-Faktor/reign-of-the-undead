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
 * @brief Update the wave progress HUD in lower left corner of HUD
 *        For example, this display shows '3/25' over a progress bar
 *
 * @param killed integer Number of zombies killed this wave
 * @param total integer Number of zombies in this wave
 *
 * @returns nothing
 */
updateWaveHud(killed, total)
{
    // 19th most-called function (0.5% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    level.waveHUD = 1;
    level.waveHUD_Killed = killed;
    level.waveHUD_Total = total;
    for (i=0; i<level.players.size; i++) {
        if (!isDefined(level.players[i])) {continue;}
        level.players[i] setclientdvars("ui_wavetext", level.waveHUD_Killed + "/" +  level.waveHUD_Total, "ui_waveprogress", level.waveHUD_Killed / level.waveHUD_Total);
    }
}


/**
 * @brief Creates a team objective point, such as over an equipment shop
 *
 * @param origin vector The position for the objecttive display
 * @param shader string The name of the shader, usu. [hud_ammo|hud_weapons]
 * @param alpha numeric Transparency of the shader, defaults to 1 (opaque)
 *
 * @returns nothing
 */
createTeamObjpoint(origin, shader, alpha)
{
    log("trace", "msg|in hud::createTeamObjpoint()||");

    scripts\gamemodes\_hud::createTeamObjpoint(origin, shader, alpha);
}


/**
 * @brief Creates a countdown timer, used for medkits and ammo cans
 *
 * @param label string The localized label for the timer
 * @param text string The UI text for the timer, usu. empty
 * @param time numeric The duration of the timer
 *
 * @returns nothing
 */
addTimer(label, text, time)
{
    log("trace", "msg|in hud::addTimer()||");

    thread scripts\gamemodes\_hud::addTimer(label, text, time);
}


/**
 * @brief Removes all HUD timers
 *
 * @returns nothing
 */
removeTimers()
{
    log("trace", "msg|in hud::removeTimers()||");

    thread scripts\gamemodes\_hud::removeTimers();
}


/**
 * @brief Displays a glowing, pulsing message on the HUD
 *
 * @param label string The localized label for the message, like &"ZOMBIE_INFECTED"
 * @param text string The UI text for the message
 * @param glowcolor tuple A CoD4 color tuple, basically RGB with each component divided by 255
 *                        @see utilty::decimalRgbToColor()
 * @param duration numeric How long to show the message
 * @param speed integer The speed of the pulsing effect
 * @param fontscale float The size of the font; a scalar to apply--probably <= 2
 *
 * @returns nothing
 */
announceMessage(label, text, glowcolor, duration, speed, fontscale)
{
    log("trace", "msg|in hud::announceMessage()||");

    for (i=0; i<level.players.size; i++) {
        level.players[i] thread scripts\gamemodes\_hud::glowMessage(label, text, glowcolor, duration, speed, fontscale);
    }
}

/**
 * @brief Displays a glowing, static message on the HUD.
 *        Used for the Players Alive, Players Down counters, et al.
 *
 * @param label string The localized label for the message, like &"ZOMBIE_INFECTED"
 * @param text string The UI text for the message
 * @param glowcolor tuple A CoD4 color tuple, basically RGB with each component divided by 255
 *                        @see utilty::decimalRgbToColor()
 * @param fontscale float The size of the font; a scalar to apply--probably <= 2
 *
 * @returns nothing
 */
overlayMessage(label, text, glowcolor, fontscale)
{
    log("trace", "msg|in hud::overlayMessage()||");

    return self thread scripts\gamemodes\_hud::overlayMessage(label, text, glowcolor, fontscale);
}


/**
 * @brief Displays a glowing, pulsing message on the HUD
 *
 * @param label string The localized label for the message, like &"ZOMBIE_INFECTED"
 * @param text string The UI text for the message
 * @param glowcolor tuple A CoD4 color tuple, basically RGB with each component divided by 255
 *                        @see utilty::decimalRgbToColor()
 * @param duration numeric How long to show the message
 * @param speed integer The speed of the pulsing effect
 * @param fontscale float The size of the font; a scalar to apply--probably <= 2
 * @param sound string The (optional) sound to play
 *
 * @returns nothing
 */
glowMessage(label, text, glowcolor, duration, speed, fontscale, sound)
{
    log("trace", "msg|in hud::glowMessage()||");

    self thread scripts\gamemodes\_hud::glowMessage(label, text, glowcolor, duration, speed, fontscale, sound);
}


/**
 * @brief Creates a glowing, pulsing, countdown timer, used for new wave countdown timer
 *
 * @param time numeric The duration of the timer
 * @param label string The localized label for the timer
 * @param glowcolor tuple A CoD4 color tuple, basically RGB with each component divided by 255
 *                        @see utilty::decimalRgbToColor()
 * @param text string The UI text for the timer, usu. empty
 *
 * @returns nothing
 */
timer(time, label, glowcolor, text)
{
    log("trace", "msg|in hud::timer()||");

    thread scripts\gamemodes\_hud::timer(time, label, glowcolor, text);
}

fadeout(time)
{
    log("trace", "msg|in hud::fadeout()||");

    if (isDefined(self)) {
        self fadeOverTime( time );
        self.alpha = 0;
        wait time;
        if (isDefined(self)) {
            self destroy();
        }
    }
}

fadein(time, alpha)
{
    log("trace", "msg|in hud::fadein()||");

    self.alpha = 0;
    self fadeOverTime( time );
    if (!isdefined(alpha)) {alpha = 1;}
    else {alpha = alpha;}
}

fontPulseInit()
{
    log("trace", "msg|in hud::fontPulseInit()||");

    self.baseFontScale = self.fontScale;
    self.maxFontScale = self.fontScale * 2;
    self.inFrames = 3;
    self.outFrames = 5;
}

fontPulse(player)
{
    log("trace", "msg|in hud::fontPulse()||");

    self notify ( "fontPulse" );
    self endon ( "fontPulse" );
    player endon("disconnect");
    player endon("joined_team");
    player endon("joined_spectators");

    scaleRange = self.maxFontScale - self.baseFontScale;

    while (self.fontScale < self.maxFontScale) {
        self.fontScale = min( self.maxFontScale, self.fontScale + (scaleRange / self.inFrames) );
        wait 0.05;
    }

    while (self.fontScale > self.baseFontScale) {
        self.fontScale = max( self.baseFontScale, self.fontScale - (scaleRange / self.outFrames) );
        wait 0.05;
    }
}


/**
 * @brief Creates a progress bar that goes from empty to full over time, such as for reviving
 *
 * @param time numeric The duration of the progressbar
 *
 * @returns nothing
 */
progressBar(time)
{
    log("trace", "msg|in hud::progressBar()||");

    self destroyProgressBar();
    self thread scripts\gamemodes\_hud::progressBar(time);
}


/**
 * @brief Creates a cooldown bar, as used for machine gun barrels
 *
 * @param color tuple A CoD4 color tuple, basically RGB with each component divided by 255
 *                    @see utilty::decimalRgbToColor()
 * @param initial integer The initial value of the bar, usually 1
 * @param y integer The on-scren y position of the bar
 *
 * @returns nothing
 */
bar(color, initial, y)
{
    log("trace", "msg|in hud::bar()||");

    self destroyProgressBar();
    self scripts\gamemodes\_hud::bar(color, initial, y);
}


/**
 * @brief Creates a cooldown bar, as used for machine gun barrels
 *
 * @param scale float Decimal percentage of how full the bar is, ie. 0.60
 * @param color tuple A CoD4 color tuple, basically RGB with each component divided by 255
 *                    @see utilty::decimalRgbToColor()
 *
 * @returns nothing
 */
barSetScale(scale, color)
{
    log("trace", "msg|in hud::barSetScale()||");

    self thread scripts\gamemodes\_hud::barSetScale(scale, color);
}


destroyProgressBar()
{
    log("trace", "msg|in hud::destroyProgressBar()||");

    if (isDefined(self.bar_bg)) {self.bar_bg destroy();}
    if (isDefined(self.bar_fg)) {self.bar_fg destroy();}
}

streakHud()
{
    log("trace", "msg|in hud::streakHud()||");

    self.hud_streak = NewClientHudElem(self);
    self.hud_streak.alpha = 0;
    self.hud_streak.font = "objective";
    self.hud_streak.label = &"ZOMBIE_STREAK";
    self.hud_streak.fontscale = 2;
    self.hud_streak.x = 0;
    self.hud_streak.y = 0;
    self.hud_streak.glowAlpha = .7;
    self.hud_streak.hideWhenInMenu = false;
    self.hud_streak.archived = true;
    self.hud_streak.alignX = "center";
    self.hud_streak.alignY = "middle";
    self.hud_streak.horzAlign = "center";
    self.hud_streak.vertAlign = "middle";
    self.hud_streak.color = rgb(224, 178, 27);
    self.hud_streak.glowColor = (.7,0,0);
    self.hud_streak fontPulseInit();
}

rgb(r, g, b)
{
    log("trace", "msg|in hud::rgb()||");

    return (r/255,g/255,b/255);
}

upgradeHud(points)
{
    log("trace", "msg|in hud::upgradeHud()||");

    self endon("disconnect");
    hud_score = NewClientHudElem(self);
    hud_score.alpha = 0;
    hud_score.font = "objective";
    hud_score.fontscale = 1.6;
    hud_score.x = 0;
    hud_score.y = 0;
    hud_score.glowAlpha = 1;
    hud_score.hideWhenInMenu = false;
    hud_score.archived = true;
    hud_score.alignX = "center";
    hud_score.alignY = "middle";
    hud_score.horzAlign = "center";
    hud_score.vertAlign = "middle";
    if (points > 0) {
        hud_score.glowColor = (.1, .9, .2);
        hud_score settext("+"+points);
    } else {
        // zero or < 0 points
        hud_score.glowColor = (.9, .1, .2);
        hud_score setvalue(points);
    }

    direction = randomint(360);

    hud_score FadeOverTime(.5);
    hud_score.alpha = 1;

    hud_score MoveOverTime(1.5);
    hud_score.x = cos(direction)*64;
    hud_score.y = sin(direction)*64;
    wait 1.3;
    hud_score FadeOverTime(.3);
    hud_score.alpha = 0;
    wait .3;
    hud_score destroy();

}

updateHealthHud(delta)
{
    log("trace", "msg|in hud::updateHealthHud()||");

    self setclientdvar("ui_healthbar", delta);
}

screenFlash(color, time, alpha)
{
    log("trace", "msg|in hud::screenFlash()||");

    whitescreen = newclientHudElem(self);
    whitescreen.sort = -2;
    whitescreen.alignX = "left";
    whitescreen.alignY = "top";
    whitescreen.x = 0;
    whitescreen.y = 0;
    whitescreen.horzAlign = "fullscreen";
    whitescreen.vertAlign = "fullscreen";
    whitescreen.foreground = true;
    whitescreen.color = color;

    whitescreen.alpha = alpha;
    whitescreen setShader("white", 640, 480);
    whitescreen fadeOverTime( time );
    whitescreen.alpha = 0;
    wait time;
    whitescreen destroy();
}

createHealthOverlay(color)
{
    log("trace", "msg|in hud::createHealthOverlay()||");

    whitescreen = newclientHudElem(self);
    whitescreen.sort = -2;
    whitescreen.alignX = "left";
    whitescreen.alignY = "top";
    whitescreen.x = 0;
    whitescreen.y = 0;
    whitescreen.horzAlign = "fullscreen";
    whitescreen.vertAlign = "fullscreen";
    whitescreen.foreground = true;
    whitescreen.color = color;
    whitescreen.alpha = 1;
    whitescreen setShader("overlay_low_health", 640, 480);

    return whitescreen;
}

playerFilmTweaks(enable, invert, desaturation, darktint,  lighttint, brightness, contrast, fovscale)
{
    log("trace", "msg|in hud::playerFilmTweaks()||");

    self.tweaksOverride = 1;
    self setClientDvars( "r_filmusetweaks", 1, "r_filmtweaks", 1 , "r_filmtweakenable", enable , "r_filmtweakinvert", invert , "r_filmtweakdesaturation", desaturation , "r_filmtweakdarktint",
    darktint , "r_filmtweaklighttint", lighttint , "r_filmtweakbrightness", brightness ,"r_filmtweakcontrast", contrast, "cg_fovscale", fovscale );
}

playerFilmTweaksOff()
{
    log("trace", "msg|in hud::playerFilmTweaksOff()||");

    self setClientDvars( "r_filmusetweaks", 0, "cg_fovscale", 1 );
    self.tweaksOverride = 0;
    if (self.tweaksPermanent) {doPermanentTweaks();}
}

playerSetPermanentTweaks(invert, desaturation, darktint,  lighttint, brightness, contrast, fovscale)
{
    log("trace", "msg|in hud::playerSetPermanentTweaks()||");

    self.tweakBrightness = brightness;
    self.tweakContrast = desaturation;
    self.tweakDarkTint = darktint;
    self.tweakLightTint = lighttint;
    self.tweakDesaturation = desaturation;
    self.tweakInvert = invert;
    self.tweakFovScale = fovscale;
    self.tweakContrast = contrast;
    self.tweaksPermanent = 1;
    doPermanentTweaks();
}

doPermanentTweaks()
{
    log("trace", "msg|in hud::doPermanentTweaks()||");

    self setClientDvars("r_filmusetweaks", 1, "r_filmtweaks", 1 , "r_filmtweakenable", 1 , "r_filmtweakinvert", self.tweakInvert , "r_filmtweakdesaturation", self.tweakDesaturation , "r_filmtweakdarktint",
    self.tweakDarkTint , "r_filmtweaklighttint", self.tweakLightTint , "r_filmtweakbrightness", self.tweakBrightness ,"r_filmtweakcontrast", self.tweakContrast, "cg_fovscale", self.tweakFovScale );
}

permanentTweaksOff()
{
    log("trace", "msg|in hud::permanentTweaksOff()||");

    self setClientDvars("r_filmusetweaks", 0, "cg_fovscale", 1);
    self.tweaksPermanent = 0;
}
