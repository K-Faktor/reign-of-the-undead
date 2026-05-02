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

init()
{
    log("trace", "msg|in _menus::init()||");

    game["menu_team"] = "team_marinesopfor";
    game["menu_class_allies"] = "class_marines";
    game["menu_changeclass_allies"] = "changeclass_marines_mw";
    game["menu_changeclass_ability"] = "changeclass_ability";
    game["menu_class_axis"] = "class_opfor";
//  game["menu_changeclass_axis"] = "changeclass_opfor_mw";
    game["menu_class"] = "class";
//  game["menu_changeclass"] = "changeclass_mw";
    game["menu_changeclass_offline"] = "changeclass_offline";
//  game["menu_welcome_inext"] = "welcome_inext"; /// @bug causes 'bad type' compile error

    game["menu_skillpoints"] = "skillpoints";  /// This is the menu to spend skillpoints

    game["menu_callvote"] = "callvote";
    game["menu_muteplayer"] = "muteplayer";
    game["menu_playermenu"] = "playermenu";
//     game["menu_mapvoting"] = "mapvoting";
    game["menu_extras"] = "extras_shop";
    game["menu_admin"] = "admin";
    game["menu_development"] = "development";
    precacheMenu(game["menu_callvote"]);
    precacheMenu(game["menu_muteplayer"]);
    precacheMenu(game["menu_playermenu"]);
    precachemenu(game["menu_skillpoints"]);
    precachemenu(game["menu_extras"]);
//     precachemenu(game["menu_mapvoting"]);
    precachemenu(game["menu_admin"]);
    precachemenu(game["menu_development"]);

    // game summary popups
    /*game["menu_eog_unlock"] = "popup_unlock";
    game["menu_eog_summary"] = "popup_summary";
    game["menu_eog_unlock_page1"] = "popup_unlock_page1";
    game["menu_eog_unlock_page2"] = "popup_unlock_page2";

    precacheMenu(game["menu_eog_unlock"]);
    precacheMenu(game["menu_eog_summary"]);
    precacheMenu(game["menu_eog_unlock_page1"]);
    precacheMenu(game["menu_eog_unlock_page2"]);*/

    precacheMenu("scoreboard");
    precacheMenu(game["menu_team"]);
//  precacheMenu(game["menu_welcome_inext"]);
    precacheMenu(game["menu_class_allies"]);
    precacheMenu(game["menu_changeclass_allies"]);
    precacheMenu(game["menu_class_axis"]);
//  precacheMenu(game["menu_changeclass_axis"]);
    precacheMenu(game["menu_class"]);
//  precacheMenu(game["menu_changeclass"]);
    precacheMenu(game["menu_changeclass_offline"]);
    precacheMenu(game["menu_changeclass_ability"]);
    precacheString( &"MP_HOST_ENDED_GAME" );
    precacheString( &"MP_HOST_ENDGAME_RESPONSE" );

    //MY SCRIPTMENUS
    game["menu_clientcmd"] = "clientcmd";
    precacheMenu(game["menu_clientcmd"]);

    //thread maps\mp\gametypes\_quickmessages::init();

    level thread onPlayerConnect();
}

onPlayerConnect()
{
    log("trace", "msg|in _menus::onPlayerConnect()||");

    for(;;) {
        level waittill("connected", player);

        player setClientDvar("ui_3dwaypointtext", "1");
        player.enable3DWaypoints = true;
        player setClientDvar("ui_deathicontext", "1");
        player setclientdvar( "g_scriptMainMenu", game["menu_class"] );
        player.enableDeathIcons = true;
        player.classType = undefined;
        player.selectedClass = false;
        //player openmenu(game["menu_welcome_inext"]);

        player thread onMenuResponse();
    }
}

