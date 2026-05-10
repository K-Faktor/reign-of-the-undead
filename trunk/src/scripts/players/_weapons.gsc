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
 * @brief Loads all the real weapons in the mod
 *
 * @returns nothing
 */
init()
{
    log("trace", "msg|in _weapons::init()||");

    level.onGiveWeapons = -1;
    level.spawnPrimary = "none";
    level.spawnSecondary = "none";

    level.specialWeps = [];

    // assigns weapons with stat numbers from 0-149
    // attachments are now shown here, they are per weapon settings instead

    // generating weaponIDs array
    level.weaponIDs = [];
    max_weapon_num = 149;
    attachment_num = 150;
    for (i=0; i<=max_weapon_num; i++) {
        weapon_name = tablelookup("mp/statstable.csv", 0, i, 4);
        if ((!isdefined(weapon_name)) || (weapon_name == "")) {
            level.weaponIDs[i] = "";
            continue;
        }
        level.weaponIDs[i] = weapon_name + "_mp";

        // generating attachment combinations
        attachment = tablelookup("mp/statstable.csv", 0, i, 8);
        if ((!isdefined(attachment)) || (attachment == "")) {
            continue;
        }

        attachment_tokens = strtok(attachment, " ");
        if (!isdefined(attachment_tokens)) {
            continue;
        }

        if (attachment_tokens.size == 0) {
            level.weaponIDs[attachment_num] = weapon_name + "_" + attachment + "_mp";
            attachment_num++;
        } else {
            for (k=0; k<attachment_tokens.size; k++) {
                level.weaponIDs[attachment_num] = weapon_name + "_" + attachment_tokens[k] + "_mp";
                attachment_num++;
            }
        }
        // log("dev", "msg|level.weaponIDs[i] : " + i + ":" + level.weaponIDs[i] + "||");
    }
    // Since tnt_mp isn't one of the common_weapons in statstable.csv,
    // append tnt_mp to weaponIDs[] array manually
    level.weaponIDs[level.weaponIDs.size] = "tnt_mp";

    // generating weaponNames array
    level.weaponNames = [];
    for (index=0; index<max_weapon_num; index++) {
        if ((!isdefined(level.weaponIDs[index])) || (level.weaponIDs[index] == "")) {
            continue;
        }

        level.weaponNames[level.weaponIDs[index]] = index;
        // log("dev", "msg|level.weaponNames[level.weaponIDs[index]] : " + index + ":" + level.weaponIDs[index] + ":" + level.weaponNames[level.weaponIDs[index]] + "||");
    }

    // generating weaponlist array
    level.weaponList = [];
    assertex(isdefined(level.weaponIDs.size), "level.weaponIDs is corrupted");
    for (i=0; i<level.weaponIDs.size; i++) {
        if ((!isdefined(level.weaponIDs[i])) || (level.weaponIDs[i] == "")) {
            continue;
        }
        // appending to array
        // log("dev", "msg|level.weaponList[level.weaponList.size] : " + level.weaponList.size + ":" + level.weaponIDs[i] + "||");
        level.weaponList[level.weaponList.size] = level.weaponIDs[i];
    }

    // based on weaponList array, precache weapons in list
    for (index=0; index<level.weaponList.size; index++) {
        precacheItem(level.weaponList[index]);
        // log("dev", "msg|Precached weapon: " + level.weaponList[index] + "||");
    }

    //precacheItem("c4_mp");
    //precacheItem( "at4_mp" );
    //precacheItem( "tnt_mp" );
    precacheItem("crossbow_mp");

    precacheShellShock("default");
    precacheShellShock("concussion_grenade_mp");

    claymoreDetectionConeAngle = 70;
    level.claymoreDetectionDot = cos(claymoreDetectionConeAngle);
    level.claymoreDetectionMinDist = 20;
    level.claymoreDetectionGracePeriod = 0.5; // 0.75
    level.claymoreDetonateRadius = 192;
    level.maxClaymoresPerPlayer = getDvarInt("game_max_claymores_per_player");
    level.maxC4PerPlayer = getDvarInt("game_max_c4_per_player");
    level.maxTntPerPlayer = getDvarInt("game_max_tnt_per_player");

    level.c4explodethisframe = false;
    level.C4FXid = loadfx("misc/light_c4_blink");
    level.claymoreFXid = loadfx("misc/claymore_laser");
}


/**
 * @brief Is the weapon a special weapon?
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean Whether the weapon is a special weapon
 */
