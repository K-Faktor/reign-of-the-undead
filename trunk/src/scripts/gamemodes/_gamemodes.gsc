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

#include scripts\include\physics;
#include scripts\include\strings;
#include scripts\include\utility;

init()
{
    log("trace", "msg|in _gamemodes::init()||");

    thread scripts\gamemodes\_hud::init();
    thread scripts\gamemodes\_upgradables::init();
    thread scripts\gamemodes\_mysterybox::init();
    dropSpawns();


    level.gameEnded = false;
    level.dif_zomHPMod = 1;
    level.dif_zomMax = 100;
    level.dif_zomPP = 5;
    level.dif_zomSpawnRate = .5;
    level.dif_zomDamMod = 1;
    level.dif_killedLast5Sec = 0;
    level.gameWasLost = false;

    level.ammoStockType = "ammo";

//  level.creditTime = 7;
    level.creditBasetime = 5;
    level.objectiveIndexAvailability = [];
    level.objectiveIndexAvailability[0] = 1;
    level.objectiveIndexAvailability[1] = 1;
    level.objectiveIndexAvailability[2] = 1;
    level.objectiveIndexAvailability[3] = 1;
    level.objectiveIndexAvailability[4] = 1;
    level.objectiveIndexAvailability[5] = 1;
    level.objectiveIndexAvailability[6] = 1;
    level.objectiveIndexAvailability[7] = 1;
    level.objectiveIndexAvailability[8] = 1;
    level.objectiveIndexAvailability[9] = 1;
    level.objectiveIndexAvailability[10] = 1;
    level.objectiveIndexAvailability[11] = 1;
    level.objectiveIndexAvailability[12] = 1;
    level.objectiveIndexAvailability[13] = 1;
    level.objectiveIndexAvailability[14] = 1;
    level.objectiveIndexAvailability[15] = 1;

}

dropSpawns()
{
    log("trace", "msg|in _gamemodes::dropSpawns()||");

    TDMSpawns = getentarray("mp_tdm_spawn", "classname");

    for (i=0; i<TDMSpawns.size; i++)
    {
        spawn = TDMSpawns[i];
        spawn.origin = dropPlayer(spawn.origin+(0,0,32), 300);
    }

    DMSpawns = getentarray("mp_dm_spawn", "classname");

    for (i=0; i<DMSpawns.size; i++)
    {
        spawn = DMSpawns[i];
        spawn.origin = dropPlayer(spawn.origin+(0,0,32), 300);
    }
}

initGameMode()
{
    log("trace", "msg|in _gamemodes::initGameMode()||");

    if (!isdefined(level.gameMode))
    level.gameMode = level.dvar["surv_defaultmode"]; // Default gamemode

    loadGameMode(level.gameMode);
    loadDifficulty(level.dvar["game_difficulty"]);
}

loadGameMode(mode)
{
    log("trace", "msg|in _gamemodes::loadGameMode()||");

    switch(mode) {
        case "waves_special":
            loadSurvivalMode("special");
        break;
        case "waves_endless":
            loadSurvivalMode("endless");
        break;
        case "scripted":
            loadScriptedMode();
        break;
        case "onslaught":
            loadOnslaughtMode();
        break;
    }
}

/// @deprecated
loadScriptedMode()
{
    log("trace", "msg|in _gamemodes::loadScriptedMode()||");

    // Scripted mode doesn't do much

}

loadOnslaughtMode()
{
    log("trace", "msg|in _gamemodes::loadOnslaughtMode()||");

    level.currentPlayer = 0;
}

loadSurvivalMode(mode)
{
    log("trace", "msg|in _gamemodes::loadSurvivalMode()||");

    level.survMode = mode;
    level.survSpawns = [];
    level.survSpawnsTotalPriority = 0;
    thread scripts\gamemodes\_survival::initGame();
}

