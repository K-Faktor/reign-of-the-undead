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
 * @returns nothing
 */
plantFlag(origin)
{
    // quality:ignore_trace

    flag = spawn("script_model", origin);
    flag setModel("prop_flag_american");  
}


/**
 * @brief Logs information about the mao being loaded
 *        Call once at map start.
 *
 * @returns nothing
 */
logMapStartHeader()
{
    // quality:ignore_trace

    initRealTime();

    currentMap = getDvar("mapname");
    currentMapName = scripts\server\_mapvoting22::mapTextName(currentMap);
    if (currentMapName == currentMap) {currentMapName = "";}
    if (level.autoMapTesting) {
        fmt = "msg|Map Started||mapName|$1||mapEnglishName|$2||timestamp|$3||";
        log("automaptest", sprintfLog(fmt, currentMap, currentMapName, getRealDateTimeString()));
    }

    log("pre", "============================================================\n");
    log("pre", "Map Started: " + getRealDateTimeString() + "\n");
    log("pre", "Map: " + currentMap + "\n");
    log("pre", "============================================================\n");
}


/**
 * @brief Initializes our JSON logging; called from bootstrapCritical()
 *
 * @returns nothing
 */
initLogging()
{
    // quality:ignore_trace

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
    
    log("server", "msg|Running debug version of rotu_svr_scripts.iwd.||");
    suppressed = [];
    if (level.hideTrace) {suppressed[suppressed.size] = "trace";}
    if (level.hideDebug) {suppressed[suppressed.size] = "debug";}
    if (level.hideValue) {suppressed[suppressed.size] = "value";}
    if (level.hideSignal) {suppressed[suppressed.size] = "signal";}
    if (level.hidePre) {suppressed[suppressed.size] = "pre";}

    if (suppressed.size == 0) {
        log("server", "msg|Suppressing no log messsage types. 'bout to get really loud in here. You'd typically want to suppress at least 'trace' and 'signal'.||");
    } else {
        log("server", "msg|Suppressing messsage types: " + join(suppressed, ", ") + "||");
    }
}


/**
 * @brief Converts internal pipe-encoded JSON into valid a JSON object of key:value pairs
 *
 * @param encodedJson string The string with parameter tokens.
 *                           Use single pipe | as a separator between key and value.
 *                           Use double pipe || as a separator between key:value pairs.
 *                           Append ':n" to a value to designate it as Numeric, and ':b" for boolean
 *                        
 *                           Ex.: "key1|value1:n||key2|value2:b||"
 *
 * @returns string A valid JSON object with the message ready to be printed to the g_log
 */
tokenizeMessage(encodedJson)
{
    // quality:ignore_trace  trace messages on low-level functions can cause stack overflows

    buf = "";
    pairs = split(encodedJson, "||");  // strTok() is too greedy, and can only handle a single-char replcement str
    if (!isDefined(pairs)) {logPrint("pairs is undefined. Bailing\n"); return;}
    
    for (i=0; i<pairs.size; i++) {
        pair = pairs[i];
        tokens = strTok(pair, "|");
        if (!isDefined(tokens)) {logPrint("tokens is undefined. Bailing\n"); return;}
        k = tokens[0];
        if (!isDefined(k)) {logPrint("k is undefined. Bailing\n"); return;}
        // logPrint("k: " + k + "\n");

        v = tokens[1];
        if (!isDefined(v)) {
            v = "null";
            // logPrint("v is undefined. Bailing\n");
            // return;
        }
        // logPrint("v: " + v + "\n");

        // All | as separators are removed now.
        // Now we will add them back as quote placeholders.
        k = "|" + k + "|";                          // all keys are strings that need quotes
        if (endsWith(v, ":b")) {
            // format as JSON bool, no quotes
            v = getSubStr(v, 0, v.size - 2);
            if (v == "0") {v = "false";}
            else if (v == "1") {v = "true";}
        } else if (endsWith(v, ":n")) {
            // format as JSON numeric, no quotes
            v = getSubStr(v, 0, v.size - 2);
        } else {
            // format as JSON string, w/quotes
            v = "|" + v + "|";
            v = replace(v, "\n", "\\n");
            v = replace(v, "\t", "\\t");
            v = replace(v, "\"", "\\\"");
        }

        // everything is properly quoted now, start building the JSON
        if (i == pairs.size - 1) {
            // last pair, no trailing comma or space
            buf += k + ": " + v;
        } else {
            buf += k + ": " + v + ", ";
        }
    }

    // nice alignment to the msg in server_mp.log
    parts = split(buf, "|msg|");
    if (!isDefined(parts[0])) {
        logPrint("BUG: no |msg| in string to split() at, so can't rightPad(). encodedJson:\n");
        logPrint(encodedJson);
    } else {
        a = rightPad(parts[0], " ", 21); // 24
        buf = a + "|msg|" + parts[1];
    }
    buf = "{" + buf + "}";

    // now replace | with real quotes
    buf = replace(buf, "|", "\"") + "\n";
    return buf;
}