isSpecialWeap(weapon)
{
    log("trace", "msg|in _weapons::isSpecialWeap()||");

    for (i=0; i<level.specialWeps.size; i++) {
        if (level.specialWeps[i] == weapon) {return true;}
    }
    return false;
}


/**
 * @brief Initializes player weapon slots
 *
 * @returns nothing
 */
initPlayerWeapons()
{
    log("trace", "msg|in _weapons::initPlayerWeapons()||");

    self.primary = "none";
    self.secondary = "none";
    self.extra = "none";
}


/**
 * @brief Should a weapon flash be shown when the weapon is fired?
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean whether to show a weapon flash
 */
checkWeaponFlash(weapon)
{
    log("trace", "msg|in _weapons::checkWeaponFlash()||");

    if ((isPistol(weapon)) ||
        (weapon == "none") ||
        (weapon == "c4_mp") ||
        (weapon == "claymore_mp") ||
        (weapon == "rpg_mp") ||
        (weapon == "at4_mp") ||
        (weapon == "tnt_mp"))
    {
        return false;
    }

    return true;
}


/**
 * @brief Gives a player their weapons
 *
 * @returns nothing
 */
givePlayerWeapons()
{
    log("trace", "msg|in _weapons::givePlayerWeapons()||");

    self.primary = self.persData.primary;
    self.secondary = self.persData.secondary;
    self.extra = self.persData.extra;

    if (self.secondary != "none") {
        self giveWeapon(self.secondary);
        self setSpawnWeapon(self.secondary);
        self SwitchToWeapon(self.secondary);
        //self giveMaxAmmo(self.secondary);
        self setWeaponAmmoStock(self.secondary , self.persData.secondaryAmmoStock);
        self setWeaponAmmoClip(self.secondary , self.persData.secondaryAmmoClip);
    }
    if (self.primary != "none") {
        self giveWeapon(self.primary);
        self setSpawnWeapon(self.primary);
        self SwitchToWeapon(self.primary);
        self setWeaponAmmoStock(self.primary, self.persData.primaryAmmoStock);
        self setWeaponAmmoClip(self.primary, self.persData.primaryAmmoClip);
    }
    if (self.extra != "none") {
        self giveWeapon(self.extra);
        self giveMaxAmmo(self.extra);
    }
}


/**
 * @brief Can the weapon have its ammo restored in the shop?
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean whether the ammo can be restored
 */
canRestoreAmmo(weapon)
{
    log("trace", "msg|in _weapons::canRestoreAmmo()||");

    if ((weapon == "helicopter_mp") ||  // helicopter_mp is the medkit
        (weapon == "m14_reflex_mp") ||  // m14_reflex_mp is the ammo box
        (weapon == "c4_mp") ||          // 'Restore Ammo' shouldn't restore ammo
        (weapon == "tnt_mp") ||         // for tnt, c4, claymores--just for bullets and grenades
        (weapon == "claymore_mp") ||
        (weapon == "none") ||
        scripts\players\_weapons::isSpecialWeap(weapon))
    {
        return false;
    }
    return true;
}


/**
 * @brief Can the weapon have its ammo restored by ammo cans?
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean whether the ammo can be restored
 */
canRestoreAmmoByAmmoBoxes(weapon)
{
    log("trace", "msg|in _weapons::canRestoreAmmoByAmmoBoxes()||");

    if ((weapon == "helicopter_mp") ||  // helicopter_mp is the medkit
        (weapon == "m14_reflex_mp") ||  // m14_reflex_mp is the ammo box
        (weapon == "none"))
    {
        return false;
    }
    if ((scripts\players\_weapons::isSpecialWeap(weapon)) &&
        (!getdvarint("surv_special_weapons_reloadable")))
    {
        // It is a special weapon, but they aren't reloadable
        return false;
    }
    return true;
}


/**
 * @brief Main logic for a player firing their weapons
 *
 * @returns nothing
 */
