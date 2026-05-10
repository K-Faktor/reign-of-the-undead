/******************************************************************************
 *    Reign of the Undead, v2.x
 *
 *    Copyright (c) 2010-2026 Reign of the Undead Team.
 *    See AUTHORS.txt for a listing.
 *
 *    Permission is hereby granted, free of charge, to any person obtaining a copy
 *    of this software and associated documentation files (the "Software"), to
 *    deal in the Software without restriction, including without limitation the
 *    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *    sell copies of the Software, and to permit persons to whom the Software is
 *    furnished to do so, subject to the following conditions:
 *
 *    The above copyright notice and this permission notice shall be included in
 *    all copies or substantial portions of the Software.
 *
 *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *    SOFTWARE.
 *
 *    The contents of the end-game credits must be kept, and no modification of its
 *    appearance may have the effect of failing to give credit to the Reign of the
 *    Undead creators.
 *
 *    Some assets in this mod are owned by Activision/Infinity Ward, so any use of
 *    Reign of the Undead must also comply with Activision/Infinity Ward's modtools
 *    EULA.
 ******************************************************************************/

/** @file modelCentroidFinder.gsc Runs a UI that helps you find the centroid of a xmodel
 *          depends on being in developer mode, for line() availability
 */

#include scripts\include\utility;
#include scripts\include\matrix;
#include scripts\include\hud;


/** developerHoursWastedHere: 66
 *
 * The goal is to implement *smooth* rotation of a model about an axis at an *arbitrary* point.
 * In this case, the arbitrary point being the model's centroid, so we could spin it nicely
 * within its own volume.
 * 
 * No success.
 *
 * We tried straight rotations about a point with stock methods (rotateYaw(), rotateRoll(), etc)
 * at various agular velocities.  Jerky.  Same with rotateTo().  Tried linking the model to a separate
 * rotator entity.  Jerky. Even tried composite motion, where we have two independent motions that
 * sum to equal the desired motion (rotate about natural weapon origin, and rotate weapon natural origin
 * about a circle with a radius equal of the magnitude of the offset vector).  Jerky. We tried rotating
 * about other tags/bones in a weapon. Jerky.
 * 
 * The internal sine and cosine functions output sufficient precision, so that isn't the issue.
 *
 * I guess what we need is a CoD4 method that is internally threaded to tween a movement from A to B
 * along a circular path of radius r.
 *
 * The sad reality is the CoD4 (IW3) engine just sucks balls at rotating models about anything other than
 * the weapon's natural origin.
 *
 * Update the wasted hours counter above as a warning to all those foolish enough to tread here.
 */


init(model, weaponName, slot)
{
    log("trace", "msg|in modelCentroidFinder::init()||");
    // precacheMenu("centroid");

    while (level.activePlayers == 0) {
        wait 0.5;
    }
    level.devPlayer = level.players[0];
    level.origin = (0,0,0); // init
    level.centroid_pivot = spawn("script_origin", level.origin);

    initHud();
    // load UMI Editor shortcuts
    level.devPlayer scripts\players\_players::execClientCommand( "exec scripts/tools/_mcf_shortcuts.cfg" );
    level.isRotating = false;

    level.devPlayer thread watchCentroidFinderMenuResponses();
    findCentroidManually(model, weaponName, slot);
}


/**
 * @brief Test smooth rotation about actual tags.
 *
 *        Shocker, it dowsn't work either.
 *
 * @param model string The name of the weapon model, like weapon_desert_eagle_gold
 * @param weaponName string The name of the weapon, like deserteaglegold_mp
 * @param slot string The weapon slot [primary|secondary]
 *
 * @returns nothing
 */
