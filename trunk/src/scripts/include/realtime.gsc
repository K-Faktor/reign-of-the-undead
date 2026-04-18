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
 * @brief Initializes our internal epoch with data injected into command line
 *
 * Lets us approximate the real time for server_mp log entries.
 * Expect it to drift more and more the longer it has been since you restarted
 * the CoD4 server
 *
 * @return Nothing
 */
initRealTime()
{
    // Base Unix timestamp (seconds since 1970-01-01 UTC)
    level.realTimeBase = getDvarInt("real_time_base");
    if (level.realTimeBase <= 0) {
        // No good solution for the case of missing time data...
        // level.realTimeBase = 1775519760;        // fallback - update this when you restart
    }

    // Timezone offset in hours to *add* to UTC (e.g. -5 = US CDT, 0 = UTC)
    // N.B. getDvarInt defaults to 0 for any missing dvar's, which here means UTC
    level.realTimeOffset = getDvarInt("real_time_offset");  

    // Timezone name for logging
    level.realTimeTZ = getDvar("real_time_tz_str");
    if (level.realTimeTZ == "")
        level.realTimeTZ = "UTC London";

    level.realTimeServerStart = getTime() / 1000;   // seconds elapsed since this RotU server started
}


/**
 * @brief Gets the Unix epoch
 *
 * @returns int The Unix epoch, in seconds
 */
getRealUnixTime()
{
    if (!isDefined(level.realTimeBase))
        initRealTime();

    // Force integer math to avoid float precision issues
    baseTime = int(level.realTimeBase);
    serverSeconds = int(getTime() / 1000);                    // force to int
    startSeconds = int(level.realTimeServerStart);

    return baseTime + (serverSeconds - startSeconds) + (level.realTimeOffset * 3600);
}

/**
 * @brief Gets the current timestamp, as a formatted string
 *
 * @returns formatted string: "2026-04-06 18:56:22 CDT"
 */
getRealDateTimeString()
{
    if (!isDefined(level.realTimeBase))
        initRealTime();

    secs = getRealUnixTime();           // This is now guaranteed to be int

    // Extract time (hours, minutes, seconds)
    hours   = int(secs / 3600) % 24;
    minutes = int(secs / 60) % 60;
    seconds = int(secs % 60);

    // Date calculation (days since 1970-01-01)
    days = int(secs / 86400);

    year = 1970;
    while (days >= 365 + isLeapYear(year))
    {
        days -= 365 + isLeapYear(year);
        year++;
    }

    monthDays = [];
    monthDays[0] = 31;
    monthDays[1] = 28;
    monthDays[2] = 31;
    monthDays[3] = 30;
    monthDays[4] = 31;
    monthDays[5] = 30;
    monthDays[6] = 31;
    monthDays[7] = 31;
    monthDays[8] = 30;
    monthDays[9] = 31;
    monthDays[10] = 30;
    monthDays[11] = 31;
    if (isLeapYear(year))
        monthDays[1] = 29;

    month = 0;
    while (days >= monthDays[month])
    {
        days -= monthDays[month];
        month++;
    }

    day = days + 1;
    month++;

    dateStr = padZero(year, 4) + "-" + padZero(month) + "-" + padZero(day);
    timeStr = padZero(hours) + ":" + padZero(minutes) + ":" + padZero(seconds);

    return dateStr + " " + timeStr + " " + level.realTimeTZ;
}

isLeapYear(y)
{
    return (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0));
}

padZero(num, digits)
{
    if (!isDefined(digits))
        digits = 2;

    str = "" + num;
    while (str.size < digits)
        str = "0" + str;

    return str;
}