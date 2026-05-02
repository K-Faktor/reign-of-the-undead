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
 * @file _adminInterface.gsc This file sets up the in-game admin interface to the admin commands
 */

#include scripts\include\utility;
#include scripts\include\adminCommon;

init()
{}

/**
 * @brief is the player an admin?
 *
 * @param player The player to check if they are an admin
 *
 * @returns true if admin, otherwise false
 */
isAdmin(player)
{
    log("trace", "msg|in _adminInterface::isAdmin()||");

    if (isDefined(player.admin) && player.admin.isAdmin) { return true;}
    return false;
}

/**
 * @brief Opens the in-game admin menu if the player is recognized as an admin
 *
 * @returns nothing
 */
onOpenAdminMenuRequest()
{
    log("trace", "msg|in _adminInterface::onOpenAdminMenuRequest()||");

    if (isAdmin(self)) {
        self onOpenAdminMenu();
        self openMenu(game["menu_admin"]);
    }
}

/**
 * @brief Opens the admin menu on 'use' key if the admin is spectating
 *
 * @returns nothing
 */
watchForAdminSpectatorOpenMenuRequests()
{
    log("trace", "msg|in _adminInterface::watchForAdminSpectatorOpenMenuRequests()||");

    self endon("disconnect");

    while (1) {
        wait 0.1;
        if ((self.isSpectating) && (self useButtonPressed())) {
            onOpenAdminMenuRequest();
        }
    }
}

/**
 * @brief Initializes this use of the admin menu
 *
 * @returns nothing
 */
onOpenAdminMenu()
{
    log("trace", "msg|in _adminInterface::onOpenAdminMenu()||");

    if (isAdmin(self)) {
        self.admin.adminMenuOpen = true;
        log("server", "msg|Enabling god mode for admin: " + self.admin.playerName + "||");
        self.isGod = true;
        self.god = true;
        self.isTargetable = false;
        showPlayerInfo();
    } else {
        self closeMenu();
        self closeInGameMenu();
        log("warn", "msg|" + self.name + " opened the admin menu, but we forced it closed.||");
        self thread ACPNotify( "You don't have permission to access this menu.", 3 );
        return;
    }
}

/**
 * @brief Ensures that only valid players are shown in the admin menu
 *
 * @returns nothing
 */
watchAdminMenuData()
{
    log("trace", "msg|in _adminInterface::watchAdminMenuData()||");

    self endon("disconnect");

    while (1) {
        if (!isDefined(level.players)){continue;}
        if (self.admin.adminMenuOpen && self.admin.isAdminMenuDirty) {
            // self.selectedPlayerIndex may not point to the player it was pointing
            // to when it was last set, because players joined or left the game
            if(!self validateSelectedPlayer()) {
                selectNextPlayer();
                self.admin.isAdminMenuDirty = false;
                displayAdminCommandFeedback("Player invalid, selecting next player.");
                log("server", "msg|Admin menu's displayed player info is no longer valid, selecting next player.||");
            }
        }
        wait 1;
    }
}

/**
 * @brief Tests whether the curretnly shown player is valid or not
 *
 * @returns boolean True if the player is valid, false otherwise
 */
validateSelectedPlayer()
{
    log("trace", "msg|in _adminInterface::validateSelectedPlayer()||");

    if (!isDefined(self.selectedPlayerEntityNumber)) {return false;}

    livePlayer = getPlayerByEntityNumber(self.selectedPlayerEntityNumber);

    if ((!isDefined(livePlayer)) || (!isDefined(livePlayer.shortGuid)) || (!isDefined(livePlayer.name))) {
        // The selected entity number isn't in the game anymore, so the UI selected
        // player data is incorrect
        return false;
    }
    if ((livePlayer.shortGuid != self.selectedPlayerShortGuid) ||
        (livePlayer.name != self.selectedPlayerName)) {
           // the selected entity number has been reassigned, so the UI selected
           // player data is incorrect
           return false;
    }
    if (getPlayerIndexByNum(self.selectedPlayerEntityNumber) != self.selectedPlayerIndex) {
        // The player's position in the player's array has changed.  This will affect
        // next/prev, but shouldn't affect out ability to execute admin commands on the player
        return true;
    }
    // Nothing has changed with repsect to this player
    return true;
}

