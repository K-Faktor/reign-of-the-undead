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
#include scripts\include\waypoints;

// called from maps\mp\gametypes\surv::Callback_StartGameType()
init()
{
    log("trace", "msg|in _server::init()||");

    // should we use the alternate bot AI under devlopment?
    level.zombieAiDevelopment = true;

    // run in automatic map testing mode?
    level.autoMapTesting = (getDvarInt("rotu_auto_map_test") == 1);
    level.autoMapTestDone = false;
    if (level.autoMapTesting) {
        log("server", "msg|In auto map testing mode||");
    }

    if (!isDefined(game["allies"])) {game["allies"] = "marines";}
    if (!isDefined(game["axis"])) {game["axis"] = "opfor";}

    level.starttime = getTime();
    level.activePlayers = 0;

    level.gametype = toLower(getDvar("g_gametype"));
    level.modversion = "RotU v2.2.2-git";
    level.dedicated = getDvar("dedicated");

    currentMap = getdvar("mapname");
    level.currentMap = currentMap;
    currentMapName = scripts\server\_mapvoting22::mapTextName(currentMap);
    log("server", "msg|Starting map " + currentMapName + " (" + currentMap + ").||");
    logMapStartHeader();

    thread scripts\server\_settings::init();
    thread maps\mp\_umiEditor::init();
    thread scripts\server\_ranks::init();
    thread scripts\server\_welcome::init();
    thread scripts\server\_maps::init();
    thread scripts\server\_environment::init();
    thread scripts\clients\_clients::init();
    thread scripts\players\_players::init();
    thread scripts\gamemodes\_gamemodes::init();
    thread scripts\bots\_bots::init();
    thread scripts\server\_adminCommands::init();
    thread scripts\server\_rconInterface::init();
    thread scripts\server\_adminInterface::init();
    thread scripts\server\_scoreboard::init();
    thread scripts\level\signals::init();

    level.ascii = scripts\include\strings::buildPrintableAscii();

    // code to manage main popup menu (open on 'b' keypress)
    thread scripts\server\_main_popup::init();
    thread showDevelopmentConsoleMessages();
    buildIntermissionDidYouKnowMessages();
    thread intermissionDidYouKnowMessages();
    thread scripts\players\_players::watchPlayersData();
    thread scripts\players\_players::correctPlayerCounts();
    thread scripts\players\_players::onWaveIntermissionBegins();
    thread scripts\players\_players::onWaveIntermissionEnds();
    thread verifyRconPassword();

    wait 0.5;

    // thread nearestWaypointsTimedTest(); // dev testing only
    log("server", "msg|Server is running and waiting for players to connect.||");
    runTestCode();
}

/**
 * @brief Checks for and tries to fix an incorrect rcon password
 *
 * @returns nothing
 */
verifyRconPassword()
{
    log("trace", "msg|in _server::verifyRconPassword()||");

    wait 5;
    resetCount = 0;
    while ((getdvar("rcon_password") != getdvar("rcon_password_backup")) &&
           (resetCount < 4))
    {
        warnPrint("rcon_password is incorrect.  Resetting it using the backup rcon password.");
        setdvar("rcon_password", getdvar("rcon_password_backup"));
        resetCount++;
        wait 3;
    }
    if (getdvar("rcon_password") != getdvar("rcon_password_backup")) {
        errorPrint("We failed to fix the incorrect rcon password.");
        return;
    }
}


/**
 * @brief Shows console messages about this being a test and development server
 *
 * @returns nothing
 */
showDevelopmentConsoleMessages()
{
    log("trace", "msg|in _server::showDevelopmentConsoleMessages()||");

    wait 15;
    prefix = "^3[admin]: ";
    message1 = prefix + getDvar("admin_message1");
    message2 = prefix + getDvar("admin_message2");
    message3 = prefix + getDvar("admin_message3");

    while(true) {
        if (message1 != prefix) {
            iPrintln(message1);
            wait 3;
        }
        if (message2 != prefix) {
            iPrintln(message2);
            wait 3;
        }
        if (message3 != prefix) {
            iPrintln(message3);
        }
        wait 180; // show messages every 3 minutes
    }
}



readLogMessages()
{
    debugPrint("in _server::readLogMessages()", "fn", level.lowVerbosity);
    /// To use the file commands, we need to be inside /# ... #/ tags
    /#

    /// N.B. These file commands require +set developer 1 in the game command line
    logFilename = "C:\\Program Files (x86)\\Activision\\Call of Duty 4 - Modern Warfare\\Mods\\rotu21\\oct_mp.log";
    chatFilename = "C:\\Program Files (x86)\\Activision\\Call of Duty 4 - Modern Warfare\\Mods\\rotu21\\chat.log";
    debugPrint("logFilename: " + logFilename, "val");
    debugPrint("chatFilename: " + chatFilename, "val");
    logFile = 0;
    logFile = openfile(logFilename, "read");
//     assertex( logFile != -1, "Could not open file: " + logFilename );
    chatFile = openfile(chatFilename, "write");
//     assertex( chatFile != -1, "Could not open file: " + chatFilename );

    /// @todo still can't work with files
    line = FReadLn(logFile);
    line = "test lorem ipsum\n";
    fprintln(chatFile, line);

    CloseFile(logFile);
    CloseFile(chatFile);
    debugPrint("test", "val");

    #/
}

/**
 * @brief Shows 'Did You Know' messages between waves
 *
 * @returns nothing
 */
intermissionDidYouKnowMessages()
{
    log("trace", "msg|in _server::intermissionDidYouKnowMessages()||");

    self endon("game_ended");

    while(1) {
        level waittill("wave_finished");
        wait 3;
        index = randomInt(level.didYouKnow.size);
        for (i=0; i<4; i++) {
            message = "^3Did You Know: ^7" + level.didYouKnow[index];
            iPrintln(message);
            index++;
            if (index == level.didYouKnow.size) {index = 0;}
            wait 5;
        }
    }
}

/**
 * @brief Loads the did you know data from the config file
 *
 * @returns nothing
 */
buildIntermissionDidYouKnowMessages()
{
    log("trace", "msg|in _server::buildIntermissionDidYouKnowMessages()||");

    level.didYouKnow = [];
    for (i=0; i<60; i++) {
        get = getdvar("surv_did_you_know"+(i+1));
        if(get == "") {break;}
        level.didYouKnow[i] = get;
    }
}

/**
 * @brief A convenient spot to put test code that will be executed when the server starts
 *
 * @returns nothing
 */
runTestCode()
{
    log("trace", "msg|in _server::runTestCode()||");

//     maps\mp\_umi::devDumpEntities();
//     maps\mp\_umi::devDumpCsvWaypointsToBtd();
    //     thread maps\mp\_umiEditor::devDrawWaypoints(true);
}