watchWeaponUsage()
{
    log("trace", "msg|in _weapons::watchWeaponUsage()||");

    self endon("death");
    self endon("disconnect");
    self endon("downed");
    self endon("spawned");      // end this instance before a respawn
    //level endon ( "game_ended" );

    self.firingWeapon = false;

    for ( ;; ) {
        self waittill ("begin_firing");

        weap = self getcurrentweapon();

        ent = undefined;

        self.hasDoneCombat = true;
        self.firingWeapon = true;

        if (weap == "saw_acog_mp") { // minigun
            self stoplocalsound("weap_minigun_spin_over_plr");
            self thread minigunQuake();
        } else if (weap == "skorpion_acog_mp") { // flamethrower
            self stoplocalsound("flamethrower_cooldown_plr");
            ent = spawn("script_model", self.origin);
            ent linkto(self);
            ent playLoopSound("flamethrower_fire_npc");
            self thread removeEntOnDeath(ent);
            self thread removeEntOnDisconnect(ent);
            self thread removeEntOnDowned(ent);

            self playsound("flamethrower_fire_npc");
            self playlocalsound("flamethrower_ignite_plr");
        } else if (weap == "g3_acog_mp") { // thundergun
            for (i=0; i<level.bots.size; i++) {
                bot = level.bots[i];
                if (!isdefined(bot)) {continue;}

                if (isalive(bot)) {
                    dis = distance(bot.origin, self.origin);
                    if (dis < 768) {
                        // @todo debug, don't rely on order of operations, be explicit with parens
                        // I think for special weapons, need to prestige, then buy raygun,
                        // then upgrade to thundergun to test this
                        dam = int((600-600 * dis / 768));
                        realdam = int(200 * (1 - (dis / 521)));
                        log("bug", sprintfLog("msg|thundegun damage||dis|$1:n||dam|$2:n||realdam|$3:n||", dis, dam, realdam));
                        if (realdam < 0) {realdam = 0;}
                        else if (realdam < 40) {realdam = 40;}

                        if (DistanceSquared(anglestoforward(self getplayerangles()), vectornormalize(bot.origin-self.origin)) < .7) {
                            self thread thunderBlast(dam, realdam, bot);
                        }
                    }
                }
            }
        }

        self waittill ("end_firing");

        if (weap == "saw_acog_mp") { // minigun
            self playlocalsound("weap_minigun_spin_over_plr");
        } else if (weap == "skorpion_acog_mp") { // flamethrower
            self stoplocalsound("flamethrower_ignite_plr");
            self playlocalsound("flamethrower_cooldown_plr");
            ent stopLoopSound("flamethrower_fire_npc");
            ent delete();
        }

        if (weap == self.primary) {
            self.persData.primaryAmmoClip = self getweaponammoclip(self.primary);
            self.persData.primaryAmmoStock = self getweaponammostock(self.primary);
        }
        else if (weap == self.secondary) {
            self.persData.secondaryAmmoClip = self getweaponammoclip(self.secondary);
            self.persData.secondaryAmmoStock = self getweaponammostock(self.secondary);
        }
        else if (weap == self.extra) {
            self.persData.extraAmmoClip = self getweaponammoclip(self.extra);
            self.persData.extraAmmoStock = self getweaponammostock(self.extra);
        }

        self.firingWeapon = false;
    }
}


/**
 * @brief Handles bot damage from the ThunderGun @todo needs testing for clarification
 *
 * @param dam integer Damage done to the bot
 * @param realdam integer Damage done to the bot
 * @param bot entity The bot that is taking damage
 *
 * @returns nothing
 */
thunderBlast(dam, realdam, bot)
{
    log("trace", "msg|in _weapons::thunderBlast()||");

    direction = (0,0,0);
    if (realdam >= bot.health) {
        // bot dies
        bot finishPlayerDamage(self, self, dam, 0, "MOD_PROJECTILE", "thundergun_mp", direction, direction, "none", 0);
    } else {
        // bot gets stunned, and damage is done
        bot thread scripts\bots\_bot::stun();
        // callback is _clients::Callback_PlayerDamage()
        bot thread [[level.callbackPlayerDamage]] (
            self,               // eInflictor entity The entity that causes the damage.(e.g. a turret)
            self,               // eAttacker entity The entity that is attacking.
            realdam,            // iDamage integer The amount of damage done
            0,                  // iDFlags integer Flags that are to be applied to the damage
            "MOD_EXPLOSIVE",    // sMeansOfDeath string The method of death
            "g3_acog_mp",       // sWeapon string The weapon used to inflict the damage
            self.origin,        // vPoint vector The position the damage is from
            direction,          // vDir vector The direction the damage is from
            "none",             // sHitLoc string The location of the hit
            0                   // psOffsetTime integer The time offset for the damage, ms
        );
    }
}