//   5:00 Debug: name                   index playerNumber    guid                    active alive down bot
//   5:00 Debug:         |PZA| Pulsar  0   20 91668de969960da261a12934105882d0     1   1   0   0
//   5:00 Debug:               player  1   25 f0b4f8b9b276eeda57312b9e8d4f9328     0   0   0   0
//   5:00 Debug:       |PZA| SPC Taff  2   21 92785c30e612c0ed2912a872dcf4d9e5     0   0   0   0
//   5:00 Debug:           (GER)Futzy  3   23 0eb2a4a9490dbfa8bbbfff1f8369bd4f     1   0   1   0
//   5:00 Debug:       {BCT}Fuzzynuts  5   19 d4df0e8da021286a95f8f8e764476671     1   0   1   0
//   5:00 Debug:      raul schuurmans  4   27 36ffaef045f0875c8b3c3a9b2d8aba8a     1   0   1   0
//   5:00 Debug:           Millennium  6   28 36ffaef045f0875c8b3c3a9b2d8aba8a     1   0   1   0
//   5:00 Debug:             DoKdudek  7   24 d5d1a6812ceacf3c408b6bf0a7adece8     1   0   1   0
//   5:00 Debug:                kusba  8   30 60fad2f83f576f3ed3470c2af5b4dd40     1   0   1   0
//   5:00 Debug:         heroinBianca  9   26 9a0a0aef196900d57442659bfbdd6ffc     0   0   0   0
//   5:00 Debug: alive: 1 active: 7 down: 6
//
//  10:00 Debug: name                   index playerNumber    guid                    active alive down bot
//  10:00 Debug:         |PZA| Pulsar  0   20 91668de969960da261a12934105882d0     1   1   0   0
//  10:00 Debug:               player  1   25 f0b4f8b9b276eeda57312b9e8d4f9328     1   0   1   0
//  10:00 Debug:       |PZA| SPC Taff  2   21 92785c30e612c0ed2912a872dcf4d9e5     1   1   0   0
//  10:00 Debug:           (GER)Futzy  3   23 0eb2a4a9490dbfa8bbbfff1f8369bd4f     1   1   0   0
//  10:00 Debug:      raul schuurmans  4   27 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  10:00 Debug:       {BCT}Fuzzynuts  5   19 d4df0e8da021286a95f8f8e764476671     1   0   1   0
//  10:00 Debug:           Millennium  6   28 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  10:00 Debug:             DoKdudek  7   24 d5d1a6812ceacf3c408b6bf0a7adece8     1   1   0   0
//  10:00 Debug:                kusba  8   30 60fad2f83f576f3ed3470c2af5b4dd40     1   1   0   0
//  10:00 Debug:         heroinBianca  9   26 9a0a0aef196900d57442659bfbdd6ffc     1   1   0   0
//  10:00 Debug: alive: 8 active: 10 down: 2
//
//
//  15:00 Debug: name                   index playerNumber    guid                    active alive down bot
//  15:00 Debug:         |PZA| Pulsar  0   20 91668de969960da261a12934105882d0     1   1   0   0
//  15:00 Debug:               player  1   25 f0b4f8b9b276eeda57312b9e8d4f9328     1   0   1   0
//  15:00 Debug:       |PZA| SPC Taff  2   21 92785c30e612c0ed2912a872dcf4d9e5     1   0   1   0
//  15:00 Debug:           (GER)Futzy  3   23 0eb2a4a9490dbfa8bbbfff1f8369bd4f     1   1   0   0
//  15:00 Debug:      raul schuurmans  4   27 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  15:00 Debug:           Millennium  5   28 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  15:00 Debug:             DoKdudek  6   24 d5d1a6812ceacf3c408b6bf0a7adece8     1   0   1   0
//  15:00 Debug:                kusba  7   30 60fad2f83f576f3ed3470c2af5b4dd40     1   1   0   0
//  15:00 Debug:         heroinBianca  8   26 9a0a0aef196900d57442659bfbdd6ffc     1   1   0   0
//  15:00 Debug: alive: 6 active: 9 down: 3
//
//  20:00 Debug: name                   index playerNumber    guid                    active alive down bot
//  20:00 Debug:         |PZA| Pulsar  0   20 91668de969960da261a12934105882d0     1   1   0   0
//  20:00 Debug:               player  1   25 f0b4f8b9b276eeda57312b9e8d4f9328     1   0   1   0
//  20:00 Debug:       |PZA| SPC Taff  2   21 92785c30e612c0ed2912a872dcf4d9e5     1   0   1   0
//  20:00 Debug:           (GER)Futzy  3   23 0eb2a4a9490dbfa8bbbfff1f8369bd4f     1   1   0   0
//  20:00 Debug:      raul schuurmans  4   27 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  20:00 Debug:           Millennium  5   28 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  20:00 Debug:                kusba  6   30 60fad2f83f576f3ed3470c2af5b4dd40     1   1   0   0
//  20:00 Debug:         heroinBianca  7   26 9a0a0aef196900d57442659bfbdd6ffc     1   0   1   0
//  20:00 Debug:            WTFKiller  8   24 7e4e1be0025118b132daf6704c1a2a96     1   1   0   0
//  20:00 Debug:            Mr. Agent  9   29 f0b4f8b9b276eeda57312b9e8d4f9328     1   1   0   0
//  20:00 Debug: alive: 7 active: 10 down: 3
//
//  25:00 Debug: name                   index playerNumber    guid                    active alive down bot
//  25:00 Debug:         |PZA| Pulsar  0   20 91668de969960da261a12934105882d0     1   1   0   0
//  25:00 Debug:               player  1   25 f0b4f8b9b276eeda57312b9e8d4f9328     1   1   0   0
//  25:00 Debug:       |PZA| SPC Taff  2   21 92785c30e612c0ed2912a872dcf4d9e5     1   1   0   0
//  25:00 Debug:           (GER)Futzy  3   23 0eb2a4a9490dbfa8bbbfff1f8369bd4f     1   1   0   0
//  25:00 Debug:           Millennium  4   28 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  25:00 Debug:                kusba  5   30 60fad2f83f576f3ed3470c2af5b4dd40     1   1   0   0
//  25:00 Debug:         heroinBianca  6   26 9a0a0aef196900d57442659bfbdd6ffc     1   1   0   0
//  25:00 Debug:            WTFKiller  7   24 7e4e1be0025118b132daf6704c1a2a96     1   1   0   0
//  25:00 Debug:            Mr. Agent  8   29 f0b4f8b9b276eeda57312b9e8d4f9328     1   1   0   0
//  25:00 Debug:        zombie killer  9   19 16a565290047e2c9ea758fa0ea93b9d4     1   1   0   0
//  25:00 Debug:                Hazar  10  31 ca533355492b75bd82580995cf2fffa1     1   1   0   0
//  25:00 Debug: alive: 11 active: 11 down: 0
//
//  30:00 Debug: name                   index playerNumber    guid                    active alive down bot
//  30:00 Debug:         |PZA| Pulsar  0   20 91668de969960da261a12934105882d0     1   0   1   0
//  30:00 Debug:               player  1   25 f0b4f8b9b276eeda57312b9e8d4f9328     1   0   1   0
//  30:00 Debug:       |PZA| SPC Taff  2   21 92785c30e612c0ed2912a872dcf4d9e5     1   1   0   0
//  30:00 Debug:           (GER)Futzy  3   23 0eb2a4a9490dbfa8bbbfff1f8369bd4f     1   0   1   0
//  30:00 Debug:           Millennium  4   28 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  30:00 Debug:                kusba  5   30 60fad2f83f576f3ed3470c2af5b4dd40     1   0   1   0
//  30:00 Debug:         heroinBianca  6   26 9a0a0aef196900d57442659bfbdd6ffc     1   0   1   0
//  30:00 Debug:            WTFKiller  7   24 7e4e1be0025118b132daf6704c1a2a96     1   0   1   0
//  30:00 Debug:            Mr. Agent  8   29 f0b4f8b9b276eeda57312b9e8d4f9328     1   0   1   0
//  30:00 Debug:        zombie killer  9   19 16a565290047e2c9ea758fa0ea93b9d4     1   0   1   0
//  30:00 Debug:              tommort  10  27 0b616a077c28a2568931bffd8045bd1f     1   0   1   0
//  30:00 Debug:           zlatan psg  11  32 c6bd49da05e61713cdff8b5e2910e763     1   1   0   0
//  30:00 Debug:      {BullS} Pusher#  12  31 36ffaef045f0875c8b3c3a9b2d8aba8a     1   0   1   0
//  30:00 Debug: alive: 3 active: 13 down: 10
//
//  35:00 Debug: name                   index playerNumber    guid                    active alive down bot
//  35:00 Debug:         |PZA| Pulsar  0   20 91668de969960da261a12934105882d0     1   1   0   0
//  35:00 Debug:               player  1   25 f0b4f8b9b276eeda57312b9e8d4f9328     1   0   1   0
//  35:00 Debug:       |PZA| SPC Taff  2   21 92785c30e612c0ed2912a872dcf4d9e5     1   1   0   0
//  35:00 Debug:           (GER)Futzy  3   23 0eb2a4a9490dbfa8bbbfff1f8369bd4f     1   0   1   0
//  35:00 Debug:           Millennium  4   28 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  35:00 Debug:                kusba  5   30 60fad2f83f576f3ed3470c2af5b4dd40     1   0   1   0
//  35:00 Debug:         heroinBianca  6   26 9a0a0aef196900d57442659bfbdd6ffc     1   0   1   0
//  35:00 Debug:            WTFKiller  7   24 7e4e1be0025118b132daf6704c1a2a96     1   1   0   0
//  35:00 Debug:            Mr. Agent  8   29 f0b4f8b9b276eeda57312b9e8d4f9328     1   0   1   0
//  35:00 Debug:        zombie killer  9   19 16a565290047e2c9ea758fa0ea93b9d4     1   1   0   0
//  35:00 Debug:              tommort  10  27 0b616a077c28a2568931bffd8045bd1f     1   0   1   0
//  35:00 Debug:           zlatan psg  11  32 c6bd49da05e61713cdff8b5e2910e763     1   1   0   0
//  35:00 Debug:      {BullS} Pusher#  12  31 36ffaef045f0875c8b3c3a9b2d8aba8a     1   0   1   0
//  35:00 Debug: alive: 6 active: 13 down: 7
//
//  40:00 Debug: name                   index playerNumber    guid                    active alive down bot
//  40:00 Debug:         |PZA| Pulsar  0   20 91668de969960da261a12934105882d0     1   0   1   0
//  40:00 Debug:               player  1   25 f0b4f8b9b276eeda57312b9e8d4f9328     1   0   1   0
//  40:00 Debug:       |PZA| SPC Taff  2   21 92785c30e612c0ed2912a872dcf4d9e5     1   0   1   0
//  40:00 Debug:           (GER)Futzy  3   23 0eb2a4a9490dbfa8bbbfff1f8369bd4f     1   0   1   0
//  40:00 Debug:           Millennium  4   28 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  40:00 Debug:                kusba  5   30 60fad2f83f576f3ed3470c2af5b4dd40     1   0   1   0
//  40:00 Debug:         heroinBianca  6   26 9a0a0aef196900d57442659bfbdd6ffc     1   0   1   0
//  40:00 Debug:            WTFKiller  7   24 7e4e1be0025118b132daf6704c1a2a96     1   0   1   0
//  40:00 Debug:            Mr. Agent  8   29 f0b4f8b9b276eeda57312b9e8d4f9328     1   0   1   0
//  40:00 Debug:        zombie killer  9   19 16a565290047e2c9ea758fa0ea93b9d4     1   0   1   0
//  40:00 Debug:              tommort  10  27 0b616a077c28a2568931bffd8045bd1f     1   0   1   0
//  40:00 Debug:      {BullS} Pusher#  11  31 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  40:00 Debug:      |2PFY|BuddiePro  12  33 c1498bf25d817e59ab8a9c40a2119014     1   0   1   0
//  40:00 Debug:                PPMAN  13  35 ef792af84945df4c815163a1ca0bc400     0   0   0   0
//  40:00 Debug:        Chimera123rix  14  34 6c37e128b47f3a9505564e041bc9a1f6     0   0   0   0
//  40:00 Debug: alive: 2 active: 13 down: 11
//
//  45:00 Debug: name                   index playerNumber    guid                    active alive down bot
//  45:00 Debug:         |PZA| Pulsar  0   20 91668de969960da261a12934105882d0     1   1   0   0
//  45:00 Debug:       |PZA| SPC Taff  1   21 92785c30e612c0ed2912a872dcf4d9e5     1   1   0   0
//  45:00 Debug:           (GER)Futzy  2   23 0eb2a4a9490dbfa8bbbfff1f8369bd4f     1   1   0   0
//  45:00 Debug:           Millennium  3   28 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  45:00 Debug:                kusba  4   30 60fad2f83f576f3ed3470c2af5b4dd40     1   1   0   0
//  45:00 Debug:         heroinBianca  5   26 9a0a0aef196900d57442659bfbdd6ffc     1   1   0   0
//  45:00 Debug:            WTFKiller  6   24 7e4e1be0025118b132daf6704c1a2a96     1   1   0   0
//  45:00 Debug:            Mr. Agent  7   29 f0b4f8b9b276eeda57312b9e8d4f9328     1   1   0   0
//  45:00 Debug:        zombie killer  8   19 16a565290047e2c9ea758fa0ea93b9d4     1   1   0   0
//  45:00 Debug:              tommort  9   27 0b616a077c28a2568931bffd8045bd1f     1   1   0   0
//  45:00 Debug:      |2PFY|BuddiePro  10  33 c1498bf25d817e59ab8a9c40a2119014     1   1   0   0
//  45:00 Debug:                PPMAN  11  35 ef792af84945df4c815163a1ca0bc400     1   1   0   0
//  45:00 Debug:        Chimera123rix  12  34 6c37e128b47f3a9505564e041bc9a1f6     1   1   0   0
//  45:00 Debug: alive: 13 active: 13 down: 0
//
//   50:00 Debug: name                   index playerNumber    guid                    active alive down bot
//  50:00 Debug:         |PZA| Pulsar  0   20 91668de969960da261a12934105882d0     1   1   0   0
//  50:00 Debug:       |PZA| SPC Taff  1   21 92785c30e612c0ed2912a872dcf4d9e5     1   1   0   0
//  50:00 Debug:           (GER)Futzy  2   23 0eb2a4a9490dbfa8bbbfff1f8369bd4f     1   0   1   0
//  50:00 Debug:           Millennium  3   28 36ffaef045f0875c8b3c3a9b2d8aba8a     1   1   0   0
//  50:00 Debug:                kusba  4   30 60fad2f83f576f3ed3470c2af5b4dd40     1   1   0   0
//  50:00 Debug:         heroinBianca  5   26 9a0a0aef196900d57442659bfbdd6ffc     1   1   0   0
//  50:00 Debug:            WTFKiller  6   24 7e4e1be0025118b132daf6704c1a2a96     1   1   0   0
//  50:00 Debug:        zombie killer  7   19 16a565290047e2c9ea758fa0ea93b9d4     1   1   0   0
//  50:00 Debug:              tommort  8   27 0b616a077c28a2568931bffd8045bd1f     1   1   0   0
//  50:00 Debug:      |2PFY|BuddiePro  9   33 c1498bf25d817e59ab8a9c40a2119014     1   0   1   0
//  50:00 Debug:                PPMAN  10  35 ef792af84945df4c815163a1ca0bc400     1   1   0   0
//  50:00 Debug:        Chimera123rix  11  34 6c37e128b47f3a9505564e041bc9a1f6     1   1   0   0
//  50:00 Debug:       =F|A= Guardian  12  25 0fa30dee0cfc080f8865683a63e8e277     1   1   0   0
//  50:00 Debug:                Hazar  13  32 ca533355492b75bd82580995cf2fffa1     1   1   0   0
//  50:00 Debug:            Mr. Agent  14  29 f0b4f8b9b276eeda57312b9e8d4f9328     1   1   0   0
//  50:00 Debug:                ZQhis  15  36 189d5c828df312f035fe2132f005c49d     1   1   0   0
//  50:00 Debug: alive: 14 active: 16 down: 2
//
//
// player indexes change as players are removed from the players array.  player
// entity numbers are fairly constant, but *may* change when a player leaves and
// rejoins then game.  Seems the game assigns the lowest available entity number
// to a joining player, which may have previously belonged to them, or to another
// player.