buildZomTypes(preset)
{
    log("trace", "msg|in _gamemodes::buildZomTypes()||");

    debugPrint("loading zombie types: " + preset, "val");

    level.zom_spawntypes = [];
    level.zom_spawntypes_weight = [];
    level.zom_spawntypes_weightotal = 0;
    level.zom_typenames["zombie"] = "zombies";
    level.zom_typenames["dog"] = "dogs";
    level.zom_typenames["fast"] = "quick zombies";
    level.zom_typenames["runners"] = "sprinting zombies";
    level.zom_typenames["fat"] = "fat zombies";
    level.zom_typenames["burning"] = "inferno zombies";
    level.zom_typenames["burning_dog"] = "inferno dogs";
    level.zom_typenames["toxic"] = "crawler zombies";
    level.zom_typenames["tank"] = "hell zombies";
    level.zom_typenames["burning_tank"] = "burning hell zombies";
    level.zom_typenames["cyclops"] = "cyclops zombies";
    level.zom_typenames["boss"] = "^1Final Zombies^7";

    switch (preset) {
        case "regular":
            level.zom_spawntypes[0] = "zombie";
            level.zom_spawntypes_weight[0] = 1;
            level.zom_spawntypes_weightotal = 1;
        break;
        case "dogs":
            level.zom_spawntypes[0] = "dog";
            level.zom_spawntypes_weight[0] = 1;
            level.zom_spawntypes_weightotal = 1;
        break;
        case "basic":
            level.zom_spawntypes[0] = "zombie";
            level.zom_spawntypes_weight[0] = 9;
            level.zom_spawntypes[1] = "fat";
            level.zom_spawntypes_weight[1] = 3;
            level.zom_spawntypes[2] = "fast";
            level.zom_spawntypes_weight[2] = 3;
            level.zom_spawntypes_weightotal = 15;

        break;
        case "all":
            level.zom_spawntypes[0] = "zombie";
            level.zom_spawntypes_weight[0] = 9;
            level.zom_spawntypes[1] = "fat";
            level.zom_spawntypes_weight[1] = 3;
            level.zom_spawntypes[2] = "fast";
            level.zom_spawntypes_weight[2] = 3;
            level.zom_spawntypes[3] = "runners";
            level.zom_spawntypes_weight[3] = 3;
            level.zom_spawntypes[4] = "burning";
            level.zom_spawntypes_weight[4] = 2;
            level.zom_spawntypes[5] = "burning_dog";
            level.zom_spawntypes_weight[5] = 2;
            level.zom_spawntypes[6] = "toxic";
            level.zom_spawntypes_weight[6] = 2;
            level.zom_spawntypes[7] = "dog";
            level.zom_spawntypes_weight[7] = 3;
            level.zom_spawntypes[8] = "tank";
            level.zom_spawntypes_weight[8] = 2;
            level.zom_spawntypes[9] = "burning_tank";
            level.zom_spawntypes_weight[9] = 2;
            level.zom_spawntypes[10] = "cyclops";
            level.zom_spawntypes_weight[10] = 1;
            level.zom_spawntypes_weightotal = 32;
        break;
    }

    // Weighted array of special zombie types
    level.weightedSpecialTypes = [];
    level.weightedSpecialTypes[0] = "runners";
    level.weightedSpecialTypes[1] = "dog";
    level.weightedSpecialTypes[2] = "toxic";
    level.weightedSpecialTypes[3] = "cyclops";
    level.weightedSpecialTypes[4] = "burning_tank";
    level.weightedSpecialTypes[5] = "dog";
    level.weightedSpecialTypes[6] = "runners";
    level.weightedSpecialTypes[7] = "burning";
    level.weightedSpecialTypes[8] = "burning_dog";
    level.weightedSpecialTypes[9] = "toxic";
    level.weightedSpecialTypes[10] = "tank";
    level.weightedSpecialTypes[11] = "burning";
    level.weightedSpecialTypes[12] = "burning_tank";
    level.weightedSpecialTypes[13] = "runners";
    level.weightedSpecialTypes[14] = "burning_dog";
    level.weightedSpecialTypes[15] = "dog";
    level.weightedSpecialTypes[16] = "tank";
}

