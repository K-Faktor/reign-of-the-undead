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
 * @file utility.gsc General utility functions
 */

#include scripts\include\realtime;
#include scripts\include\strings;

/*
 * @brief Inserts a flag into the map at \corigin. Good for debugging.
 *
 * @param origin vector The position to place the flag, will be bottom of flagpole.
 *
 * @return nothing
 */
plantFlag(origin)
{
    flag = spawn("script_model", origin);
    flag setModel("prop_flag_american");  
}


// Call this once at the start of every map / new game
logMapStartHeader()
{
    initRealTime();

    currentMap = getDvar("mapname");
    currentMapName = scripts\server\_mapvoting22::mapTextName(currentMap);
    if (currentMapName == currentMap) {currentMapName = "";}
    if (level.autoMapTesting) {
        fmt = "|Map Started|, |mapName|: |$1|, |mapEnglishName|: |$2|, |timestamp|: |$3|";
        log("automaptest", sprintfJson(fmt, currentMap, currentMapName, getRealDateTimeString()));
    }

    log("pre", "============================================================\n");
    log("pre", "Map Started: " + getRealDateTimeString() + "\n");
    log("pre", "Map: " + currentMap + "\n");
    log("pre", "============================================================\n");
}


/**
 * @deprecated Forwards to log() until I do a global replace
 * @brief Writes debug messages to logfile specified in g_log dvar
 *
 * @param message string The message to write
 * @param type string The type of debug message ["fn"|"val"]
 * @param verbosity integer The verbosity level [0-3].  0 is low verbosity, 3 is high verbosity
 *
 * @returns nothing
 */
debugPrint(message, type, verbosity)
{
    // Function entry messages
    if ((level.printFunctionEntryMessages) &&
        (type == "fn") &&
        (verbosity <= level.debugVerbosity))
    {
        log("trace", message, false);
    }

    // Variable value messages
    else if ((level.printValueMessages) && (type == "val")) {
        log("value", message, false);
    }

    // Signals notified or received
    else if ((level.printSignalMessages) && (type == "sig")) {
        log("signal", message, false);
    }
}


/**
 * @brief Initializes our JSON logging; called from bootstrapCritical()
 *
 * @returns nothing
 */
initLogging()
{
    temp = getdvar("sv_hide_log_message");
    values = strTok(temp, ",");

    level.hideTrace = false;
    level.hideDebug = false;
    level.hideValue = false;
    level.hideSignal = false;
    level.hidePre = false;
    for (i=0; i<values.size; i++) {
        if (trim(toLower(values[i])) == "trace")  {level.hideTrace = true; continue;}
        if (trim(toLower(values[i])) == "debug")  {level.hideDebug = true; continue;}
        if (trim(toLower(values[i])) == "value")  {level.hideValue = true; continue;}
        if (trim(toLower(values[i])) == "signal") {level.hideSignal = true; continue;}
        if (trim(toLower(values[i])) == "pre")    {level.hidePre = true; continue;}
    }

    // overrides, for dev convenience; easier than messing w/config files
    if (level.developmentStatus == "dev") {
        level.hideTrace = true;
        level.hideDebug = false;
        level.hideValue = false;
        level.hideSignal = true;
        level.hidePre = false;
    }
    
    log("server", "Running debug version of rotu_svr_scripts.iwd.");
    suppressed = [];
    if (level.hideTrace) {suppressed[suppressed.size] = "trace";}
    if (level.hideDebug) {suppressed[suppressed.size] = "debug";}
    if (level.hideValue) {suppressed[suppressed.size] = "value";}
    if (level.hideSignal) {suppressed[suppressed.size] = "signal";}
    if (level.hidePre) {suppressed[suppressed.size] = "pre";}

    if (suppressed.size == 0) {
        log("server", "Suppressing no log messsage types. 'bout to get really loud in here. You'd typically want to suppress at least 'trace' and 'signal'.");
    } else {
        log("server", "Suppressing messsage types: " + join(suppressed, ", "));
    }
}