/**
 * @brief Removes admin's god mode two seconds after they close the admin menu
 *
 * @returns nothing
 */
onCloseAdminMenu()
{
    log("trace", "msg|in _adminInterface::onCloseAdminMenu()||");

    self.admin.adminMenuOpen = false;

    wait level.adminMenuGodModeTimeout;
    if (self.admin.adminMenuOpen) {
        // Do nothing if admin menu was reopend in the last 2 seconds
        log("server", "msg|Disabling god mode canceled because menu re-opened within timeout for admin: " + self.admin.playerName + "||");
    } else {
        self.isGod = false;
        self.god = false;
        self.isTargetable = true;
        log("server", "msg|Disabling god mode for admin: " + self.admin.playerName + "||");
    }
}


/**
 * @brief Informs the admin they do not have permission to use a given command
 *
 * @returns nothing
 */
onNoPermissions()
{
    log("trace", "msg|in _adminInterface::onNoPermissions()||");

    self thread ACPNotify( "You don't have permission to use this command.", 3 );
}


/**
 * @brief Watches the admin menu for commands, then processes them
 *
 * @returns nothing
 */
watchAdminMenuResponses()
{
    log("trace", "msg|in _adminInterface::watchAdminMenuResponses()||");

    self endon( "disconnect" );
    // threaded on each admin player

    while (1) {
        self waittill( "menuresponse", menu, response );
        log("dev", "msg|menu: " + menu + " response: " + response + "||");

        // menu "-1" is the main in-game popup menu bound to the 'b' key
        if ((menu == "-1") && (response == "admin_menu_open_request")) {
            self onOpenAdminMenuRequest();
            continue;
        }

        // If menu isn't an admin menu, then bail
        if ((menu != "admin") &&
            (menu != "admin_kick") &&
            (menu != "admin_ban") &&
            (menu != "admin_temp_ban") &&
            (menu != "admin_changemap") &&
            (menu != "admin_warn"))
        {
            log("dev", "msg|Menu is not an admin menu.||"); // <debug />
            continue;
        }

        // Cancel the command if the UI player data is incorrect
        if(!self validateSelectedPlayer()) {
            selectNextPlayer();
            displayAdminCommandFeedback("Player invalid, admin command canceled, next player selected.");
            log("server", "msg|Player invalid, admin command canceled, selecting next player.||");
            continue;
        }

        // detect keypresses for the change map command's filter
        if ((menu == "admin_changemap") && isSubStr(response, "filter:")) {
            tokens = StrTok(response, ":");
            character = tokens[1];
            // log("dev", "msg|Detected filter character: " + character + "||");
            switch(character) {
                case "space": character = " "; break;
                case "[":     character = "("; break;
                case "]":     character = "]"; break;
                case ".":     character = "_"; break;
                default: // do nothing
                    break;
            }
            changeMapUpdateFilter(character);
        }

        // log("dev", "msg|menu repsonse is: " + response + "||");
        switch(response)
        {
        case "admin_next":
            selectNextPlayer();
            break;
        case "admin_prev":
            selectPreviousPlayer();
            break;
        case "admin_menu_close":
            thread onCloseAdminMenu();
            break;

        /** Punishment */
        case "admin_down":
            downPlayer(self.selectedPlayerEntityNumber);
            break;
        case "admin_boom":
            explodePlayer(self.selectedPlayerEntityNumber);
            break;
        case "admin_drop":
            dropPlayerWeapon(self.selectedPlayerEntityNumber);
            break;
        case "admin_disarm":
            disarmPlayer(self.selectedPlayerEntityNumber);
            break;
        case "admin_take_current_weapon":
            takePlayersCurrentWeapon(self.selectedPlayerEntityNumber);
            break;
        case "admin_demote":
            demotePlayer(self.selectedPlayerEntityNumber);
            break;

        /** Reward */
        case "admin_promote":
            promotePlayer(self.selectedPlayerEntityNumber);
            break;
        case "admin_restore_primary_weapon":
            restorePlayersPrimaryWeapon(self.selectedPlayerEntityNumber);
            break;
        case "admin_restore_sidearm":
            restorePlayersSidearm(self.selectedPlayerEntityNumber);
            break;
        case "admin_give_upgrade_points":
            givePlayerUpgradePoints(self.selectedPlayerEntityNumber);
            break;

        /** Banning */
        case "admin_warn_general":
            /// if session is visible, reason will become "[Admin's Name] decision."
            warnPlayer(self.selectedPlayerEntityNumber, "admin_name");
            break;
        case "admin_warn_language":
            warnPlayer(self.selectedPlayerEntityNumber, "Bad Language");
            break;
        case "admin_warn_silent":
            warnPlayer(self.selectedPlayerEntityNumber, "silent");
            break;
        case "admin_remove_one_warning":
            removeOneWarning(self.selectedPlayerEntityNumber);
            break;
        case "admin_remove_one_language_warning":
            removeOneLanguageWarning(self.selectedPlayerEntityNumber);
            break;
        case "admin_remove_all_warnings":
            removeAllWarnings(self.selectedPlayerEntityNumber);
            break;

        case "admin_temp_ban_general":
            /// if session is visible, reason will become "[Admin's Name] decision."
            temporarilyBanPlayer(self.selectedPlayerEntityNumber, "admin_name");
            break;
        case "admin_temp_ban_glitching":
            temporarilyBanPlayer(self.selectedPlayerEntityNumber, "Glitching");
            break;
        case "admin_temp_ban_cheating":
            temporarilyBanPlayer(self.selectedPlayerEntityNumber, "Cheating");
            break;
        case "admin_temp_ban_language":
            temporarilyBanPlayer(self.selectedPlayerEntityNumber, "Bad Language");
            break;
        case "admin_temp_ban_silent":
            temporarilyBanPlayer(self.selectedPlayerEntityNumber, "silent");
            break;

        case "admin_kick_general":
            /// if session is visible, reason will become "[Admin's Name] decision."
            kickPlayer(self.selectedPlayerEntityNumber, "admin_name");
            break;
        case "admin_kick_glitching":
            kickPlayer(self.selectedPlayerEntityNumber, "Glitching");
            break;
        case "admin_kick_cheating":
            kickPlayer(self.selectedPlayerEntityNumber, "Cheating");
            break;
        case "admin_kick_language":
            kickPlayer(self.selectedPlayerEntityNumber, "Bad Language");
            break;
        case "admin_kick_silent":
            kickPlayer(self.selectedPlayerEntityNumber, "silent");
            break;
        case "admin_ban_general":
            /// if session is visible, reason will become "[Admin's Name] decision."
            banPlayer(self.selectedPlayerEntityNumber, "admin_name");
            break;
        case "admin_ban_glitching":
            banPlayer(self.selectedPlayerEntityNumber, "Glitching");
            break;
        case "admin_ban_cheating":
            banPlayer(self.selectedPlayerEntityNumber, "Cheating");
            break;
        case "admin_ban_language":
            banPlayer(self.selectedPlayerEntityNumber, "Bad Language");
            break;
        case "admin_ban_silent":
            banPlayer(self.selectedPlayerEntityNumber, "silent");
            break;


        /** Miscellaneous */
        case "admin_bounce":
            bouncePlayer(self.selectedPlayerEntityNumber);
            break;
        case "admin_teleport_to_spawn":
            teleportPlayerToSpawn(self.selectedPlayerEntityNumber);
            break;
        case "admin_teleport_to_admin":
            teleportPlayerToAdmin(self.selectedPlayerEntityNumber);
            break;
        case "admin_teleport_forward":
            teleportPlayerForward(self.selectedPlayerEntityNumber);
            break;
        case "admin_session_visibility":
            toggleAdminSessionVisibility();
            break;
        case "admin_kill_zombies":
            killZombies();
            break;

        /** Assist Players */
        case "admin_spawn":
            spawnPlayer(self.selectedPlayerEntityNumber);
            break;
        case "admin_cure":
            curePlayer(self.selectedPlayerEntityNumber);
            break;
        case "admin_heal":
            healPlayer(self.selectedPlayerEntityNumber);
            break;
        case "admin_revive":
            revivePlayer(self.selectedPlayerEntityNumber);
            break;
        case "admin_ammo":
            ammoBox(self.selectedPlayerEntityNumber);
            break;
        case "admin_aura":
            healingAura(self.selectedPlayerEntityNumber);
            break;

        /** Game */
        case "admin_restart_wave":
            restartWave();
            break;
        case "admin_restart_map":
            restartMap();
            break;
        case "admin_finish_wave":
            finishWave();
            break;
        case "admin_finish_map":
            finishMap();
            break;
        case "admin_changemap_accept":
            changeMap();
            break;
        case "admin_changemap_cancel":
            onCancelChangeMap();
            break;
        case "admin_changemap_apply_filter":
            // log("dev", "msg|Filter: " + filter + "||");
            applyMapFilter();
            break;
        case "admin_open_changemap":
            onOpenChangeMap();
            break;
        case "admin_changemap_backspace":
            changeMapFilterBackspace();
            break;
        default:
            // Do nothing
            break;
        } // end switch(response)

    } // End while(1)
}