getDefaultWeight(type)
{
    log("trace", "msg|in _gamemodes::getDefaultWeight()||");

    switch (type) {
        case "zombie":
            return 9;
        case "fat":
            return 3;
        case "runners":         // Fall through
        case "fast":
            return 3;
        case "burning":         // Fall through
        case "burning_dog":
            return 2;
        case "toxic":
            return 2;
        case "dog":
            return 3;
        case "tank":            // Fall through
        case "burning_tank":
            return 2;
        case "cyclops":
            return 2;
    }
}

addSpawnType(type)
{
    log("trace", "msg|in _gamemodes::addSpawnType()||");

    weight = getDefaultWeight(type);
    level.zom_spawntypes_weightotal += weight;
    level.zom_spawntypes[level.zom_spawntypes.size] = type;
    level.zom_spawntypes_weight[level.zom_spawntypes_weight.size] = weight;
}

/**
 * @brief Randomly selects a type of zombie
 *
 * @returns string The type of zombie to spawn
 */
getRandomType()
{
    log("trace", "msg|in _gamemodes::getRandomType()||");

    weight = randomint(level.zom_spawntypes_weightotal);
    for (i=0; i<level.zom_spawntypes.size; i++) {
        weight -= level.zom_spawntypes_weight[i];
        if (weight < 0) {
            return level.zom_spawntypes[i];
        }
    }
}


/**
 * @brief Randomly selects a special type of zombie
 *
 * @returns string The type of special zombie to spawn
 */
getRandomSpecialType()
{
    log("trace", "msg|in _gamemodes::getRandomSpecialType()||");

    index = randomInt(level.weightedSpecialTypes.size);
    return level.weightedSpecialTypes[index];
}


loadDifficulty(difficulty)
{
    log("trace", "msg|in _gamemodes::loadDifficulty()||");

    switch (difficulty) {
        case 1:
            level.dif_zomPP = 2;
            level.dif_zomHPMod = .5;
        break;
        case 2:
            level.dif_zomPP = 3;
            level.dif_zomHPMod = .75;
        break;
        case 3:
            level.dif_zomPP = 5;
            level.dif_zomHPMod = 1;

        break;
        case 4:
            level.dif_zomPP = 10;
            level.dif_zomHPMod = 1.5;

        break;
        default:
            thread custom_scripts\_difficulty::difficulty(difficulty);
        break;
    }

    if (level.dvar["zom_dynamicdifficulty"]) {level thread monitorDifficulty();}
}

monitorDifficulty()
{
    log("trace", "msg|in _gamemodes::monitorDifficulty()||");

    level endon("stop_monitoring");
    thread resumeMonitoring();
    level waittill("start_monitoring");
    while (1) {
        level.dif_zomMax = level.dif_zomPP * level.activePlayers;
        level.dif_zomSpawnRate = .1;
        if (level.dif_killedLast5Sec!=0) {
            // Divide by zero protection
            if (level.activePlayers != 0) {
                level.dif_zomSpawnRate = .5 * ( level.dif_killedLast5Sec / level.activePlayers);
            } else {level.dif_zomSpawnRate = .5 * level.dif_killedLast5Sec;}
            if (level.dif_zomSpawnRate < 0.05) {level.dif_zomSpawnRate = 0.05;}
            level.dif_killedLast5Sec = 0;
        }
        if (level.dif_zomSpawnRate < 0.05) {level.dif_zomSpawnRate = 0.05;}

        level.dif_zomDamMod = .5;
        if (level.activePlayers > 5)  {level.dif_zomDamMod = .75;}
        if (level.activePlayers > 10) {level.dif_zomDamMod = 1;}
        if (level.activePlayers > 15) {level.dif_zomDamMod = 1.25;}
        if (level.activePlayers > 20) {level.dif_zomDamMod = 1.5;}
        if (level.activePlayers > 25) {level.dif_zomDamMod = 1.75;}
        if (level.activePlayers > 30) {level.dif_zomDamMod = 2;}

        wait 5;
    }
}