testTagSpin(model, weaponName, slot)
{
    log("trace", "msg|in modelCentroidFinder::testTagSpin()||");

    commonTags = [];
    commonTags[0] = "tag_weapon";
    commonTags[1] = "tag_flash";
    commonTags[2] = "tag_brass";

    pistolTags = [];
    pistolTags[0] = "j_pistol_grip";    // in both pistols, in neither long gun

    rifleTags = [];
    rifleTags[0] = "tag_clip";          // in both long guns, in neither pistol

    weapTags = [];
    for (i=0; i<commonTags.size; i++) {
        t = commonTags[i];
        if (isDefined(level.temp getTagOrigin(t))) {
            weapTags[weapTags.size] = t;
        }
    }
    if (slot == "primary") {
        for (i=0; i<rifleTags.size; i++) {
            t = rifleTags[i];
            if (isDefined(level.temp getTagOrigin(t))) {
                weapTags[weapTags.size] = t;
            }
        }
    }
    if (slot == "secondary") {
        for (i=0; i<pistolTags.size; i++) {
            t = pistolTags[i];
            if (isDefined(level.temp getTagOrigin(t))) {
                weapTags[weapTags.size] = t;
            }
        }
    }

    for (i=0; i<weapTags.size; i++) {
        t = weapTags[i];
        log("dev", "msg|Available tags||name| " + t + "||origin|" + level.temp getTagOrigin(t) + "||");   // j_gun
    }

    level.origin = level.temp getTagOrigin("tag_weapon");
    // level.origin = level.temp getTagOrigin("j_pistol_grip");
    pivot = spawn("script_origin", level.origin);
    // pivot = spawn("script_origin", level.temp getTagOrigin("tag_weapon"));

    level.temp unlink();
    level.temp linkTo(pivot);

    pivot thread doContinuousRotate((0,0,1));   // or your smooth version
}


/**
 * @brief Main testing logic
 *
 * @param model string The name of the weapon model, like weapon_desert_eagle_gold
 * @param weaponName string The name of the weapon, like deserteaglegold_mp
 * @param slot string The weapon slot [primary|secondary]
 *
 * @returns nothing
 */
findCentroidManually(model, weaponName, slot)
{
    log("trace", "msg|in modelCentroidFinder::findCentroidManually()||");

    position = (640, 1180, 0); //  spec'd for mp_surv_gold_rush

    // precachemodel(model);
    struct = spawnstruct();
    level.mys_wep[level.mys_wep.size] = struct;
    struct.model = model;
    struct.weaponName = weaponName;
    struct.slot = slot;

    offset = (0, 0, 55);
    origin = position + offset;
    log("warn", "msg|position: " + position + " origin: " + origin + "||");
    // === NEW: compute centroid offset (model-local space) ===
    level.temp = spawn("script_model", origin);
    level.temp setmodel(model);
    level.temp.angles = (0, 0, 0);               // default orientation
    level.temp.origin = origin;
    level.modelNativeOrigin = level.temp.origin;

    level.direction = vectorNormalize((level.temp.origin + (100, 0, 0)) - level.temp.origin); // get x direction
    level.temp thread devDrawLocalCoordinateSystem(level.direction, level.temp.origin);
    testTagSpin(model, weaponName, slot);

    wait(0.05);                            // give engine a frame to update bounds
}


/**
 * @brief Toggles continuous rotation around the given local axis for centroid tuning
 *
 * @param axis vector The unit vector to rotate about
 *
 * @returns nothing
 */
rotateAboutAxis(axis)
{
    log("trace", "msg|in modelCentroidFinder::rotateAboutAxis()||");

    if (!isDefined(level.temp) || !isDefined(level.origin))
        return;

    if (isDefined(level.isRotating) && level.isRotating) {
        // stopping
        level.isRotating = false;
        level notify("stop_centroid_rotation");
        wait 0.05;
        level.temp unlink();
        // reset model to original position
        level.temp.angles = level.direction;
        level.temp.origin = level.modelNativeOrigin;
        // reset centroid pivot
        level.centroid_pivot.angles = level.direction;
        level.centroid_pivot.origin = level.origin;
        log("warn", "msg|Stopped rotation||");
    } else {
        level.isRotating = true;
        level.centroid_pivot.origin = level.origin;
        level.temp linkTo(level.centroid_pivot);

        level.centroid_pivot thread doContinuousRotate(axis);  // rotate around X
        // level.temp thread doContinuousCompositeRotate(axis);
    }
}


/**
 * @brief Smooth composite rotation around a custom centroid
 *
 *   1. Rotate the weapon around its own natural origin (this part is always buttery smooth)
 *   2. Simultaneously orbit the weapon's origin around your chosen centroid
 *   Expected Result: perfect rotation around the centroid with zero engine snapping.
 *   Real Result: LOL, LMFAO even.
 *
 *   The math works, but the CoD4 engine is foiling us.
 *
 * @param axis vector The unit vector to rotate about
 *
 * @returns nothing
 */