onMenuResponse()
{
    log("trace", "msg|in _menus::onMenuResponse()||");

    self endon("disconnect");

    for(;;) {
        self waittill("menuresponse", menu, response);

        println( self getEntityNumber() + " menuresponse: " + menu + " " + response );

        if ( menu == game["menu_skillpoints"]) {
            switch(response)
            {
            case "upgr_soldier":
                self scripts\players\_classes::increaseClassRank("soldier");
                break;

            case "upgr_stealth":
                self scripts\players\_classes::increaseClassRank("stealth");
                break;

            case "upgr_armored":
                self scripts\players\_classes::increaseClassRank("armored");
                break;

            case "upgr_engineer":
                self scripts\players\_classes::increaseClassRank("engineer");
                break;
            case "upgr_scout":
                self scripts\players\_classes::increaseClassRank("scout");
                break;
            case "upgr_medic":
                self scripts\players\_classes::increaseClassRank("medic");
                break;
            }
        }

        if (response == "prestige") {
            self closeMenu();
            self closeInGameMenu();
            self scripts\players\_rank::prestigeUp();
        }
        if ( response == "back" )
        {
            self closeMenu();
            self closeInGameMenu();
            if ( menu == game["menu_changeclass_ability"] )
            {
                self openMenu( game["menu_changeclass_allies"] );
            }
            continue;
        }

        if( getSubStr( response, 0, 7 ) == "loadout" )
        {
            //self maps\mp\gametypes\_modwarfare::processLoadoutResponse( response );
            continue;
        }

        if( response == "changeteam" )
        {
            self closeMenu();
            self closeInGameMenu();
            self openMenu(game["menu_team"]);
        }

        if( response == "changeclass_marines" )
        {
            self closeMenu();
            self closeInGameMenu();
            self openMenu( game["menu_changeclass_allies"] );
            continue;
        }

        if( response == "changeclass_opfor" )
        {
            self closeMenu();
            self closeInGameMenu();
            self openMenu( game["menu_changeclass_axis"] );
            continue;
        }
        if (response == "admin")
        {
            self closeMenu();
            self closeInGameMenu();
            //self openMenu(game["menu_eog_unlock"]);
            /*if (self.isAdmin)
            {
                self closeMenu();
                self closeInGameMenu();
                self openMenu( "bxmod_admin" );
            }
            else
            self iprintlnbold("You are not allowed to use this menu");*/
        }

        if( response == "endgame" )
        {
            continue;
        }
        if ( isSubStr(response, "SC_") ) // Process secondary abilities
        {
            ability = GetSubStr(response, 3);
            self thread  scripts\players\_classes::pickSecondary(ability);
        }
        if ( menu == game["menu_changeclass_ability"])
        {
            if (response == "accept")
            {
                self closeMenu();
                self closeInGameMenu();
                //self openmenu(game["menu_changeweapon"]);

            }
            self thread scripts\players\_classes::acceptClass();

        }

        if (menu == game["menu_extras"])
        {
            self closeMenu();
            self closeInGameMenu(
            scripts\players\_shop::processResponse(response));
        }

        if( menu == game["menu_team"] )
        {
            switch(response)
            {
            case "allies":
                self closeMenu();
                self closeInGameMenu();
                self scripts\players\_players::joinAllies();
                self thread scripts\players\_classes::monitorEnabledClasses();
                self openMenu(game["menu_changeclass_allies"]);
                break;

            case "autoassign":
                self closeMenu();
                self closeInGameMenu();
                self scripts\players\_players::joinAllies();
                self thread scripts\players\_classes::monitorEnabledClasses();
                self openMenu(game["menu_changeclass_allies"]);
                break;

            case "spectator":
                self closeMenu();
                self closeInGameMenu();
                self scripts\players\_players::joinSpectator();
                break;
            }
        }   // the only responses remain are change class events
        else if( menu == game["menu_changeclass_allies"]  )
        {
            self closeMenu();
            self closeInGameMenu();
            // log("dev", "msg|279: soldier class respone is: " + response + "||");
            thread  scripts\players\_classes::pickClass(response);
            continue;
        }
/*      else if( menu == game["menu_changeclass"] )
        {
            self closeMenu();
            self closeInGameMenu();

            self.selectedClass = true;
            //self maps\mp\gametypes\_modwarfare::menuAcceptClass();
        }*/
        else
        {
            //if(menu == game["menu_playermenu"])
            //  maps\mp\gametypes\_players::processPlayerMenu(response);
            //else if(menu == game["menu_playermenu"])
            //  zombiesurvival\_main::processPlayerMenu(response);
        }

    }
}