resumeMonitoring()
{
    log("trace", "msg|in _gamemodes::resumeMonitoring()||");

    level waittill("stop_monitoring");
    thread monitorDifficulty();
}

endMap(endReasontext, showcredits)
{
    log("trace", "msg|in _gamemodes::endMap()||");

    if (!isdefined(showcredits)) {
        // Game was lost
        showcredits = false;
        level.gameWasLost = true;
    }

    level.gameEndTime = getTime();
    level.gameEnded = true;

//  game["state"] = "intermission";
    game["state"] = "postgame";
    level notify("intermission");
    level notify("game_ended");

    setGameEndTime( 0 );

    alliedscore = getTeamScore("allies");
    axisscore = getTeamScore("axis");

    setdvar( "g_deadChat", 1 );

    // Don't lock the 'Leave' menu on a Listen server
    if (!level.isDedicated) {
        players = getentarray("player", "classname");
        message = "^1You may not leave the game until the next map loads!";
        for(i = 0; i < players.size; i++) {
            players[i] setclientdvar("canleavegame", 0);
            players[i] closeMenu();
            players[i] closeInGameMenu();
            players[i] iPrintlnBold(message);
            players[i] freezePlayerForRoundEnd();
        }
    }

    scripts\server\_environment::stopAmbient(2);

    wait 2;
    noPlayersInGame = false;
    if (level.players.size == 0) {
        noPlayersInGame = true;
        showcredits = false; // no need to show credits!
    }

    if (showcredits) {
        thread playCreditsSound();
        level notify("starting_credits");
    } else {
        thread playEndSound();
    }

    level.blackscreen = newHudElem();
    level.blackscreen.sort = -2;
    level.blackscreen.alignX = "left";
    level.blackscreen.alignY = "top";
    level.blackscreen.x = 0;
    level.blackscreen.y = 0;
    level.blackscreen.horzAlign = "fullscreen";
    level.blackscreen.vertAlign = "fullscreen";
    level.blackscreen.foreground = true;

    level.blackscreen.alpha = 0;
    level.blackscreen setShader("black", 640, 480);

    level.end_text = newHudElem();
    level.end_text.font = "objective";
    level.end_text.fontScale = 2.4;
    level.end_text SetText(endReasontext);
    level.end_text.alignX = "center";
    level.end_text.alignY = "top";
    level.end_text.horzAlign = "center";
    level.end_text.vertAlign = "top";
    level.end_text.x = 0;
    level.end_text.y = 96;
    level.end_text.sort = -1; //-3
    level.end_text.alpha = 1;
    level.end_text.glowColor = (1,0,0);
    level.end_text.glowAlpha = 1;
    level.end_text.foreground = true;


    if (showcredits) {
        level.blackscreen fadeOverTime(7.5);
        level.blackscreen.alpha = 1;
        level.end_text setPulseFX( 95, int(7000), 1000 );
        wait 10;
    } else {
        level.blackscreen fadeOverTime(10);
        level.blackscreen.alpha = 1;
        level.end_text setPulseFX( 150, int(10000), 1000 );
        wait 15;
    }
    level.end_text destroy();

    if (showcredits) {
        temp = buildMovieCreditText();
        labelText = temp[0];
        creditText = temp[1];
        finalCredit = buildCenteredCreditText();

        thread showMovieStyleCredit(labelText, creditText);
        wait 5; // controls distance between movie credits and final credit
        showCenteredCredit(finalCredit, 2.0);

        level notify("credits_finished");
    }

    level.blackscreen destroy();
    if (noPlayersInGame) {
        // we don't need to vote!
        scripts\server\_maps::changeMap(getdvar("mapname"));
    } else {[[level.onChangeMap]]();}
}