/**
 * @brief Writes JSON-formatted log messages to logfile specified in g_log dvar
 *
 * @param eventType string The type of message. Any of the values in the switch:
 *                           [value|warn|error|debug|server|criticalbug|...]
 *
 * @param message string The message to write
 * @param includeEpoch bool Include the Unix epoch, i.e. integer seconds?
 *
 * @returns nothing
 */
log(eventType, message, includeEpoch)
{
    // handle undefined eventType
    if (!isDefined(eventType)) {
        LogPrint("Error: utility::log() parameter 'eventType' is undefined\n");
        if (isDefined(message)) {LogPrint("The associated message parameter was: " + message + "\n");}
    }
    // handle undefined message
    if (!isDefined(message)) {
        LogPrint("Error: utility::log() parameter 'message' is undefined\n");
        // we will need the stack trace to debug, so force the error regardless
        LogPrint(message);
        return;
    }

    epoch = "";
    if (!isDefined(includeEpoch)) {includeEpoch = false;}
    else if (includeEpoch) {epoch = " |epoch|: " + getRealUnixTime() + ",";} 

    temp = "";
    switch (eventType) {
    // server status, game state
    case "server":                      
        temp = "Notice: {|event|: |server|," + epoch + " " + "|msg|: |" + message + "|}";
        break;
    case "trace":
        if (level.hideTrace) {return;}
        temp = "Debug:  {|event|: |trace|," + epoch + " " + "|msg|: |" + message + "|}";
        break;
    case "bug":
        temp = "Error: {|event|: |bug|," + epoch + " " + "|msg|: |" + message + "|}";
        break;
    case "warn":
        temp = "Warn:   {|event|: |warn|," + epoch + "   " + "|msg|: |" + message + "|}";
        break;
    case "error":
        temp = "Error: {|event|: |error|," + epoch + " " + "|msg|: |" + message + "|}";
        break;
    case "debug":
        if (level.hideDebug) {return;}
        temp = "Debug:  {|event|: |debug|," + epoch + "  " + "|msg|: |" + message + "|}";
        break;
    case "criticalbug":
        temp = "Debug:  {|event|: |criticalbug|," + epoch + " " + "|msg|: |" + message + "|}";
        break;
    case "value":
        if (level.hideValue) {return;}
        temp = "Debug:  {|event|: |value|," + epoch + "  " + "|msg|: |" + message + "|}";
        break;
    case "signal":
        if (level.hideSignal) {return;}
        temp = "Debug:  {|event|: |signal|," + epoch + " " + "|msg|: |" + message + "|}";
        break;
    case "automaptest":
        temp = "Test:   {|event|: |automaptest|," + epoch + " " + "|msg|: " + message + "}";
        break;
    case "pre":
        if (level.hidePre) {return;}
        logPrint(message);
        return;
    // just show the darn message!
    case "dev":
        if (level.developmentStatus == "dev") {
            temp = "Dev: {|event|: |dev|," + epoch + " " + "|msg|: |" + message + "|}";
            break;
        } else {return;}
    default:
        temp = "Warn:   Unsupported event type: " + eventType + "   for message: " + message;
    }

    message = replace(temp, "|", "\"") + "\n";
    logPrint(message);

}

// Escape a string for JSON.  Unused currently, but we may need it later.
// escapeString(s)
// {
//     s = replace(s, "\\", "\\\\");
//     s = replace(s, "\"", "\\\"");
//     s = replace(s, "\n", "\\n");
//     s = replace(s, "\r", "\\r");
//     s = replace(s, "\t", "\\t");
//     return s;
// }

/**
 * @deprecated
 * @brief Writes warning messages to logfile specified in g_log dvar
 *
 * @param message string The message to write
 *
 * @returns nothing
 */
warnPrint(message)
{
    // @todo print deprecation notice to find any warnPrint's not ported, *after gloabl replace
    log("warn", message, false);
}


/**
 * @deprecated
 * @brief Always writes error messages to logfile specified in g_log dvar
 *
 * @param message string The message to write
 *
 * @returns nothing
 */
errorPrint(message)
{
    // @todo print deprecation notice to find any noticePrint's not ported
    log("error", message, false);
}


