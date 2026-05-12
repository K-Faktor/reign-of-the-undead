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
#include scripts\include\matrix;
#include scripts\include\hud;

// called from scripts\gamemodes\gamemodes::init()
init()
{
    log("trace", "msg|in _mysterybox::init()||");

    level.mys_wep = [];
    addMysWep("weapon_ak47", "ak47_mp", "primary");
    addMysWep("weapon_m4gre_sp_silencer_reflex", "m4_acog_mp", "primary");
    addMysWep("weapon_m40a3", "m40a3_mp", "primary");
    addMysWep("weapon_benelli_super_90", "m1014_grip_mp", "primary");
    addMysWep("weapon_m14_scout_mp", "m14_mp", "primary");
    addMysWep("weapon_ak74u", "ak74u_mp", "primary");
    addMysWep("weapon_g36", "g36c_acog_mp", "primary");
    addMysWep("weapon_m16_mp", "m16_mp", "primary");
    addMysWep("weapon_m60", "m60e4_mp", "primary");
    addMysWep("weapon_p90", "p90_acog_mp", "primary");

    addMysWep("weapon_usp", "usp_mp", "secondary");
    addMysWep("weapon_beretta" , "beretta_mp", "secondary");
    addMysWep("weapon_colt1911_silencer" , "colt45_silencer_mp", "secondary");
    addMysWep("weapon_crossbow_1" , "crossbow_mp", "secondary");
    addMysWep("weapon_desert_eagle_gold", "deserteaglegold_mp", "secondary");
    addMysWep("weapon_mini_uzi", "uzi_mp", "secondary");

    addMysWep("weapon_mw2_f2000_wm", "m14_acog_mp", "primary");
    addMysWep("weapon_spas12", "m1014_reflex_mp", "primary");
    addMysWep("weapon_aug", "rpd_acog_mp", "primary");
    addMysWep("mw2_aa12_worldmodel", "m60e4_acog_mp", "primary");
    addMysWep("worldmodel_bo_minigun", "saw_acog_mp", "primary");
    addMysWep("weapon_tesla", "ak74u_acog_mp", "primary");

    addMysWep("mw2_mp5k_worldmodel", "mp5_acog_mp", "secondary");

    addMysWep("weapon_raygun", "barrett_acog_mp", "primary"); // fixed: barrett, not barret
    addMysWep("weapon_flamethrower", "skorpion_acog_mp", "primary");
    addMysWep("mw2_intervention_wm", "deserteagle_mp", "primary");

    // findCentroidManually("weapon_desert_eagle_gold", "deserteaglegold_mp", "secondary");
    // scripts\tools\modelCentroidFinder::init("weapon_desert_eagle_gold", "deserteaglegold_mp", "secondary");
    // log("warn", "msg|added msytery box weapons. level.ammoStockType: " + level.ammoStockType + "||");
}


/**
 * @brief Precaches mystery weapon models & builds level.mys_wep[] array.
 *
 * @param model string The name of the weapon model, like weapon_desert_eagle_gold
 * @param weaponName string The name of the weapon, like deserteaglegold_mp
 * @param slot string The weapon slot [primary|secondary]
 * 
 * @returns nothing
 */
addMysWep(model, weaponName, slot)
{
    log("trace", "msg|in _mysterybox::addMysWep()||");

    precachemodel(model);
    struct = spawnstruct();
    level.mys_wep[level.mys_wep.size] = struct;
    struct.model = model;
    struct.weaponName = weaponName;
    struct.slot = slot;
}


/**
 * @brief Build a crate for testing the mystery box, as not
 *        all amps will a have a small green crate.
 *
 * @returns nothing
 */
buildTestCrate()
{
    log("trace", "msg|in _mysterybox::buildTestCrate()||");

    level.ammoStockType = "weapon";
    level.ammoStockTypeForced = "weapon"; // force it, for testing
    position = (0, 0, 0); // mp_surv_testmap
    if (level.currentMap == "mp_surv_gold_rush") {position = (640, 1180, 0);}
    weaponupgrade = spawn("script_model", position);
    if (isDefined(weaponupgrade)) {
        weaponupgrade.angles = (0, 0, 0);
        weaponupgrade setModel("com_plasticcase_green_big"); // single large green crate

        // spawn a solid trigger_radius to simulate xmodel actually being solid
        level.solid = spawn("trigger_radius", (0, 0, 0), 0, 21, 27 );
        level.solid.origin = weaponupgrade.origin;
        level.solid.angles = weaponupgrade.angles;
        level.solid setContents(1);

        level scripts\players\_usables::addUsable(weaponupgrade, "ammobox", "Press [USE] for a weapon! (^1"+level.dvar["surv_waw_costs"]+"^7)", 96);
        createTeamObjpoint(weaponupgrade.origin + (0,0,72), "hud_weapons", 1);
    }
    return weaponupgrade;
}