/**
 * @brief Writes JSON-formatted log messages to logfile specified in g_log dvar
 *
 * @param eventType string The type of message. Any of the values in the switch:
 *                           [value|warn|error|debug|server|criticalbug|...]
 *
 * @param message string The pipe-encoded JSON message to write.  The first JSON
 *                       key in the message ahould be 'msg|`.
 * @param includeEpoch bool Include the Unix epoch, i.e. integer seconds?
 *
 * @returns nothing
 */
log(eventType, message, includeEpoch)
{
    // quality:ignore_trace  trace messages on low-level functions can cause stack overflows

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
    else if (includeEpoch) {
        epoch = "epoch|" + getRealUnixTime() + "||";
    } 

    temp = "";
    switch (eventType) {    // server status, game state
        // assert: first token of each snippet is a key, with no leading sep character
        // assert: last token of each snippet is a value, and ends with ||
        //         Example:   pre = "event|criticalbug||";
    case "server":                      
        pre = "event|server||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Notice: " + tokenizeMessage(temp);
        break;
    case "trace":
        if (level.hideTrace) {return;}
        pre = "event|trace||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Debug:  " + tokenizeMessage(temp);
        break;
    case "bug":
        pre = "event|bug||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Error: " + tokenizeMessage(temp);
        break;
    case "warn":
        pre = "event|warn||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Warn:   " + tokenizeMessage(temp);
        break;
    case "error":
        pre = "event|error||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Error:  " + tokenizeMessage(temp);
        break;
    case "debug":
        if (level.hideDebug) {return;}
        pre = "event|debug||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Debug:  " + tokenizeMessage(temp);
        break;
    case "criticalbug":
        pre = "event|criticalbug||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Debug:  " + tokenizeMessage(temp);
        break;
    case "value":
        if (level.hideValue) {return;}
        pre = "event|value||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Debug:  " + tokenizeMessage(temp);
        break;
    case "signal":
        pre = "event|signal||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Debug:  " + tokenizeMessage(temp);
        break;
    case "validate":
        pre = "event|validate||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Test:   " + tokenizeMessage(temp);
        break;
    case "automaptest":
        pre = "event|automaptest||";
        if (includeEpoch) {pre += epoch;}
        temp = pre + message;
        temp = "Test:   " + tokenizeMessage(temp);
        break;
    case "pre":
        if (level.hidePre) {return;}
        logPrint(message);
        return;
    // just show the darn message!
    case "dev":
        if (level.developmentStatus == "dev") {
            pre = "event|dev||";
            if (includeEpoch) {pre += epoch;}
            temp = pre + message;
            temp = "Dev:    " + tokenizeMessage(temp);
            break;
        } else {return;}
    default:
        temp = "Warn:   Unsupported event type: " + eventType + "   for message: " + message;
    }

    logPrint(temp);
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
 * @brief Performs sprintf-like variable interpolation for JSON log strings
 *
 * @param formatString string The string with parameter tokens.
 *                            Use single pipe | as a separator between key and value.
 *                            Use double pipe || as a separator between key:value pairs.
 *                            Append ':n" to a value to designate it as Numeric, and ':b" for boolean
 *                        
 *                            Ex.: "key1|value1:n||key2|value2:b||"
 *
 * @param p1 string A parameter to interpolate
 * @param p2 string A parameter to interpolate
 * @param p3 string A parameter to interpolate
 * @param p4 string A parameter to interpolate
 * @param p5 string A parameter to interpolate
 * @param p6 string A parameter to interpolate
 * @param p7 string A parameter to interpolate
 * @param p8 string A parameter to interpolate
 * @param p9 string A parameter to interpolate
 * @param p10 string A parameter to interpolate
 * @param p11 string A parameter to interpolate
 * @param p12 string A parameter to interpolate
 * @param p13 string A parameter to interpolate
 * @param p14 string A parameter to interpolate
 * @param p15 string A parameter to interpolate
 * @param p16 string A parameter to interpolate
 * @param p17 string A parameter to interpolate
 * @param p18 string A parameter to interpolate
 * @param p19 string A parameter to interpolate
 *
 * @returns the interpolated JSON-formatted string
 */
sprintfLog(formatString, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19)
{
    // quality:ignore_trace  trace messages on low-level functions can cause stack overflows

    // We are *just* doing interpolation here, no quoting, no default values
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

    interpolatedString = formatString; // Init
    // replace all two-digit tokens first, so $1 doesn't mistakenly match $10
    for (i=10; i<p.size; i++) {
        interpolatedString = replace(interpolatedString, "$" + i, p[i]);
    }
    // replace all single-digit tokens
    for (i=1; ((i<11) && (i<p.size)); i++) {
        interpolatedString = replace(interpolatedString, "$" + i, p[i]);
    }
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
    log("trace", "msg|in utility::decimalRgbToColor()||");

    return (red/255, green/255, blue/255);
}