doContinuousCompositeRotate(axis)
{
    log("trace", "msg|in modelCentroidFinder::doContinuousCompositeRotate()||");

    self endon("death");
    level endon("stop_centroid_rotation");

    level.isRotating = true;

    centroid = level.origin;
    model    = level.temp;
    offset   = model.origin - centroid;

    log("dev", "msg|grokDebug||initialOffset|" + offset + "||len|" + length(offset) + "||");

    rotationSpeed = 90; //90;      // adjust to taste
    angleStep     = rotationSpeed * 0.05;
    angleStep2 = angleStep;

    model unlink();
    model.angles = level.direction;

    frame = 0;
    radiansFactor = 1;   // degrees mode confirmed
    c = cos(angleStep * radiansFactor);
    s = sin(angleStep * radiansFactor);

    log("dev", "msg|START COMPOSITE SMOOTH||c|" + c + "||s|" + s + "||");

    while (level.isRotating) {
        // === Orbit (position) ===
        if (axis[2] != 0) {  // Z Yaw - most common
            newX = offset[0] * c - offset[1] * s;
            newY = offset[0] * s + offset[1] * c;
            offset = (newX, newY, offset[2]);
        } else if (axis[1] != 0) { // Y = Pitch
            newX = offset[0] * c + offset[2] * s;
            newZ = -1*offset[0] * s + offset[2] * c;
            offset = (newX, offset[1], newZ);
        } else if (axis[0] != 0) { // X = Roll
            newY = offset[1] * c - offset[2] * s;
            newZ = offset[1] * s + offset[2] * c;
            offset = (offset[0], newY, newZ);
        }

        model.origin = centroid + offset;

        // === Local weapon spin (smooth part) ===
        if (axis[2] != 0) {
            model rotateYaw(angleStep2, 0.05);
        } else if (axis[1] != 0) {
            model rotatePitch(angleStep2, 0.05);
        } else if (axis[0] != 0) {
            model rotateRoll(angleStep2, 0.05);
        }

        wait 0.05;
        frame++;
    }
}


/**
 * @brief Continuous rotation thread around a given axis
 *
 * @param axis   Vector (1,0,0) = X, (0,1,0) = Y, (0,0,1) = Z
 *
 * @returns nothing
 */
doContinuousRotate(axis)
{
    log("trace", "msg|in modelCentroidFinder::doContinuousRotate()||");

    self endon("death");
    level endon("stop_centroid_rotation");

    frames = 10;
    self.angles = (0, 0, 0);
    theta = scripts\players\_turrets::angleBetweenTwoVectors(level.xPrime, level.xPrime * -1);
    rotationSpeed = 30;   // degrees per second - feels good for tuning (adjust as needed)
    while (level.isRotating) {
        // === Local weapon spin (smooth part) ===
        if (axis[2] != 0) {
            self rotateYaw(360, 6.8);
        } else if (axis[1] != 0) {
            self rotatePitch(360, 6.8);
        } else if (axis[0] != 0) {
            self rotateRoll(360, 6.8);
        }        
        // self rotateYaw(360, 6.8);   // One full rotation every 6.8 seconds
        wait 6.8;
    }
}



//
// Code the runs the centroidFinder inetrface
//

/**
 * @brief Watches the development menu for commands, then processes them
 *
 * NOTE: We cannot actually use a menu here, just the shortcut keys.  I tried--
 *       even with a modest menu, it makes us exceed the limit of 640 menu items.
 *
 * @returns nothing
 */
