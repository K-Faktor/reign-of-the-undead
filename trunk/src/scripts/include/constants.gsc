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
/**
 * @file constants.gsc Constants and enums
 */

init()
{
    // quality:ignore_trace
    
    level.MAX_INT = 2147483647; // 32-bit ints

    /// bot movement modes
    level.BOT_WANDERING = 0;

    /// bot motion types
    level.BOT_WALK = 0;
    level.BOT_RUN = 1;
    level.BOT_CLIMB = 2;

    level.BOT_MOVE_DISTANCE = 37; // about 18 inches movement resolution
    level.MANTLE_MIN_Z = 15;
    level.MANTLE_MAX_Z = 85;
    level.MANTLE_MAX_DISTANCE = 50;

    /// waypoint path type enums
    level.PATH_NORMAL = 0;
    level.PATH_MANTLE = 1;
    level.PATH_LADDER = 2;
    level.PATH_CLAMPED = 3;
    level.PATH_FALL = 4;
    level.PATH_TELEPORT = 5;
    level.PATH_JUMP = 6;
    level.PATH_MANTLE_OVER = 7;

    /// special speeds
    level.MANTLE_SPEED = 120;
    level.LADDER_SPEED = 120;
}