/**
 * @brief Converts a player number from a string to an integer
 *
 * @param stringPlayerNumber string The player number as a string
 *
 * @returns integer The player number cast as an integer
 */
intPlayerNumber(stringPlayerNumber)
{
    log("trace", "msg|in _adminInterface::intPlayerNumber()||");

    // log("dev", "msg|stringPlayerNumber: " + stringPlayerNumber + "||");
    if (!isDefined(level.players)) {
        log("bug", "msg|level.players is undefined.||");
    }
    return int(level.players[stringPlayerNumber] getEntityNumber());
}

/**
 * @brief Displays a message next to the admin menu
 *
 * @param text string The text to display
 * @param time string The amount of time to display the text
 *
 * @returns nothing
 */
ACPNotify(text, time)
{
    log("trace", "msg|in _adminInterface::ACPNotify()||");

    self notify("acp_notify");
    self endon("acp_notify");
    self endon("disconnect");

    self setClientDvar("admin_txt", text);
    wait time;
    self setClientDvar("admin_txt", "");
}


/**
 * @brief Selects the next player
 *
 * @returns nothing
 */
selectNextPlayer()
{
    log("trace", "msg|in _adminInterface::selectNextPlayer()||");
    players = level.players;

    self.selectedPlayerIndex++;

    // wrap around the array bounds
    if( self.selectedPlayerIndex >= players.size ) {
        self.selectedPlayerIndex = 0;
    }
    self.selectedPlayerName = players[self.selectedPlayerIndex].name;
    self.selectedPlayerShortGuid = players[self.selectedPlayerIndex].shortGuid;
    self.selectedPlayerEntityNumber = players[self.selectedPlayerIndex] getEntityNumber();
    showPlayerInfo();
}