/**
 * @brief Removes flamethrower when player is downed
 *
 * @param ent entity The entity (flamethrower) to remove
 *
 * @returns nothing
 */
removeEntOnDowned(ent)
{
    log("trace", "msg|in _weapons::removeEntOnDowned()||");

    self endon( "end_firing" );
    self waittill("downed");
    ent stopLoopSound("flamethrower_fire_npc");
    ent delete();
}


/**
 * @brief Removes flamethrower when player dies
 *
 * @param ent entity The entity (flamethrower) to remove
 *
 * @returns nothing
 */
removeEntOnDeath(ent)
{
    log("trace", "msg|in _weapons::removeEntOnDeath()||");

    self endon( "end_firing" );
    self waittill("death");
    ent stopLoopSound("flamethrower_fire_npc");
    ent delete();
}


/**
 * @brief Removes flamethrower when player disconnects
 *
 * @param ent entity The entity (flamethrower) to remove
 *
 * @returns nothing
 */
removeEntOnDisconnect(ent)
{
    log("trace", "msg|in _weapons::removeEntOnDisconnect()||");

    self endon( "end_firing" );
    self waittill("death");
    ent delete();
}


/**
 * @brief Plays a rumble while the minigun fires
 *
 * @returns nothing
 */
minigunQuake()
{
    log("trace", "msg|in _weapons::minigunQuake()||");

    self endon( "death" );
    self endon( "downed" );
    self endon( "disconnect" );
    self endon( "end_firing" );

    while (1) {
        Earthquake( 0.2, .2, self.origin, 240);
        wait .1;
    }
}


/**
 * @brief Alerts zombies when a weapon if fired near them
 *
 * @returns nothing
 */
alertTillEndFiring()
{
    log("trace", "msg|in _weapons::alertTillEndFiring()||");

    self endon("death");
    self endon("disconnect");
    self endon("end_firing");

    while (1) {
        curWeapon = self getCurrentWeapon();
        if (curWeapon == "none") {return;}

        if (weaponIsBoltAction(curWeapon)) {
            scripts\bots\_bots::alertZombies(self.origin, 1024, 200, undefined);
        } else if (WeaponIsSemiAuto(curWeapon)) {
            scripts\bots\_bots::alertZombies(self.origin, 1024, 100, undefined);
        } else {
            scripts\bots\_bots::alertZombies(self.origin, 1024, 100, undefined);
        }
        wait .5;
    }
}

/// @deprecated
// watchWeaponSwitching()
// {
//     log("trace", "msg|in _weapons::watchWeaponSwitching()||");

//     self endon("death");
//     self endon("disconnect");
//     self endon("spawned");      // end this instance before a respawn

// }


/**
 * @brief Replaces a player's weapon with a new weapon
 *
 * Called to pick up a weapon, upgrade a weapon, or to give grenades from the shop.
 * It is not used when a player just switches between weapons in their current
 * inventory of weapons.
 *
 * @param type string One of primary|secondary|extra|grenade
 * @param weapon string The name of the weapon, i.e. g3_mp
 *
 * @returns nothing
 */
swapWeapons(type, weapon)
{
    log("trace", "msg|in _weapons::swapWeapons()||");

    switch (type) {
    case "primary":
        if (self.primary != "none")
            self takeweapon(self.primary);
            self giveWeapon(weapon);
            self giveMaxAmmo(weapon);
            self SwitchToWeapon(weapon);
            self.primary = weapon;
            self.persData.primary = self.primary;
            self.persData.primaryAmmoClip = WeaponClipSize(self.primary);
            self.persData.primaryAmmoStock = WeaponMaxAmmo(self.primary);
        break;
        case "secondary":
            if (self.secondary != "none")
            self takeweapon(self.secondary);
            self giveWeapon(weapon);
            self giveMaxAmmo(weapon);
            self SwitchToWeapon(weapon);
            self.secondary = weapon;
            self.persData.secondary = self.secondary;
            self.persData.secondaryAmmoClip = WeaponClipSize(self.secondary);
            self.persData.secondaryAmmoStock = WeaponMaxAmmo(self.secondary);
        break;
        case "extra":
            if (self.extra != "none")
            self takeweapon(self.extra);
            self giveWeapon(weapon);
            self giveMaxAmmo(weapon);
            self SwitchToWeapon(weapon);
            self.extra = weapon;
            self.persData.extra = self.extra;
            self.persData.extraAmmoClip = WeaponClipSize(self.extra);
            self.persData.extraAmmoStock = WeaponMaxAmmo(self.extra);
        break;
        case "grenade":
            self giveWeapon(weapon);
            self giveMaxAmmo(weapon);
        break;
    }
}