buildMovieCreditText()
{
    log("trace", "msg|in _gamemodes::buildMovieCreditText()||");

    labels = [];
    credits = [];
    results = [];

    // Unless you are committing code to the Official RotU subversion repository,
    // do not call yourself a developer.  Use the "Server Customization" credit instead.
    labels[0] = "Developer";
    credits[0] = "Mark A. Taff";

    labels[1] = "Original Developer";
    credits[1] = "Bipo";

    labels[2] = "Original Scripters";
    credits[2][0] = "Bipo";
    credits[2][1] = "Brax (medkit)";

    labels[3] = "2D Art";
    credits[3] = "Mr-X";

    labels[4] = "Rigging & Ripping";
    credits[4][0] = "Etheross (most stuff)";
    credits[4][1] = "Hacker 22 (hellknight & crossbow)";

    labels[5] = "Original Mappers";
    credits[5][0] = "Viking";
    credits[5][1] = "Coverop";
    credits[5][2] = "Etheross";
    credits[5][3] = "Mr-X";
    credits[5][4] = "Bipo";

    labels[6] = "Server Provider";
    providers = level.dvar["server_provider"];
    tokens = scripts\include\strings::split(providers, ";");
    if (tokens.size == 0) {
        // no semi-colon, so only one provider listed
        credits[6] = providers;
    } else {
        for (i=0; i<tokens.size; i++) {
            credits[6][i] = tokens[i];
        }
    }

    // If you run a non-stock RotU, give yourself some credit. :-)
    customizers = level.dvar["server_customizer"];
    if (customizers != "") {
        labels[7] = "Server Customization";
        tokens = scripts\include\strings::split(customizers, ";");
        if (tokens.size == 0) {
            // no semi-colon, so only one customizer listed
            credits[7] = customizers;
        } else {
            for (i=0; i<tokens.size; i++) {
                credits[7][i] = tokens[i];
            }
        }
    }

    /**
     * HACK: Since Activision couldn't be bothered to let us right-justify lines
     * of text in a single HUD element, we have to pad each line so it is approximately
     * right-justified.  Further, since they couldn't be bothered to give us access
     * to font metrics, we have to adjust each line manually, by eye.
     */
    maxLength = 0;
    for (i=0; i<labels.size; i++) {
        if (labels[i].size > maxLength) {
            maxLength = labels[i].size;
        }
    }
    extraPadding = [];
    extraPadding[0] = 6;
    extraPadding[1] = 2;
    extraPadding[2] = 2;
    extraPadding[3] = 8;
    extraPadding[4] = 3;
    extraPadding[5] = 3;
    extraPadding[6] = 4;
    if (customizers != "") {extraPadding[7] = 0;}

    for (i=0; i<labels.size; i++) {
        labels[i] = leftPad(labels[i], " ", maxLength + extraPadding[i]);
    }

    credit = "";
    label = "";
    for (i=0; i<credits.size; i++) {
        if (isString(credits[i])) {
            // just one credit for this label
            credit += credits[i] + "\n";
            label += labels[i] + "\n";
        } else {
            // multiple credits for this label
            for (j=0; j<credits[i].size; j++) {
                credit += credits[i][j] + "\n";
                if (j==0) {
                    label += labels[i] + "\n";
                } else {
                    label += "\n";
                }
            }
        }
        // use a blank line between credit sections
        credit += "\n";
        label += "\n";
    }
    results[0] = label;
    results[1] = credit;
    return results;
}



/**
 * @brief Build the text string for the centered final credit
 *
 * @returns the text for the credit
 */
buildCenteredCreditText()
{
    log("trace", "msg|in _gamemodes::buildCenteredCreditText()||");

    // N.B. manually padded string, because we don't have font metrics
    credits  = "        Thanks for playing Rotu 2.2.2-git!\n";
    credits += "     Rotu 2.2.2-git is open source software.\n";
    credits += "github.com/marktaff/reign-of-the-undead";
    return credits;
}

