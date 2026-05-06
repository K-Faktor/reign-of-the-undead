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

#include scripts\include\data;
#include scripts\include\utility;

init()
{
    log("trace", "msg|in _hud::init()||");

    level.waveHUD = 0;
    level.waveHUD_Killed = 0;
    level.waveHUD_Total = 0;

    level.globalHUD = 0;

    precache();
}


precache()
{
    log("trace", "msg|in _hud::precache()||");

    precachestring(&"ZOMBIE_STREAK");
    precachestring(&"ZOMBIE_NEWWAVE");
    precachestring(&"ZOMBIE_BOSS_EXPLOSIVES");
    precachestring(&"ZOMBIE_BOSS_KNIFE");
    precachestring(&"ZOMBIE_DAMMOD");
    precachestring(&"ZOMBIE_AVAILABLE_SKILLPOINTS");
    precachestring(&"ZOMBIE_SURV_LEFT");
    precachestring(&"ZOMBIE_SURV_DOWN");

    precacheShader("overlay_low_health");
    precacheShader("progress_bar_fill");
    precacheshader("hud_weapons");
    precacheshader("hud_ammo");
}


/**
 * @brief Creates a team objective point, such as over an equipment shop
 *
 * @param origin vector The position for the objecttive display
 * @param shader string The name of the shader, usu. [hud_ammo|hud_weapons]
 * @param alpha numeric Transparency of the shader, defaults to 1 (opaque)
 *
 * @returns the new HUD element
 */
createTeamObjpoint(origin, shader, alpha)
{
    log("trace", "msg|in _hud::createTeamObjpoint()||");

    objPoint = newHudElem();

    objPoint.x = origin[0];
    objPoint.y = origin[1];
    objPoint.z = origin[2];
    objPoint.isFlashing = false;
    objPoint.isShown = true;

    objPoint setShader( shader, 8, 8 );
    objPoint setWaypoint( true );

    if (isDefined(alpha)) {
        objPoint.alpha = alpha;
    } else {
        objPoint.alpha = 1;
    }
    objPoint.baseAlpha = objPoint.alpha;

    return objPoint;
}


/**
 * @brief Initialize the player's HUD when they connect
 *
 * @returns nothing
 */
onPlayerConnect()
{
    log("trace", "msg|in _hud::onPlayerConnect()||");

    self.announceHUD = 0;
    self.announceIndex = 0;
    self.announceTotal = 0;
    if (level.waveHUD) {
        self setclientdvars("ui_wavetext", level.waveHUD_Killed + "/" +  level.waveHUD_Total, "ui_waveprogress", level.waveHUD_Killed / level.waveHUD_Total);
    } else {
        self setclientdvars("ui_wavetext", "", "ui_waveprogress", 0);
    }
    self.hud_message = NewClientHudElem(self);
    self.hud_message.alpha = 0;
    self.hud_overlay = [];
    self.hud_timers = [];
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
    log("trace", "msg|in _hud::addTimer()||");

    self endon("death");
    self endon("disconnect");

    timer = spawnstruct();
    timer.id = self.hud_timers.size;
    self.hud_timers[timer.id] = timer;
    timer.hud_timer = newClientHudElem(self);
    timer.hud_timer.font = "default";
    timer.hud_timer.fontscale = 1.4;
    timer.hud_timer.x = -16;
    timer.hud_timer.y = -48 - timer.id * 32;
    timer.hud_timer.glowAlpha = 1;
    timer.hud_timer.hideWhenInMenu = false;
    timer.hud_timer.archived = true;
    timer.hud_timer.alignX = "right";
    timer.hud_timer.alignY = "bottom";
    timer.hud_timer.horzAlign = "right";
    timer.hud_timer.vertAlign = "bottom";
    timer.hud_timer.alpha = 1;
    timer.hud_timer.glowAlpha = 0;
    timer.hud_timer.glowColor = (1,1,0);
    timer.hud_timer SetTimer(time);

    timer.hud_timertext = newClientHudElem(self);
    timer.hud_timertext.elemType = "font";
    timer.hud_timertext.font = "default";
    timer.hud_timertext.fontscale = 1.4;
    timer.hud_timertext.x = -16;
    timer.hud_timertext.y = -64 - timer.id * 32;
    timer.hud_timertext.glowAlpha = 1;
    timer.hud_timertext.hideWhenInMenu = false;
    timer.hud_timertext.archived = true;
    timer.hud_timertext.alignX = "right";
    timer.hud_timertext.alignY = "bottom";
    timer.hud_timertext.horzAlign = "right";
    timer.hud_timertext.vertAlign = "bottom";
    timer.hud_timertext.alpha = 1;
    timer.hud_timertext.glowAlpha = 0;
    timer.hud_timertext.glowColor = (1,1,0);
    timer.hud_timertext.label = label;
    timer.hud_timertext setText(text);

    wait time;

    if (isDefined(timer.hud_timer)) {
        timer.hud_timer destroy();
    }
    if (isDefined(timer.hud_timertext)) {
        timer.hud_timertext destroy();
    }

    self.hud_timers = removefromarray(self.hud_timers, timer);
    for (i=0; i<self.hud_timers.size; i++) {
        self.hud_timers[i].id = i;
        self.hud_timers[i].hud_timer.y = -48 - i * 32;
        self.hud_timers[i].hud_timertext.y = -64 - i * 32;
    }

}