watchCentroidFinderMenuResponses()
{
    log("trace", "msg|in modelCentroidFinder::watchCentroidFinderMenuResponses()||");

    self endon("disconnect");
    // threaded on each admin player

    while (!(isDefined(level.developerMode))) {wait 1;} // wait until developerMode is defined
    if (!(level.developerMode)) {return;} // don't listen for commands if developerMode is off

    log("warn", "msg|waiting for menu responses||");

    while (1) {
        self waittill("menuresponse", menu, response);

        log("warn", "msg|menu response||menu|" + menu + "||response|" + response + "||");

        switch(response)
        {
        /** Development */
        case "mcf_increment_x":
            xIncrement();
            break;
        case "mcf_increment_y":
            yIncrement();
            break;
        case "mcf_increment_z":
            zIncrement();
            break;
        case "mcf_decrement_x":
            xDecrement();
            break;
        case "mcf_decrement_y":
            yDecrement();
            break;
        case "mcf_decrement_z":
            zDecrement();
            break;
        case "mcf_rotate_x":
            rotateAboutAxis((1, 0, 0));
            break;
        case "mcf_rotate_y":
            rotateAboutAxis((0, 1, 0));
            break;
        case "mcf_rotate_z":
            rotateAboutAxis((0, 0, 1));
            break;
        default:
            // Do nothing
            break;
        } // end switch(response)
        updateHud();
        wait 0.05;
    } // End while(1)
}


/**
 * @brief Initializes the HUD
 *
 * @returns nothing
 */
initHud()
{
    log("trace", "msg|in modelCentroidFinder::initHud()||");

    // Set up HUD elements
    verticalOffset = 80;

    level.shortcutsHud = newClientHudElem(level.devPlayer);
    level.shortcutsHud.elemType = "font";
    level.shortcutsHud.font = "default";
    level.shortcutsHud.fontscale = 1.4;
    level.shortcutsHud.x = -160;
    level.shortcutsHud.y = 20;
    level.shortcutsHud.hideWhenInMenu = true;
    level.shortcutsHud.archived = false;
    level.shortcutsHud.alignX = "right";
    level.shortcutsHud.alignY = "middle";
    level.shortcutsHud.horzAlign = "center";
    level.shortcutsHud.vertAlign = "top";
    level.shortcutsHud.color = (0,1,0);
    level.shortcutsHud.alpha = 1;
    level.shortcutsHud.glowColor = (0,0,0);
    level.shortcutsHud.glowAlpha = 1;
    level.shortcutsHud.label = &"ZOMBIE_CENTROID_SHORTCUTS";

    level.coordXHud = newClientHudElem(level.devPlayer);
    level.coordXHud.elemType = "font";
    level.coordXHud.font = "default";
    level.coordXHud.fontscale = 1.4;
    level.coordXHud.x = -16;
    level.coordXHud.y = verticalOffset + 18*2;
    level.coordXHud.glowAlpha = 1;
    level.coordXHud.hideWhenInMenu = true;
    level.coordXHud.archived = false;
    level.coordXHud.alignX = "right";
    level.coordXHud.alignY = "middle";
    level.coordXHud.horzAlign = "right";
    level.coordXHud.vertAlign = "top";
    level.coordXHud.alpha = 1;
    level.coordXHud.glowColor = (0,0,1);
    level.coordXHud.label = &"ZOMBIE_COORD_X";
    level.coordXHud setValue(level.origin[0]);

    level.coordYHud = newClientHudElem(level.devPlayer);
    level.coordYHud.elemType = "font";
    level.coordYHud.font = "default";
    level.coordYHud.fontscale = 1.4;
    level.coordYHud.x = -16;
    level.coordYHud.y = verticalOffset + 18*3;
    level.coordYHud.glowAlpha = 1;
    level.coordYHud.hideWhenInMenu = true;
    level.coordYHud.archived = false;
    level.coordYHud.alignX = "right";
    level.coordYHud.alignY = "middle";
    level.coordYHud.horzAlign = "right";
    level.coordYHud.vertAlign = "top";
    level.coordYHud.alpha = 1;
    level.coordYHud.glowColor = (0,0,1);
    level.coordYHud.label = &"ZOMBIE_COORD_Y";
    level.coordYHud setValue(level.origin[1]);

    level.coordZHud = newClientHudElem(level.devPlayer);
    level.coordZHud.elemType = "font";
    level.coordZHud.font = "default";
    level.coordZHud.fontscale = 1.4;
    level.coordZHud.x = -16;
    level.coordZHud.y = verticalOffset + 18*4;
    level.coordZHud.glowAlpha = 1;
    level.coordZHud.hideWhenInMenu = true;
    level.coordZHud.archived = false;
    level.coordZHud.alignX = "right";
    level.coordZHud.alignY = "middle";
    level.coordZHud.horzAlign = "right";
    level.coordZHud.vertAlign = "top";
    level.coordZHud.alpha = 1;
    level.coordZHud.glowColor = (0,0,1);
    level.coordZHud.label = &"ZOMBIE_COORD_Z";
    level.coordZHud setValue(level.origin[2]);
}