showCenteredCredit(credit, scale)
{
    log("trace", "msg|in _gamemodes::showCenteredCredit()||");

    creditTimePerNewline = 0.3;     // how long to show credit per newline in credits
    creditHeightPerNewline = 20;    // base height of each credit line in pixels

    newlineCount = tokenMatchCount(credit, "\n");
//     creditTime = 2 + level.creditBasetime + (creditTimePerNewline * newlineCount);
    creditHeight = (creditHeightPerNewline * scale) * newlineCount;

    end_text = newHudElem();
    end_text.font = "objective";
    end_text.fontScale = scale;
    end_text SetText(credit);
    end_text.alignX = "center";
    end_text.alignY = "top";
    end_text.horzAlign = "center";
    end_text.vertAlign = "top";
    end_text.x = 0;
    end_text.y = 540;
    end_text.sort = -1; //-3
    end_text.alpha = 1;
    end_text.glowColor = (.1,.8,0);
    end_text.glowAlpha = 1;
    end_text moveOverTime(level.creditTime);
    end_text.y = level.endY;
    end_text.foreground = true;
    wait level.creditTime - 5;
    end_text destroy();
}

/**
 * @brief Shows credits center-tab-aligned like most movies
 *
 * @param label string The left-hand text containing the credit labels
 * @param credits string The right-hand text containing the name of the people being given credit
 *
 * @returns nothing
 */
showMovieStyleCredit(label, credits)
{
    log("trace", "msg|in _gamemodes::showMovieStyleCredit()||");

    scale = 1.8;                    // font scale, 1.4 is minimum cod4 accepts w/o errors
    creditTimePerNewline = 0.3;     // how long to show credit per newline in credits
    creditHeightPerNewline = 20;    // base height of each credit line in pixels

    newlineCount = tokenMatchCount(credits, "\n");
    level.creditTime = level.creditBasetime + (creditTimePerNewline * newlineCount);
    creditHeight = (creditHeightPerNewline * scale) * newlineCount;
    level.endY = 0 - creditHeight - 20;

    // Hud element for labels
    labelText = newHudElem();
    labelText.font = "objective";
    labelText.fontScale = scale;
    labelText SetText(label);
    labelText.alignX = "right"; // aligns *block* of text to the right, doesn't justify each line
    labelText.alignY = "top";
    labelText.justify = "right";
    labelText.horzAlign = "center";
    labelText.vertAlign = "top";
    labelText.x = -10;
    labelText.y = 540;
    labelText.sort = -1; //-3
    labelText.alpha = 1;
    labelText.glowColor = (.1,.8,0);
    labelText.glowAlpha = 1;
//     debugPrint("label width: " + labelText.width, "val");

    // Hud element for credits
    creditText = newHudElem();
    creditText.font = "objective";
    creditText.fontScale = scale;
    creditText SetText(credits);
    creditText.alignX = "left";  // How text is aligned within its bounding box
    creditText.alignY = "top";
    creditText.horzAlign = "center"; // origin relative to left edge, center of screen, or right edge
    creditText.vertAlign = "top";
    creditText.x = 10;
    creditText.y = 540;
    creditText.sort = -1; //-3
    creditText.alpha = 1;
    creditText.glowColor = (.1,.8,0);
    creditText.glowAlpha = 1;

    labelText moveOverTime(level.creditTime);
    labelText.y = level.endY; //-60
    labelText.foreground = true;

    creditText moveOverTime(level.creditTime);
    creditText.y = level.endY; //-60
    creditText.foreground = true;

    wait level.creditTime;

    labelText destroy();
    creditText destroy();
}

playEndSound()
{
    log("trace", "msg|in _gamemodes::playEndSound()||");

    playSoundOnPlayers("zom_outro");
}

playCreditsSound()
{
    log("trace", "msg|in _gamemodes::playCreditsSound()||");

    AmbientStop(0);
    AmbientPlay("ambient_tank" , 1);
}

playSoundOnPlayers(sound)
{
    log("trace", "msg|in _gamemodes::playSoundOnPlayers()||");

    for (i=0; i<level.players.size; i++) {
        level.players[i] playLocalSound(sound);
    }
}

freezePlayerForRoundEnd()
{
    log("trace", "msg|in _gamemodes::freezePlayerForRoundEnd()||");

    self closeMenu();
    self closeInGameMenu();

    self freezeControls( true );
}