/**
 * @brief Selects the previous player
 *
 * @returns nothing
 */
selectPreviousPlayer()
{
    log("trace", "msg|in _adminInterface::selectPreviousPlayer()||");
    players = level.players;
    self.selectedPlayerIndex--;

    // wrap around the array bounds
    if( self.selectedPlayerIndex <= -1 ) {
        self.selectedPlayerIndex = players.size-1;
    }
    self.selectedPlayerName = players[self.selectedPlayerIndex].name;
    self.selectedPlayerShortGuid = players[self.selectedPlayerIndex].shortGuid;
    self.selectedPlayerEntityNumber = players[self.selectedPlayerIndex] getEntityNumber();
    showPlayerInfo();
}


/**
 * @brief Updates the selected player's info in the admin menu
 *
 * @returns nothing
 */
showPlayerInfo()
{
    log("trace", "msg|in _adminInterface::showPlayerInfo()||");

    if (!isDefined(self.selectedPlayerIndex)) {
        log("bug", "msg|for " + self.name + " self.selectedPlayerIndex is undefined; cannot show player info.||");
        return;
    }
    player = level.players[self.selectedPlayerIndex];
    if(!isDefined(player)) {return;}

    if (!isDefined(self.selectedPlayerName)) {self.selectedPlayerName = player.name;}
    if (!isDefined(self.selectedPlayerShortGuid)) {self.selectedPlayerShortGuid = player.shortGuid;}
    if (!isDefined(self.selectedPlayerEntityNumber)) {self.selectedPlayerEntityNumber = player getEntityNumber();}

    self.spectatorclient = player getEntityNumber();
    // This info only gets updated when an admin uses the next/previous player menu options,
    // as it doesn't change frequently
    self setClientDvars( "admin_p_n", player.name,
                         "admin_p_t", getTeamName(player),
                         "admin_p_rpd", getRankPresitgeDemerits(player),
                         "admin_p_g", player.guid);
    // Thread updates to the perishable player info
    self thread updatePerishablePlayerInfo(player, self.selectedPlayerIndex);
}

/**
 * @brief Updates frequently changed player info
 *
 * @param player The player whose data we should update
 * @param selectedPlayer The player that was selected in the menu when this function was called
 *
 * @returns nothing
 */
updatePerishablePlayerInfo(player, selectedPlayer)
{
    log("trace", "msg|in _adminInterface::updatePerishablePlayerInfo()||");

    self endon("disconnect");

    while (self.admin.adminMenuOpen && isDefined(player)) {
        // Bail if originally selected player has changed
        if (selectedPlayer != self.selectedPlayerIndex) {return;}

        self setClientDvars("admin_p_h", (player.health + "/" + player.maxhealth),
                            "admin_p_w", getPlayersWarnings(player),
                            "admin_p_s", getPlayerStatus(player),
                            "admin_p_skd", (player.score + "-" + player.kills + "-" + player.deaths));
        wait 3; // update every three seconds
    }
}


/**
 * @brief Gets the player's warnings
 *
 * @param player The player to get warning counts for
 *
 * @returns string player's warnings
 */
getPlayersWarnings(player)
{
    log("trace", "msg|in _adminInterface::getPlayersWarnings()||");

    if (player.pers["badLanguageWarnings"] == level.badLanguageWarningTempBanThreshold - 1) {
        nextLanguage = "TempBan";
    } else if (player.pers["badLanguageWarnings"] == level.badLanguageWarningBanThreshold - 1) {
        nextLanguage = "Ban";
    } else {nextLanguage = "Warn";}

    if (player.pers["generalWarnings"] == level.generalWarningTempBanThreshold - 1) {
        nextGeneral = "TempBan";
    } else if (player.pers["generalWarnings"] == level.generalWarningBanThreshold - 1) {
        nextGeneral = "Ban";
    } else {nextGeneral = "Warn";}

    result = player.pers["badLanguageWarnings"] + "(" + nextLanguage + ")/" + player.pers["generalWarnings"] + "(" + nextGeneral + ")";

    return result;
}

/**
 * @brief Gets the player's rank, prestige, and demerits
 *
 * @param player The player to get information for
 *
 * @returns string player's rank, prestige, and demerits
 */
getRankPresitgeDemerits(player)
{
    log("trace", "msg|in _adminInterface::getRankPresitgeDemerits()||");

    prestige = player scripts\players\_rank::getPrestigeLevel();
    rank = player scripts\players\_rank::getRank() + 1;

    result = rank + "/" + prestige + "/" + player.pers["demerits"];

    return result;
}

/**
 * @brief Gets the name of the players team
 *
 * @param player The player to get the team name for
 *
 * @returns string the name of the player's team, one of [Zombies|Survivors|Spectator]
 */
getTeamName(player)
{
    log("trace", "msg|in _adminInterface::getTeamName()||");

    if (!isDefined(player.team)) {return "Undefined";}
    if(player.team=="allies") {
        if (player.isZombie) {return "Zombies";}
        else {return "Survivors";}
    }
    else {return "Spectator";}
}


/**
 * @brief Gets the player's status
 *
 * @param player The player to check the status of
 *
 * @returns string the player's status, one of [Playing|Down|Dead|Spectating]
 */
getPlayerStatus(player)
{
    log("trace", "msg|in _adminInterface::getPlayerStatus()||");

    if ((isDefined(player.isDown)) && (player.isDown)) {return "Down";}
    else if( player.sessionstate == "playing" )        {return "Playing";}
    else if( player.sessionstate == "dead" )           {return "Dead";}
    else                                               {return "Spectating";}
}


/**
 * @brief Is the player locked by a pending admin command?
 * If the player isn't locked, it locks the player so an admin command can be issued
 *
 * @param player The player to be checked/locked
 * @param adminName The name of the admin requesting the lock
 * @param commandName The name of the command requesting the lock
 *
 * @returns boolean True if the player was already locked, false if we just locked them.
 * In any event, the player will be locked when this function returns.
 */
isLocked(player, adminName, commandName)
{
    log("trace", "msg|in _adminInterface::isLocked()||");

    // Ensure only one pending admin action on a player at a time
    if(player.isLocked) {
        displayAdminCommandFeedback("Player locked by " + adminName);
        return true;
    } else {
        player.isLocked = true;
        player.lockedBy = self.admin.playerName;
        player.lockTime = getTime();
        player.lockingCommand = commandName;
    }
    return false;
}


/**
 * @brief Warns a player
 *
 * @param playerEntityNumber integer The player's entity number
 * @param reason string The reason the player is being warned
 *
 * @returns nothing
 */