/**
 * @deprecated
 * @brief Always writes a message to logfile specified in g_log dvar
 * This function is used for messages we always want to write, yet aren't
 * really error messages.
 *
 * @param message string The message to write
 *
 * @returns nothing
 */
noticePrint(message)
{
    // @todo print deprecation notice to find any noticePrint's not ported
    log("server", message, false);
}


/**
 * @brief Performs sprintf-like variable interpolation for JSON strings
 *
 * N.B.: For when we need more control that log() gives us
 *
 * @param formatString string The string with parameter tokens. Use pipe `|` for double quotes `"`
 * @param p1-p19 string The parameters to interpolate
 *
 * @returns the interpolated JSON-formatted string
 */
logJson(formatString, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19)
{
    debugPrint("in utility::logJson()", "fn", level.highVerbosity);

    msg = sprintfJson(formatString, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19);
    logPrint(msg + "\n");
}


/**
 * @brief Performs sprintf-like variable interpolation for JSON strings
 *
 * N.B.: For when we need more control that log() gives us
 *
 * @param formatString string The string with parameter tokens. Use pipe `|` for double quotes `"`
 * @param p1-p19 string The parameters to interpolate
 *
 * @returns the interpolated JSON-formatted string
 */
sprintfJson(formatString, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19)
{
    debugPrint("in utility::sprintfJson()", "fn", level.highVerbosity);

    defaultStr = "";
    defaultNumeric = 0;
    defaultBool = "false";
    // parse parameters
    count = 1;
    p = [];
    p[0] = formatString;
    p[1] = p1;
    p[2] = p2;
    p[3] = p3;
    p[4] = p4;
    p[5] = p5;
    p[6] = p6;
    p[7] = p7;
    p[8] = p8;
    p[9] = p9;
    p[10] = p10;
    p[11] = p11;
    p[12] = p12;
    p[13] = p13;
    p[14] = p14;
    p[15] = p15;
    p[16] = p16;
    p[17] = p17;
    p[18] = p18;
    p[19] = p19;

    // set any JSON default values
    interpolatedString = formatString; // Init
    for (i=1; i<p.size; i++) {
        if (!isDefined(p[i])) {
            if (tokenMatchCount(formatString, "$" + i + ":b")) {
                // found a bool that need a defaults value
                p[i] = defaultBool;
            } else if (tokenMatchCount(formatString, "$" + i + ":n")) {
                // found a bool that need a defaults value
                p[i] = defaultNumeric;
            } else {
                // found a str that need a defaults value
                p[i] = defaultStr;
            }
        } else {
            if (tokenMatchCount(formatString, "$" + i + ":b")) {
                // found a bool that need a defaults value
                if ((p[i] == 0) || (p[i] == "")) {
                    p[i] = "false";
                } else {
                    p[i] = "true";
                }
            }
        }

    }
    // replace all two-digit tokens first, so $1 doesn't mistakenly match $10
    for (i=10; i<p.size; i++) {
        interpolatedString = replace(interpolatedString, "$" + i + ":b", p[i]);
        interpolatedString = replace(interpolatedString, "$" + i + ":n", p[i]);
        interpolatedString = replace(interpolatedString, "$" + i, p[i]);
    }
    // replace all single-digit tokens
    for (i=1; ((i<11) && (i<p.size)); i++) {
        interpolatedString = replace(interpolatedString, "$" + i + ":b", p[i]);
        interpolatedString = replace(interpolatedString, "$" + i + ":n", p[i]);
        interpolatedString = replace(interpolatedString, "$" + i, p[i]);
    }
    // swap out pipes for double quotes
    interpolatedString = replace(interpolatedString, "|", "\"");
    return interpolatedString;
}


/**
 * @brief Coverts a decimal RGB tuple to a cod4 color tuple
 *
 * @param red integer The red component, [0, 255]
 * @param green integer The green component, [0, 255]
 * @param blue integer The blue component, [0, 255]
 *
 * @returns a cod4 color tuple
 */
decimalRgbToColor(red, green, blue)
{
    debugPrint("in utility::decimalRgbToColor()", "fn", level.nonVerbose);

    return (red/255, green/255, blue/255);
}