/**
 * @brief Removes all HUD timers
 *
 * @returns nothing
 */
removeTimers()
{
    log("trace", "msg|in _hud::removeTimers()||");

    for (i=0; i<self.hud_timers.size; i++) {
        if (isdefined(self.hud_timers[i])) {self.hud_timers[i].hud_timer destroy();}
        if (isdefined(self.hud_timers[i].hud_timertext)) {self.hud_timers[i].hud_timertext destroy();}
    }
    self.hud_timers = [];
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
    log("trace", "msg|in _hud::bar()||");

    self endon("disconnect");

    self.bar_bg = newClientHudElem(self);
    self.bar_fg = newClientHudElem(self);

    self.bar_bg endon("death");

    width = 128;
    height = 7;

    if (!isdefined(y)) {y = 0;}

    self.bar_bg.x = -0.5 * width - 2;
    self.bar_bg.y = y;
    self.bar_bg.sort = -2;
    self.bar_bg.width = width;
    self.bar_bg.height = height;
    self.bar_bg.shader = "black";
    self.bar_bg setShader( "black", width + 4, height + 4 );
    self.bar_bg.alignX = "left";
    self.bar_bg.alignY = "middle";
    self.bar_bg.horzAlign = "center";
    self.bar_bg.vertAlign = "middle";
    self.bar_bg.color = (1, 1, 1);
    self.bar_bg.alpha = 1;
    self.bar_bg.hidden = false;

    self.bar_fg.x = -0.5 * width;
    self.bar_fg.y = y;
    self.bar_fg.sort = -1;
    self.bar_fg.width = width;
    self.bar_fg.height = height;
    self.bar_fg.shader = "white";
    self.bar_fg setShader( "white", initial * width, height );
    self.bar_fg.alignX = "left";
    self.bar_fg.alignY = "middle";
    self.bar_fg.horzAlign = "center";
    self.bar_fg.vertAlign = "middle";
    self.bar_fg.color = color;
    self.bar_fg.alpha = 1;
    self.bar_fg.hidden = false;
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
    log("trace", "msg|in _hud::barSetScale()||");

    if (isDefined(self.bar_fg)) {
        self.bar_fg ScaleOverTime(1, int(self.bar_fg.width*scale), self.bar_fg.height);
        if (isdefined(color)) {self.bar_fg.color = color;}
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
    log("trace", "msg|in _hud::progressBar()||");

    self endon("disconnect");

    self.bar_bg = newClientHudElem(self);
    self.bar_fg = newClientHudElem(self);

    self.bar_bg endon("death");

    width = 128;
    height = 7;

    self.bar_bg.x = -0.5 * width - 2;
    self.bar_bg.y = 0;
    self.bar_bg.sort = -2;
    self.bar_bg.width = width;
    self.bar_bg.height = height;
    self.bar_bg.shader = "black";
    self.bar_bg setShader("black", width + 4, height + 4);
    self.bar_bg.alignX = "left";
    self.bar_bg.alignY = "middle";
    self.bar_bg.horzAlign = "center";
    self.bar_bg.vertAlign = "middle";
    self.bar_bg.color = (1,1,1);
    self.bar_bg.alpha = 1;
    self.bar_bg.hidden = false;

    self.bar_fg.x = -0.5 * width;
    self.bar_fg.y = 0;
    self.bar_fg.sort = -1;
    self.bar_fg.width = width;
    self.bar_fg.height = height;
    self.bar_fg.shader = "white";
    self.bar_fg setShader("white", 0, height);
    self.bar_fg.alignX = "left";
    self.bar_fg.alignY = "middle";
    self.bar_fg.horzAlign = "center";
    self.bar_fg.vertAlign = "middle";
    self.bar_fg.color = (1,1,1);
    self.bar_fg.alpha = 1;
    self.bar_fg.hidden = false;
    self.bar_fg ScaleOverTime(time, width, height);

    wait time;

    self.bar_fg destroy();
    self.bar_bg destroy();
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
    log("trace", "msg|in _hud::timer()||");

    level.globalHUD = 1;
    if (time < 2) {time = 2;}

    hud_timer = newHudElem();
    hud_timer.font = "objective";
    hud_timer.fontscale = 1.8;
    hud_timer.x = 0;
    hud_timer.y = 84;
    hud_timer.glowAlpha = 1;
    hud_timer.hideWhenInMenu = false;
    hud_timer.archived = true;
    hud_timer.alignX = "center";
    hud_timer.alignY = "middle";
    hud_timer.horzAlign = "center";
    hud_timer.vertAlign = "top";
    hud_timer.alpha = 0;
    hud_timer.glowAlpha = 1;
    hud_timer.glowColor = glowcolor;
    hud_timer SetTimer(time);

    hud_timertext = newHudElem();
    hud_timertext.elemType = "font";
    hud_timertext.font = "objective";
    hud_timertext.fontscale = 1.8;
    hud_timertext.x = 0;
    hud_timertext.y = 64;
    hud_timertext.glowAlpha = 1;
    hud_timertext.hideWhenInMenu = false;
    hud_timertext.archived = true;
    hud_timertext.alignX = "center";
    hud_timertext.alignY = "middle";
    hud_timertext.horzAlign = "center";
    hud_timertext.vertAlign = "top";
    hud_timertext.alpha = 0;
    hud_timertext.glowAlpha = 1;
    hud_timertext.glowColor = glowcolor;
    hud_timertext.label = label;
    if (isdefined(text)) {hud_timertext setText(text);}

    hud_timertext FadeOverTime(1);
    hud_timertext.alpha = 1;
    hud_timer FadeOverTime(1);
    hud_timer.alpha = 1;

    wait time -.5 ;

    hud_timer setPulseFX(0, 0, 1000);
    hud_timertext setPulseFX( 0, 0, 1000);

    wait .5;

    hud_timer destroy();
    hud_timertext destroy();

    level.globalHUD = 0;
    level notify("hud_global_done");
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
    log("trace", "msg|in _hud::glowMessage()||");

    self endon("disconnect");

    while(level.globalHUD) {
        level waittill("hud_global_done");
        wait .5;
    }

    if (self.announceHUD) {
        self.announceTotal++;
        index = self.announceTotal;

        while (1) {
            self waittill("hud_announce_done");
            if (index == self.announceIndex) {
                self.announceHUD = 1;
                break;
            }
        }
    } else {
        self.announceHUD = 1;
    }

    if (isdefined(sound)) {self playlocalsound(sound);}

    showGlowMessage(label, text, glowcolor, duration, speed, fontscale);
    wait duration;
    self.announceHUD = 0;
    self.announceIndex++;
    self notify("hud_announce_done");
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
    log("trace", "msg|in _hud::overlayMessage()||");

    hud_message = newHudElem();
    hud_message.elemType = "font";
    hud_message.font = "objective";
    if (!isdefined(fontscale)) {
        hud_message.fontscale = 2;
    } else {
        hud_message.fontscale = fontscale;
    }
    hud_message.x = 0;
    hud_message.y = 96;
    hud_message.glowAlpha = 1;
    hud_message.hideWhenInMenu = true;
    hud_message.archived = false;
    hud_message.alignX = "center";
    hud_message.alignY = "middle";
    hud_message.horzAlign = "center";
    hud_message.vertAlign = "top";
    hud_message.alpha = 1;
    hud_message.glowAlpha = 1;
    hud_message.glowColor = glowcolor;
    hud_message.label = label;
    if (isdefined(text)) {hud_message setText(text);}

    return hud_message;
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
 * @param fontscale integer The size of the font
 *
 * @returns nothing
 */
showGlowMessage(label, text, glowcolor, duration, speed, fontscale)
{
    log("trace", "msg|in _hud::showGlowMessage()||");

    self.hud_message.elemType = "font";
    self.hud_message.font = "objective";
    if (!isdefined(fontscale)) {
        self.hud_message.fontscale = 2;
    } else {
        self.hud_message.fontscale = fontscale;
    }
    self.hud_message.x = 0;
    self.hud_message.y = 100;
    self.hud_message.glowAlpha = 1;
    self.hud_message.hideWhenInMenu = true;
    self.hud_message.archived = false;
    self.hud_message.alignX = "center";
    self.hud_message.alignY = "middle";
    self.hud_message.horzAlign = "center";
    self.hud_message.vertAlign = "top";
    self.hud_message.alpha = 1;
    self.hud_message.glowAlpha = 1;
    self.hud_message.glowColor = glowcolor;
    self.hud_message.label = label;
    if (isdefined(text)) {self.hud_message setText(text);}

    self.hud_message setPulseFX(speed, int((duration) * 1000), 1000);
}