/** @deprecated
 * @brief Precaches weapon models.  Unused, these are precached in addMysWep()
 *
 * @returns nothing
 */
precache()
{
    log("trace", "msg|in _mysterybox::precache()||");

    // @fixme  previously, these weren't precached, as precache() was never called
    // but they ring a bell.  I think they were special weapons,
    // like weapon_saw_new_rescue was a Stihl Concrete Saw.
    // We *should* remove the precaching from addMysWep, to this method, before
    // relocating the precaching close to bootstrap()
    precachemodel("weapon_desert_eagle_silver");
    precachemodel("weapon_saw_new_rescue");
    precachemodel("weapon_m67_grenade");
}


/**
 * @brief Entry point for dev testing of mystery box
 *
 * @returns nothing
 */
testMysteryBox()
{
    log("trace", "msg|in _mysterybox::testMysteryBox()||");

    crate = buildTestCrate();
}


/**
 * @brief Main mystery box sequence for a player.
 *        Spawns a floating weapon model, makes it hover & 'scroll' up.
 *        Rapidly cycles through available weapons, then cleans up.
 *
 * Called from _usables when (self.curEnt.type == "ammobox") &&
 *                           (level.ammoStockType == "weapon")
 *
 * @param box entity The mystery box trigger/chest entity.
 *
 * @returns nothing
 */
mysteryBox(box)
{
    log("trace", "msg|in _mysterybox::mysteryBox()||");

    trace = bulletTrace(box.origin + (0,0,72), box.origin + (0,0,-100), false, box);
    topPos = trace["position"];
    newPos = topPos + (0, 0, 17);
    weapon = spawn("script_model", newPos);

    // log("dev", "msg|box.origin|" + box.origin + "||topPos|" + topPos + "||" + "||newPos|" + newPos + "||");
    weapon.angles = (0, box.angles[1] + 0, 0);
    self.box_weapon = weapon;
    weapon hide();
    weapon showToPlayer(self);
    self playLocalSound("zom_mystery");
    // Hover up
    weapon moveZ(32, 2.4);
    /**
     * N.B. Before you try to implement rotating weapons about an axis at an arbitrary point,
     * such the weapon's centroid or a tag, read the warning at the top of
     * scripts/tools/modelCentroidFinder.gsc
     */

    // Fake rolling animation by cycling weapon models
    lastIndex = undefined;
    // ~3.5 seconds of rolling
    for (i=0; i<14; i++) {
        if (!isDefined(self.box_weapon)) {break;} // box_weapon is deleted when the user takes a weapon
        self.box_weapon.done = false;
        lastIndex = weapon createRandomItem(self, lastIndex);
        self.box_weapon.done = true;
        wait 0.25;
    }
    wait 0.05;

    // Auto-cleanup if player doesn't take the weapon in time
    weapon thread deleteOverTime(7);
}


/**
 * @brief Changes the mystery box model to a random weapon the player doesn't already own.
 *
 * @param player entity The player using the box.
 * @param lastIndex integer Index of the previously shown weapon (to prevent repeats).
 *
 * @returns integer The index of the weapon chosen this frame.
 */
createRandomItem(player, lastIndex)
{
    log("trace", "msg|in _mysterybox::createRandomItem()||");

    if ((!isDefined(level.mys_wep)) || (level.mys_wep.size <= 0)) {
        return 0;
    }

    attempts = 0;
    while (attempts < 40) {  // Safety to prevent infinite loop
        index = randomInt(level.mys_wep.size);

        // Don't show the exact same weapon twice in a row
        if ((isDefined(lastIndex)) && (index == lastIndex)) {
            attempts++;
            continue;
        }

        wep = level.mys_wep[index];

        // Skip weapons the player already has
        if (((isDefined(player.primary))   && (wep.weaponName == player.primary)) ||
            ((isDefined(player.secondary)) && (wep.weaponName == player.secondary)))
        {
            attempts++;
            continue;
        }

        // Found a good one
        self setModel(wep.model);
        self.weaponName = wep.weaponName;
        self.slot = wep.slot;

        return index;
    }

    // Fallback: just pick any weapon that isn't the last one shown
    for (i=0; i<level.mys_wep.size; i++) {
        if ((isDefined(lastIndex)) && (i == lastIndex)) {
            continue;
        }

        wep = level.mys_wep[i];
        self setModel(wep.model);
        self.weaponName = wep.weaponName;
        self.slot = wep.slot;
        return i;
    }

    return 0;
}


/**
 * @brief Deletes and item after a delay
 *
 * @param time integer Seconds to wait before deleting an item, if it still exists
 *
 * @returns nothing
 */
deleteOverTime(time)
{
    log("trace", "msg|in _mysterybox::deleteOverTime()||");

    self endon("death");
    wait time;
    if (isDefined(self)) {
        self delete();
    }
}