warnPlayer(playerEntityNumber, reason)
{
    log("trace", "msg|in _adminInterface::warnPlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canWarnPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't warn them.");
        return;
    }

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "warn"))) {

        // Do we show admins name?
        if ((self.admin.isStealthSession) && (reason == "admin_name")) {
            reason = "Admin decision";
        } else if (reason == "admin_name") {
            reason = self.admin.playerName + "'s decision";
        }

        player thread scripts\server\_adminCommands::warnPlayer(self, reason);
        displayAdminCommandFeedback("Player warned.");
    }
}



/**
 * @brief Permenantly bans a player from this server
 *
 * @param playerEntityNumber integer The player's entity number
 * @param reason string The reason the player is being banned
 *
 * @returns nothing
 */
banPlayer(playerEntityNumber, reason)
{
    log("trace", "msg|in _adminInterface::banPlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canBanPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't ban them.");
        return;
    }

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "ban"))) {

        // Do we show admins name?
        if ((self.admin.isStealthSession) && (reason == "admin_name")) {
            reason = "Admin decision";
        } else if (reason == "admin_name") {
            reason = self.admin.playerName + "'s decision";
        }

        player thread scripts\server\_adminCommands::banPlayer(self, reason);
        displayAdminCommandFeedback("Player being banned...");
    }
}


/**
 * @brief Remove one general warning for a player
 * @threaded on the admin player
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
removeOneWarning(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::removeOneWarning()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canRemovePlayerWarnings) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't remove warnings.");
        return;
    }

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "remove one warning"))) {
        player thread scripts\server\_adminCommands::removeOneWarning(self);
        displayAdminCommandFeedback("One warning removed.");
    }
}


/**
 * @brief Remove one language warning for a player
 * @threaded on the admin player
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
removeOneLanguageWarning(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::removeOneLanguageWarning()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canRemovePlayerWarnings) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't remove warnings.");
        return;
    }

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "remove one language warning"))) {
        player thread scripts\server\_adminCommands::removeOneLanguageWarning(self);
        displayAdminCommandFeedback("One language warning removed.");
    }
}



/**
 * @brief Remove all warnings for a player
 * @threaded on the admin player
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
removeAllWarnings(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::removeAllWarnings()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canRemovePlayerWarnings) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't remove warnings.");
        return;
    }

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "remove all warnings"))) {
        player thread scripts\server\_adminCommands::removeAllWarnings(self);
        displayAdminCommandFeedback("All warnings removed.");
    }
}


/**
 * @brief Demotes a player one rank, or 500 rank points, whichever is less
 * @threaded on the admin player
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
demotePlayer(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::demotePlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canRank) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't demote them.");
        return;
    }

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "demote player"))) {
        result = player scripts\server\_adminCommands::demotePlayer(self);
        displayAdminCommandFeedback(result);
    }
}


/**
 * @brief Promotes a player one rank, or 500 rank points, whichever is less
 * @threaded on the admin player
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
promotePlayer(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::promotePlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canRank) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't promote them.");
        return;
    }

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "promote player"))) {
        result = player scripts\server\_adminCommands::promotePlayer(self);
        displayAdminCommandFeedback(result);
    }
}


/**
 * @brief Restores a player's initial primary weapon
 * @threaded on the admin player
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
restorePlayersPrimaryWeapon(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::restorePlayersPrimaryWeapon()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canRestoreWeapons) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't restore their primary weapon.");
        return;
    }

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "restore primary weapon"))) {
        player thread scripts\server\_adminCommands::restorePlayersPrimaryWeapon(self);
        displayAdminCommandFeedback("Restored primary weapon.");
    }
}


/**
 * @brief Restores a player's initial sidearm
 * @threaded on the admin player
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
restorePlayersSidearm(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::restorePlayersSidearm()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canRestoreWeapons) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't restore their sidearm.");
        return;
    }

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "restore sidearm"))) {
        player thread scripts\server\_adminCommands::restorePlayersSidearm(self);
        displayAdminCommandFeedback("Restored sidearm.");
    }
}


/**
 * @brief Gives a player upgrade points
 * @threaded on the admin player
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
givePlayerUpgradePoints(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::givePlayerUpgradePoints()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canGiveUpgradePoints) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "give upgrade points"))) {
        player thread scripts\server\_adminCommands::givePlayerUpgradePoints(self);
        displayAdminCommandFeedback("Gave player 2,000 upgrade points.");
    }
}


/**
 * @brief Kicks a player from this server
 * @threaded on the admin player
 *
 * @param playerEntityNumber integer The player's entity number
 * @param reason string The reason the player is being kicked
 *
 * @returns nothing
 */
kickPlayer(playerEntityNumber, reason)
{
    log("trace", "msg|in _adminInterface::kickPlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canKickPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "kick"))) {

        // Do we show admins name?
        if ((self.admin.isStealthSession) && (reason == "admin_name")) {
            reason = "Admin decision";
        } else if (reason == "admin_name") {
            reason = self.admin.playerName + "'s decision";
        }

        player thread scripts\server\_adminCommands::kickPlayer(self, reason);
        displayAdminCommandFeedback("Player being kicked...");
    }
}



/**
 * @brief Temporarily bans a player from this server
 *
 * @param playerEntityNumber integer The player's entity number
 * @param reason string The reason the player is being temp-banned
 *
 * @returns nothing
 */
temporarilyBanPlayer(playerEntityNumber, reason)
{
    log("trace", "msg|in _adminInterface::temporarilyBanPlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canBanPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if ((isDefined(player)) && (!isLocked(player, self.admin.playerName, "temporary ban"))) {

        // Do we show admins name?
        if ((self.admin.isStealthSession) && (reason == "admin_name")) {
            reason = "Admin decision";
        } else if (reason == "admin_name") {
            reason = self.admin.playerName + "'s decision";
        }

        player thread scripts\server\_adminCommands::temporarilyBanPlayer(self, reason);
        displayAdminCommandFeedback("Player banned for " + getDvar("sv_kickBanTime") + " seconds.");
    }
}



/**
 * @brief Kills all zombies currently in the game
 *
 * @returns nothing
 */