/**
 * @brief Determines if the weapon is a sniper rifle
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean True if the weapon is a sniper rifle, false otherwise
 */
isSniper(weapon)
{
    log("trace", "msg|in _weapons::isSniper()||");

    if (weapon == "m21_mp") {return true;}
    if (weapon == "aw50_mp") {return true;}
    if (weapon == "barrett_mp") {return true;}
    if (weapon == "dragunov_mp") {return true;}
    if (weapon == "m40a3_mp") {return true;}
    if (weapon == "remington700_mp") {return true;}
    if (weapon == "deserteagle_mp") {return true;}

    return false;
}

/**
 * @brief Determines if the weapon is a rifle
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean True if the weapon is a rifle, false otherwise
 */
isRifle(weapon)
{
    log("trace", "msg|in _weapons::isRifle()||");

    if (isSubStr(weapon, "ak47")) {return true;}
    if (isSubStr(weapon, "m4")) {return true;}
    if (isSubStr(weapon, "m16")) {return true;}
    if (isSubStr(weapon, "g3")) {return true;}
    if (isSubStr(weapon, "g36c")) {return true;}
    if (isSubStr(weapon, "mp44")) {return true;}

    return false;
}

/**
 * @brief Determines if the weapon is a shotgun
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean True if the weapon is a shotgun, false otherwise
 */
isShotgun(weapon)
{
    log("trace", "msg|in _weapons::isShotgun()||");

    if (isSubStr(weapon, "m1014")) {return true;}
    if (isSubStr(weapon, "winchester1200")) {return true;}
    if (weapon == "m60e4_acog_mp") {return true;}
    return true;

    return false;
}

/**
 * @brief Determines if the weapon is a light machine gun
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean True if the weapon is a light machine gun, false otherwise
 */
isLMG(weapon)
{
    log("trace", "msg|in _weapons::isLMG()||");

    if (isSubStr(weapon, "m60e4")) {return true;}
    if (isSubStr(weapon, "saw")) {return true;}
    if (isSubStr(weapon, "rpd")) {return true;}

    return false;
}

/**
 * @brief Determines if the weapon is a sub-machine gun
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean True if the weapon is a sub machine gun, false otherwise
 */
isSMG(weapon)
{
    log("trace", "msg|in _weapons::isSMG()||");

    if (isSubStr(weapon, "mp5")) {return true;}
    if (isSubStr(weapon, "ak74u")) {return true;}
    if (isSubStr(weapon, "p90")) {return true;}
    if (isSubStr(weapon, "uzi")) {return true;}
    if (isSubStr(weapon, "skorpion")) {return true;}

    return false;
}

/**
 * @brief Determines if the weapon is an explosive
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean True if the weapon is an explosive, false otherwise
 */
isExplosive(weapon)
{
    log("trace", "msg|in _weapons::isExplosive()||");

    if (weapon=="c4_mp") {return true;}
    if (weapon=="claymore_mp") {return true;}
    if (weapon=="tnt_mp") {return true;}
    if (weapon=="rpg_mp") {return true;}
    if (weapon=="at4_mp") {return true;}
    if (weapon=="frag_grenade_mp") {return true;}

    return false;
}


/**
 * @brief Determines if the weapon is a pistol
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean True if the weapon is a pistol, false otherwise
 */
isPistol(weapon)
{
    log("trace", "msg|in _weapons::isPistol()||");

    if (isSubStr(weapon, "beretta")) {return true;}
    if (isSubStr(weapon, "usp")) {return true;}
    if (isSubStr(weapon, "colt45")) {return true;}
    if (isSubStr(weapon, "deserteaglegold")) {return true;}

    return false;
}


/**
 * @brief Determines if the weapon is suppressed
 *
 * @param weapon string The name of the weapon
 *
 * @returns boolean True if the weapon is supressed, false otherwise
 */
isSilenced(weapon)
{
    log("trace", "msg|in _weapons::isSilenced()||");

    if (isSubStr(weapon, "_silencer_")) {return true;}

    return false;
}


/**
 * @brief Main logic for Claymore mine use
 *
 * @returns nothing
 */