/**
 * @brief Updates the HUD as we shift the offset position
 *
 * @returns nothing
 */
updateHud()
{
    log("trace", "msg|in modelCentroidFinder::updateHud()||");

    // log("dev", "msg|in modelCentroidFinder::updateHud()||");

    level.coordXHud setValue(level.origin[0]);
    level.coordYHud setValue(level.origin[1]);
    level.coordZHud setValue(level.origin[2]);    
}

// shift the drawn coord system by half a unit
xIncrement() {level.origin += (0.5, 0, 0);}
yIncrement() {level.origin += (0, 0.5, 0);}
zIncrement() {level.origin += (0, 0, 0.5);}
xDecrement() {level.origin -= (0.5, 0, 0);}
yDecrement() {level.origin -= (0, 0.5, 0);}
zDecrement() {level.origin -= (0, 0, 0.5);}


/**
 * @brief Draws a local right-handed coordinate system
 *
 * @param direction vector The unit vector specifing the direction for the x-axis
 * @param origin vector The position to place the origin at. Uses bot.origin if \corigin is undefined.
 *
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
devDrawLocalCoordinateSystem(direction, origin)
{
    log("trace", "msg|in _bot::devDrawLocalCoordinateSystem()||");

    log("warn", "msg|direction: " + direction + " origin: " + origin + "||");
    self endon("hide_coordinate_system");

    if (!isDefined(origin)) {origin = (0, 0, 0);}

    // standard basis vectors in world coordinate system
    i = (1,0,0);
    j = (0,1,0);
    k = (0,0,1);

    // [i|j|k]Prime are the basis vectors for the rotated coordinate system
    iPrime = direction;
    kPrime = vectorNormalize((origin + (0,0,25)) -  origin);
    kPrime = kPrime * -1;
    u = zeros(3,1);
    scripts\include\matrix::setValue(u,1,1,iPrime[0]);  // x
    scripts\include\matrix::setValue(u,2,1,iPrime[1]);  // y
    scripts\include\matrix::setValue(u,3,1,iPrime[2]);  // z
    v = zeros(3,1);
    scripts\include\matrix::setValue(v,1,1,kPrime[0]);  // x
    scripts\include\matrix::setValue(v,2,1,kPrime[1]);  // y
    scripts\include\matrix::setValue(v,3,1,kPrime[2]);  // z
    // i cross -k to get the real j
    jPrimeM = matrixCross(u, v);
    jPrime = vectorNormalize((value(jPrimeM,1,1), value(jPrimeM,2,1), value(jPrimeM,3,1)));
    w = zeros(3,1);
    scripts\include\matrix::setValue(w,1,1,jPrime[0]);  // x
    scripts\include\matrix::setValue(w,2,1,jPrime[1]);  // y
    scripts\include\matrix::setValue(w,3,1,jPrime[2]);  // z
    // now i cross j to get the real k
    kPrimeM = matrixCross(u, w);
    kPrime = vectorNormalize((value(kPrimeM,1,1), value(kPrimeM,2,1), value(kPrimeM,3,1)));

    log("warn", "msg|origin: " + origin + " x-end: " + (origin + (iPrime * 30)) + "||");
    log("warn", "msg|origin: " + origin + " y-end: " + (origin + (jPrime * 30)) + "||");
    log("warn", "msg|origin: " + origin + " z-end: " + (origin + (kPrime * 30)) + "||");

    level.origin = origin;
    level.xPrime = iPrime;
    level.yPrime = jPrime;
    level.zPrime = kPrime;

    while (1) {
        line(level.origin, level.origin + (iPrime * 30), decimalRgbToColor(255,0,0), false, 25);
        line(level.origin, level.origin + (jPrime * 30), decimalRgbToColor(0,255,0), false, 25);
        line(level.origin, level.origin + (kPrime * 30), decimalRgbToColor(0,0,255), false, 25);
        updateHud();
        wait 0.05;
    }
}