killZombies()
{
    log("trace", "msg|in _adminInterface::killZombies()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canKillZombies) {onNoPermissions(); return;}

    thread scripts\server\_adminCommands::killZombies(self);

    displayAdminCommandFeedback("Zombies killed.");
}



/**
 * @brief Restarts the current game wave
 *
 * @returns nothing
 */
restartWave()
{
    log("trace", "msg|in _adminInterface::restartWave()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canRestart) {onNoPermissions(); return;}

    thread scripts\server\_adminCommands::restartWave(self);

    displayAdminCommandFeedback("Wave restarting.");
}



/**
 * @brief Restarts the current map
 *
 * @returns nothing
 */
restartMap()
{
    log("trace", "msg|in _adminInterface::restartMap()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canRestart) {onNoPermissions(); return;}

    adminActionConsoleMessage("Map restarting in 3 seconds...");
    displayAdminCommandFeedback("Map restarting.");
    wait 1.5;
    displayAdminCommandFeedback("");  // clear feedback before actually restarting map

    thread scripts\server\_adminCommands::restartMap(self);
}



/**
 * @brief Finishes the current game wave
 *
 * @returns nothing
 */
finishWave()
{
    log("trace", "msg|in _adminInterface::finishWave()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canFinish) {onNoPermissions(); return;}

    thread scripts\server\_adminCommands::finishWave(self);

    displayAdminCommandFeedback("Wave finished");
}



/**
 * @brief Finishes the current map
 *
 * @returns nothing
 */
finishMap()
{
    log("trace", "msg|in _adminInterface::finishMap()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canFinish) {onNoPermissions(); return;}

    thread scripts\server\_adminCommands::finishMap(self);
    displayAdminCommandFeedback("Map finished.");
}



/**
 * @brief Changes to the specified map
 *
 * @param string the full name of the map to change to
 *
 * @returns nothing
 */
changeMap()
{
    log("trace", "msg|in _adminInterface::changeMap()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canChangeMap) {onNoPermissions(); return;}

    displayAdminCommandFeedback("Map being changed.");
    wait 2;
    // clear the properties and unlock the command, just in case map chnaging fails
    onCancelChangeMap();
    displayAdminCommandFeedback("");
    thread scripts\server\_adminCommands::changeMap(self, level.changeMapNewMap);
}

/**
 * @brief Filters the list of maps according to the current filter
 *
 * @returns nothing
 */
applyMapFilter()
{
    log("trace", "msg|in _adminInterface::applyMapFilter()||");

    if(!isDefined(level.changeMapFilter)) {level.changeMapFilter = "";}

    // update filter text on-screen
    self setClientDvar("admin_changemap_filter", level.changeMapFilter);

    // apply the filter
    filteredMaps = filterMaps(level.changeMapFilter);

    // set the new map, as appropriate
    if (filteredMaps.size == 1) {
        level.changeMapNewMap = filteredMaps[0].name;
    } else {level.changeMapNewMap = "";}

    // enable the accept map button, as appropriate
    self setClientDvar("filterResultCount", filteredMaps.size);
    self buildFilteredMapsString(filteredMaps);
}

/**
 * @brief Initializes the map filter, or aborts if another admin is already trying to change the map
 *
 * @returns nothing
 */
onOpenChangeMap()
{
    log("trace", "msg|in _adminInterface::onOpenChangeMap()||");

    if(!isDefined(level.changeMapLockedBy)) {level.changeMapLockedBy = "";}

    if (level.changeMapLockedBy == "") {
        // lock change map, continue
        level.changeMapLockedBy = self.name;
        applyMapFilter();
    } else {
        // change map is locked, abort
        self closeMenu();
        displayAdminCommandFeedback("Change Map command is locked by " + level.changeMapLockedBy);
    }
}

/**
 * @brief Unlocks the change map command when the admin cancels the command
 *
 * @returns nothing
 */
onCancelChangeMap()
{
    log("trace", "msg|in _adminInterface::onCancelChangeMap()||");

    level.changeMapFilter = "";
    self setClientDvar("admin_changemap_filter", level.changeMapFilter);
    level.changeMapLockedBy = ""; // unlock the change map command
}

/**
 * @brief Updates the filtered maps when a new character is added to the filter
 *
 * @param character string The character that is to be added to the filter
 *
 * @returns nothing
 */
changeMapUpdateFilter(character)
{
    log("trace", "msg|in _adminInterface::changeMapUpdateFilter()||");

    level.changeMapFilter += character;
    applyMapFilter();
}

/**
 * @brief Removes the last character added to the filter, the updates the filter results
 *
 * @returns nothing
 */
changeMapFilterBackspace()
{
    log("trace", "msg|in _adminInterface::changeMapFilterBackspace()||");

    newFilter = "";
    for (i=0; i<level.changeMapFilter.size - 1; i++) {
        newFilter += level.changeMapFilter[i];
    }
    level.changeMapFilter = newFilter;
    applyMapFilter();
}

/**
 * @brief Builds and displays the filtered maps to the admin
 * We have limited room on the screen, so we allow for the matching maps to be
 * truncated.  Also, there is a character limit for a single hud element, so we
 * use three hud elements, and split the matching maps into these three elements.
 *
 * @param maps struct A struct containing the information on the matching maps
 *
 * @returns nothing
 */
buildFilteredMapsString(maps)
{
    log("trace", "msg|in _adminInterface::buildFilteredMapsString()||");

    tokens = [];
    for (i=0; i<maps.size; i++) {
        tokens[i] = maps[i].filterString;
    }

    results = [];
    resultsIndex = 0;
    lines = 0;
    results[resultsIndex] = tokens[0];
    lines++;
    if (tokens.size > 1) {
        for (i=1; i<tokens.size; i++) {
            if ((resultsIndex == 2) && (results[resultsIndex].size + 2 + tokens[i].size > 160)) {
                // truncate results, since we can't display them all
                results[resultsIndex] += "\n^1--RESULTS TRUNCATED--";
                break;
            } else if ((results[resultsIndex].size + 2 + tokens[i].size > 260) || (lines == 9)){
                // adding this token will overflow the string for the current dvar
                resultsIndex++;
                results[resultsIndex] = tokens[i];
                lines = 1;
            } else {
                results[resultsIndex] += "\n" + tokens[i];
                lines++;
            }
        }
    }

    // clear the old filter results
    self setClientDvar("admin_matching_maps1", "");
    self setClientDvar("admin_matching_maps2", "");
    self setClientDvar("admin_matching_maps3", "");

    // set the new results as required
    if (results.size >= 1) {self setClientDvar("admin_matching_maps1", results[0]);}
    if (results.size >= 2) {self setClientDvar("admin_matching_maps2", results[1]);}
    if (results.size >= 3) {self setClientDvar("admin_matching_maps3", results[2]);}
}

/**
 * @brief Filters the available maps that don't match \c filter
 *
 * @param filter string The substring to search for
 *
 * @returns the maps that were matched
 */
filterMaps(filter)
{
    log("trace", "msg|in _adminInterface::filterMaps()||");

    log("server", "msg|Admin filtering maps for " + filter + "||");
    filteredMaps = [];
    index = 0;
    for (i=0; i<level.mapList.size; i++) {
        search = level.mapList[i].lcFilterString;
        if (issubstr(search, filter)) {
            filteredMaps[index] = level.mapList[i];
            index++;
        }
    }
    return filteredMaps;
}


/**
 * @brief Forces a player to drop their current weapon
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
dropPlayerWeapon(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::dropPlayerWeapon()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canDropPlayerWeapon) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't drop their weapon.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't drop weapon of a player that isn't alive.");
        return;
    }

    if ((isDefined(player)) &&
        (player.isAlive) &&
        (!isLocked(player, self.admin.playerName, "drop weapon")))
    {
        if (player thread scripts\server\_adminCommands::dropPlayerWeapon(self)) {
            displayAdminCommandFeedback("Weapon dropped.");
        } else {
            displayAdminCommandFeedback("Weapon not dropped because it had no ammunition.");
        }
    }
}


/**
 * @brief Toggles showing/hiding admin status this admin session
 *
 * @returns nothing
 */
toggleAdminSessionVisibility()
{
    log("trace", "msg|in _adminInterface::toggleAdminSessionVisibility()||");

    // Bail if admin doesn't have this power
    if (!self.admin.isAdmin) {onNoPermissions(); return;}

    if (self.admin.isStealthSession) {showAdminSession();}
    else {hideAdminSession();}
}


/**
 * @brief Shows admin status this admin session
 *
 * @returns nothing
 */
showAdminSession()
{
    log("trace", "msg|in _adminInterface::showAdminSession()||");

    // Bail if admin doesn't have this power
    if (!self.admin.isAdmin) {onNoPermissions(); return;}

    self.admin.isStealthSession = 0;
    self.admin.informPlayerOfAdminActions = 1;
    self.admin.showActionConsoleMessages = 1;
    self.admin.visibilityState = "^2Visible"; // green text

    // Set admin head icon, but do not override infected and low hit points head icons
    if ((self.headicon != "icon_infected") &&
        (self.headicon != "hud_icon_lowhp") &&
        (self.headicon != "headicon_medhp"))
    {
        self.headicon = "headicon_admin";
    }

    if ((self.sessionstate == "playing") || (self.sessionstate == "dead")) {
        self.statusicon = "icon_admin";
    } else if (self.isDown){self.statusicon = "icon_down";} // down
    else {self.statusicon = "icon_spec";}                   // spectating

    self setClientDvar("admin_visibility", self.admin.visibilityState);

    displayAdminCommandFeedback("Session is now visible");
}



/**
 * @brief Hides admin status this admin session
 *
 * @returns nothing
 */
hideAdminSession()
{
    log("trace", "msg|in _adminInterface::hideAdminSession()||");

    // Bail if admin doesn't have this power
    if (!self.admin.isAdmin) {onNoPermissions(); return;}

    self.admin.isStealthSession = 1;
    self.admin.informPlayerOfAdminActions = 0;
    self.admin.showActionConsoleMessages = 0;
    self.admin.visibilityState = "^1Hidden"; // red text
    self setClientDvar("admin_visibility", self.admin.visibilityState);

    // remove icons as required
    self scripts\players\_players::defaultHeadicon();

    if ((self.sessionstate == "playing") || (self.sessionstate == "dead")) {
        self.statusicon = "";
    } else if (self.isDown){self.statusicon = "icon_down";} // down
    else {self.statusicon = "icon_spec";}                   // spectating

    displayAdminCommandFeedback("Session is now hidden");
}


/**
 * @brief Drops an ammo can near the player
 *
 * @param playerEntityNumber The number of the player
 *
 * @returns nothing
 */
ammoBox(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::ammoBox()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canAmmoBox) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't drop ammo box near them.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't drop ammo box near a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "ammo box")))
    {
        player thread scripts\server\_adminCommands::ammoBox(self);
        displayAdminCommandFeedback("Ammo box dropped.");
    }
}


/**
 * @brief Starts a healing aura at the player's position
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
healingAura(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::healingAura()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canHealingAura) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't place a healing aura.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't place healing aura by a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "healing aura")))
    {
        player thread scripts\server\_adminCommands::healingAura(self);
        displayAdminCommandFeedback("Healing aura placed.");
    }
}


/**
 * @brief Gives admin private feedback that they executed a command
 *
 * @param message The message to display.
 *
 * @returns nothing
 */
displayAdminCommandFeedback(message)
{
    log("trace", "msg|in _adminInterface::displayAdminCommandFeedback()||");

    msg = "^5" + message; // cyan text
    self thread ACPNotify(msg, 3);
}



/**
 * @brief Takes all of a player's weapons
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
disarmPlayer(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::disarmPlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canDisarmPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't disarm them.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't disarm a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "disarm")))
    {
        player thread scripts\server\_adminCommands::disarmPlayer(self);
        displayAdminCommandFeedback("Player disarmed.");
    }
}



/**
 * @brief Takes a player's current weapon
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
takePlayersCurrentWeapon(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::takePlayersCurrentWeapon()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canTakePlayerWeapon) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't take their current weapon.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't take a weapon from a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "take current weapon")))
    {
        player thread scripts\server\_adminCommands::takePlayersCurrentWeapon(self);
        displayAdminCommandFeedback("Weapon taken.");
    }
}


/**
 * @brief Restores a player's health
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
healPlayer(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::healPlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canHealPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't heal them.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't heal a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "heal")))
    {
        player thread scripts\server\_adminCommands::healPlayer(self);
        displayAdminCommandFeedback("Player healed.");
    }
}



/**
 * @brief Cures a player's infection
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
curePlayer(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::curePlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canCurePlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't cure.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't cure a player that isn't alive.");
        return;
    } else if (!player.infected) {
        displayAdminCommandFeedback("Can't cure a player that isn't infected.");
        return;
    }

    // Player locking should be the *last* boolean test, so we don't lock a player
    // and then wind bailing on the function!
    if ((isDefined(player)) &&
        (player.isAlive) &&
        (player.infected) &&
        (!isLocked(player, self.admin.playerName, "cure")))
    {
        player thread scripts\server\_adminCommands::curePlayer(self);
        displayAdminCommandFeedback("Player cured.");
    }
}


/**
 * @brief Spawns a player if they are a spectator
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
spawnPlayer(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::spawnPlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canSpawnPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't spawn them.");
        return;
    } else if (player.isAlive) {
        displayAdminCommandFeedback("Can't spawn a player that is already alive.");
        return;
    }

    if((isDefined(player)) &&
       (!player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "spawn")))
    {
        if (player thread scripts\server\_adminCommands::spawnPlayer(self)) {
            displayAdminCommandFeedback("Player spawned.");
        } else {
            displayAdminCommandFeedback("Player not spawned.");
        }
    }
}

/**
 * @brief Bounces a player
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
bouncePlayer(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::bouncePlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canBouncePlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't bounce them.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't bounce a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "bounce")))
    {
        player thread scripts\server\_adminCommands::bouncePlayer(self);
        displayAdminCommandFeedback("Player bounced.");
    }
}

/**
 * @brief Teleports a player to the spawn point
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
teleportPlayerToSpawn(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::teleportPlayerToSpawn()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canTeleportPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't teleport them.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't teleport a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "teleport to spawn")))
    {
        player thread scripts\server\_adminCommands::teleportPlayerToSpawn(self);
        displayAdminCommandFeedback("Player teleported.");
    }
}

/**
 * @brief Teleports a player to the admin's location
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
teleportPlayerToAdmin(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::teleportPlayerToAdmin()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canTeleportPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't teleport them.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't teleport a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "teleport to admin")))
    {
        player thread scripts\server\_adminCommands::teleportPlayerToAdmin(self.origin, self);
        displayAdminCommandFeedback("Player teleported.");
    }
}

/**
 * @brief Teleports a player forward about 3 feet
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
teleportPlayerForward(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::teleportPlayerForward()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canTeleportPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't teleport them.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't teleport a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "teleport forward")))
    {
        player thread scripts\server\_adminCommands::teleportPlayerForward(self);
        displayAdminCommandFeedback("Player teleported.");
    }
}

/**
 * @brief Downs a player, but they can still be revived
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
downPlayer(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::downPlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canDownPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't down them.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't down a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "down")))
    {
        player thread scripts\server\_adminCommands::downPlayer(self);
        displayAdminCommandFeedback("Player downed.");
    }
}

/**
 * @brief Revives a player
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
revivePlayer(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::revivePlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canRevivePlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't revive.");
        return;
    } else if (player.isZombie) {
        displayAdminCommandFeedback("Can't revive a zombie.");
        return;
    } else if (player.isDown && player.infected) {
        displayAdminCommandFeedback("Player must be cured before being revived.");
        return;
    } else if (!player.isDown) {
        displayAdminCommandFeedback("Can't revive a player that isn't down.");
        return;
    }

    if ((isDefined(player)) &&
        (player.isDown) &&
        (!player.infected) &&
        (!player.isZombie) &&
        (!isLocked(player, self.admin.playerName, "revive")))
    {
            player thread scripts\server\_adminCommands::revivePlayer(self);
            displayAdminCommandFeedback("Player revived.");
    }
}

/**
 * @brief Kills a player, and they cannot be revived
 *
 * @param playerEntityNumber integer The player's entity number
 *
 * @returns nothing
 */
explodePlayer(playerEntityNumber)
{
    log("trace", "msg|in _adminInterface::explodePlayer()||");

    // Bail if admin doesn't have this power
    if (!self.admin.canBoomPlayer) {onNoPermissions(); return;}

    player = getPlayerByEntityNumber(playerEntityNumber);

    if (!isDefined(player)) {
        displayAdminCommandFeedback("Player is undefined, can't explode.");
        return;
    } else if (!player.isAlive) {
        displayAdminCommandFeedback("Can't explode a player that isn't alive.");
        return;
    }

    if((isDefined(player)) &&
       (player.isAlive) &&
       (!isLocked(player, self.admin.playerName, "explode")))
    {
        player thread scripts\server\_adminCommands::explodePlayer(self);
        displayAdminCommandFeedback("Player exploded.");
    }
}