watchClaymores()
{
    log("trace", "msg|in _weapons::watchClaymores()||");

    self endon("disconnect");
    self endon("spawned");      // end this instance before a respawn

    self.emplacedClaymores = [];
    while(1) {
        self waittill("grenade_fire", claymore, weapname);
        if ((weapname == "claymore") || (weapname == "claymore_mp")) {
            // player is starting to emplace the claymore
            self.emplacedClaymores[self.emplacedClaymores.size] = claymore;
            claymore.owner = self;
            claymore waitUntilExplosivesEmplaced();
            /// runtime error if claymore becomes undefined while waiting to be emplaced
            if (!isDefined(claymore)) {
                log("error", "msg|" + self.name + " claymore became undefined while waiting to be emplaced.||");
                continue;
            }
            claymore thread c4Damage();
            claymore thread claymoreDetonation();
            claymore thread playClaymoreEffects();
        }
    }
}


/**
 * @brief Shows the claymore's lasers beams
 *
 * @returns nothing
 */
playClaymoreEffects()
{
    log("trace", "msg|in _weapons::playClaymoreEffects()||");

    self endon("death");

    while (1) {
        origin = self getTagOrigin("tag_fx");
        angles = self getTagAngles("tag_fx");
        fx = spawnFx(level.claymoreFXid, origin, anglesToForward(angles), anglesToUp(angles));
        triggerfx(fx);

        self thread clearFXOnDeath(fx);

        originalOrigin = self.origin;

        while (1) {
            wait .25;
            if (self.origin != originalOrigin) {break;}
        }
        fx delete();
    }
}


/**
 * @brief Handle a claymore detonation
 *
 * @returns nothing
 */
claymoreDetonation()
{
    log("trace", "msg|in _weapons::claymoreDetonation()||");

    // self is claymore
    self endon("death");

    damageArea = spawn("trigger_radius", self.origin + (0,0,0-level.claymoreDetonateRadius), 0, level.claymoreDetonateRadius, level.claymoreDetonateRadius*2);
    self thread deleteEntityOnPlayerDeath(damageArea);

    while (1) {
        damageArea waittill("trigger", ent);

        if ((isDefined(ent.isBot)) && (ent.isBot) ||        // entity is a bot
            (isDefined(ent.isZombie)) && (ent.isZombie))    // entity is a player-zombie
        {
            // Don't detonate if player isn't in detection cone
            if (!ent shouldAffectClaymore(self)) {continue;}
            // Detonate if the player is in the damage cone
            if (ent damageConeTrace(self.origin, self) > 0) {break;}
        }
    }

    self playsound ("claymore_activated");

    wait level.claymoreDetectionGracePeriod;

    // Remove claymore from deployed array & detonate it
    self.owner thread rebuildPlayersEmplacedExplosives();
    self detonate();
}


/**
 * @brief Waits until the explosive is no longer moving
 *
 * @returns nothing
 */
waitUntilExplosivesEmplaced()
{
    log("trace", "msg|in _weapons::waitUntilExplosivesEmplaced()||");

    // self is claymore
    previousLocation = (0,0,0); // Init
    while (isDefined(self)) {
        if (self.origin == previousLocation) {break;}

        previousLocation = self.origin;
        wait .15;
    }
}


/**
 * @brief Deletes an entity when a player dies
 *
 * @param entity The entity to delete
 *
 * @returns nothing
 */
deleteEntityOnPlayerDeath(entity)
{
    log("trace", "msg|in _weapons::deleteEntityOnPlayerDeath()||");

    self waittill("death");
    wait .05;

    if (isdefined(entity)) {entity delete();}
}


/**
 * @brief Rebuilds a player's deployed explosives arrays
 *
 * @returns nothing
 */
rebuildPlayersEmplacedExplosives()
{
    log("trace", "msg|in _weapons::rebuildPlayersEmplacedExplosives()||");

    self endon("disconnect");
    self endon("death");

    wait(0.1);

    // C4
    temp = [];
    if (isDefined(self.emplacedC4)) {
        for (i=0; i<self.emplacedC4.size; i++) {
            if (isDefined(self.emplacedC4[i])) {
                temp[temp.size] = self.emplacedC4[i];
            }
        }
    }
    if (isDefined(self)) {self.emplacedC4 = temp;}

    // Claymores
    temp = [];
    if (isDefined(self.emplacedClaymores)) {
        for (i=0; i<self.emplacedClaymores.size; i++) {
            if (isDefined(self.emplacedClaymores[i])) {
                temp[temp.size] = self.emplacedClaymores[i];
            }
        }
    }
    if (isDefined(self)) {
        self.emplacedClaymores = temp;
    }

    // TNT
    temp = [];
    if (isDefined(self.emplacedTnt)) {
        for (i=0; i<self.emplacedTnt.size; i++) {
            if (isDefined(self.emplacedTnt[i]))
                temp[temp.size] = self.emplacedTnt[i];
        }
    }
    if (isDefined(self)) {
        self.emplacedTnt = temp;
    }
}


/**
 * @brief Is the zombie (self) in the Claymore's detection cone?
 *
 * @param claymore entity Should this entity trigger the claymore?
 *
 * @returns boolean indicating whether it should trigger the claymore or not
 */
shouldAffectClaymore(claymore)
{
    log("trace", "msg|in _weapons::shouldAffectClaymore()||");

    // fn from modwarfare
    pos = self.origin + (0,0,32);

    dirToPos = pos - claymore.origin;
    claymoreForward = anglesToForward(claymore.angles);

    dist = vectorDot(dirToPos, claymoreForward);
    if (dist < level.claymoreDetectionMinDist) {
        return false;
    }

    dirToPos = vectornormalize(dirToPos);

    dot = vectorDot(dirToPos, claymoreForward);
    return (dot > level.claymoreDetectionDot);
}


/**
 * @brief Removes deployed explosives when a player leaves the game
 *
 * @returns nothing
 */
deleteExplosivesOnDisconnect()
{
    log("trace", "msg|in _weapons::deleteExplosivesOnDisconnect()||");

    self endon("death");
    self endon("spawned");      // end this instance before a respawn

    self waittill("disconnect");

    wait .05;

    if (isDefined(self.emplacedC4)) {
        for (i=0; i<self.emplacedC4.size; i++) {            // C4
            if (isdefined(self.emplacedC4[i])) {self.emplacedC4[i] delete();}
        }
    }
    if (isDefined(self.emplacedClaymores)) {
        for (i=0; i<self.emplacedClaymores.size; i++) {     // Claymores
            if (isdefined(self.emplacedClaymores[i])) {self.emplacedClaymores[i] delete();}
        }
    }
    if (isDefined(self.emplacedTnt)) {
        for (i=0; i<self.emplacedTnt.size; i++) {           // TNT
            if (isdefined(self.emplacedTnt[i])) {self.emplacedTnt[i] delete();}
        }
    }
}


/**
 * @brief Main logic for employment of C4
 *
 * @returns nothing
 */
watchC4()
{
    log("trace", "msg|in _weapons::watchC4()||");

    self endon("death");
    self endon("disconnect");
    self endon("spawned");      // end this instance before a respawn

    self thread triggerThrowable();

    while(1) {
        self waittill("grenade_fire", throwable, weapname);
        if (weapname == "c4" || weapname == "c4_mp") {
            //if ( !self.emplacedC4.size )
            //  self thread watchC4AltDetonate();

            self.emplacedC4[self.emplacedC4.size] = throwable;
            throwable.owner = self;
            throwable.activated = false;

            throwable thread maps\mp\gametypes\_shellshock::c4_earthQuake(); // stock method
            //throwable thread c4Activate();
            throwable thread c4Damage();
            throwable thread playC4Effects();
        }
    }
}


/**
 * @brief Main logic for employment of TNT
 *
 * @returns nothing
 */
watchTnt()
{
    log("trace", "msg|in _weapons::watchTnt()||");

    /// We can't endon "death" because it gets emmitted whan a player-zombie is killed
    self endon("disconnect");
    self endon("spawned");      // end this instance before a respawn

    /// We only need to call this once, so we just do it in watchC4
    // self thread triggerThrowable();

    while(1) {
        self waittill( "grenade_fire", throwable, weapname );
        if ( weapname == "tnt" || weapname == "tnt_mp" ) {
            //if ( !self.emplacedTnt.size )
            //  self thread watchC4AltDetonate();

            self.emplacedTnt[self.emplacedTnt.size] = throwable;
            throwable.owner = self;
            throwable.activated = false;

            throwable thread maps\mp\gametypes\_shellshock::c4_earthQuake(); // stock method
            //throwable thread c4Activate();
            throwable thread c4Damage();
            throwable thread playC4Effects();
        }
    }
}


/**
 * @brief Triggers a throwable explosive: C4 & TNT
 *
 * @returns nothing
 */
triggerThrowable()
{
    log("trace", "msg|in _weapons::triggerThrowable()||");

    self endon("death");
    self endon("disconnect");
    self endon("spawned");      // end this instance before a respawn

    while (1) {
        self waittill("detonate");
        weap = self getCurrentWeapon();
        if ( weap == "c4_mp" ) {
            for ( i = 0; i < self.emplacedC4.size; i++ ) {
                c4 = self.emplacedC4[i];
                if ( isdefined(self.emplacedC4[i]) ) {
                        c4 thread waitAndDetonate(0.1);
                }
            }
            self.emplacedC4 = [];
            self notify ("detonated");
        } else if (weap == "tnt_mp") {
            for ( i = 0; i < self.emplacedTnt.size; i++ ) {
                tnt = self.emplacedTnt[i];
                if (isdefined(self.emplacedTnt[i])) {
                    tnt thread waitAndDetonate(0.1);
                }
            }
            self.emplacedTnt = [];
            self notify ("detonated");
        }
    }
}


/**
 * @brief Detonates C4 & TNT after a small delay
 *
 * @param delay float How long to wait before detonation, ms
 *
 * @returns nothing
 */
waitAndDetonate(delay)
{
    log("trace", "msg|in _weapons::waitAndDetonate()||");

    self endon("death");
    wait delay;

    self detonate();
}


/**
 * @brief Plays detonation effects for C4 & TNT
 *
 * @returns nothing
 */
playC4Effects()
{
    log("trace", "msg|in _weapons::playC4Effects()||");

    self endon("death");
    self waittill("activated");

    while (1) {
        org = self getTagOrigin("tag_fx");
        ang = self getTagAngles("tag_fx");

        fx = spawnFx(level.C4FXid, org, anglesToForward(ang), anglesToUp(ang));
        triggerfx(fx);
        self thread clearFXOnDeath(fx);

        originalOrigin = self.origin;
        while (1) {
            wait .25;
            if (self.origin != originalOrigin) {
                break;
            }
        }

        fx delete();
    }
}


/**
 * @brief Handles damage calls for Claymores, C4, and TNT
 *
 * @returns nothing
 */
c4Damage()
{
    log("trace", "msg|in _weapons::c4Damage()||");

    self endon( "death" );

    self setcandamage(true);
    self.maxhealth = 100000;
    self.health = self.maxhealth;

    attacker = undefined;

    while (1) {
        self waittill ("damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags);
        if (!isplayer(attacker)) {continue;}

        // don't allow people to destroy C4 on their team if FF is off
        if (self.owner != attacker && !getDvarInt("game_allowfriendlyfire")) {
            continue;
        }

        // ignore concussion grenades
        if (damage < 5) {continue;}

        break;
    }

    if (level.c4explodethisframe) {
        wait .1 + randomfloat(.4);
    } else {
        wait .05;
    }

    if (!isdefined(self)) {
        return;
    }

    level.c4explodethisframe = true;
    thread resetC4ExplodeThisFrame();

    if (isDefined(type) && (isSubStr(type, "MOD_GRENADE") || isSubStr(type, "MOD_EXPLOSIVE"))) {
        self.wasChained = true;
    }

    if (isDefined(iDFlags) && (iDFlags & level.iDFLAGS_PENETRATION)) {
        self.wasDamagedFromBulletPenetration = true;
    }

    self.wasDamaged = true;

    // "destroyed_explosive" notify, for challenges
    if (isdefined(attacker)   && isdefined(attacker.pers["team"]) &&
        isdefined(self.owner) && isdefined(self.owner.pers["team"]))
    {
        if (attacker.pers["team"] != self.owner.pers["team"]) {
            attacker notify("destroyed_explosive");
        }
    }

    self detonate(attacker);
}


/**
 * @brief Sets level.c4explodethisframe to false
 *
 * @returns nothing
 */
resetC4ExplodeThisFrame()
{
    log("trace", "msg|in _weapons::resetC4ExplodeThisFrame()||");

    wait .05;
    level.c4explodethisframe = false;
}


/**
 * @brief Deletes the fx on death
 *
 * @param fx entity The fx to delete
 *
 * @returns nothing
 */
clearFXOnDeath(fx)
{
    log("trace", "msg|in _weapons::clearFXOnDeath()||");

    fx endon("death");
    self waittill("death");
    fx delete();
}
