# Unified Mapping Interface (UMI) Guide

**Since:** RotU 2.2.1  
**Status:** Draft

## Introduction

This document covers how to use the **Unified Mapping Interface (UMI)** and the **UMI Map Editor**.

## Documentation

For the most up-to-date API documentation, you should refer to the debug versions of these two files:

- `_umi.gsc`
- `_umiEditor.gsc`

You can find them in the debug version of `rotu_svr_scripts.iwd` or directly in the repository.

## Important Bugs

> **Do NOT** delete a waypoint link — this will crash the game.  
> **Workaround:** Delete the waypoint itself, then recreate it and link it as desired.

This bug will be fixed in a future update.

## General Information

To load a non-RotU map or override a RotU map, you generally need three files (example for `mp_damnalley`):

- `mp_damnalley.gsc` — main map script
- `mp_damnalley_waypoints.gsc` — waypoints for the map (not required if internal waypoints are OK)
- `mp_damnalley_tradespawns.gsc` — tradespawns (shops and weapon upgrades)

These files should be placed in:

- `custom_maps/maps/mp/` (when using SVN), or
- `maps/mp/` inside `rotu_svr_mapdata.iwd` (when using the binary release)

You will need a text editor to create or edit the main `.gsc` file. Waypoints and tradespawns can be created and edited in-game using the UMI Editor, then saved.

After making changes, rebuild the mod with `perl makeMod.pl -s` (SVN) or manually re-zip `rotu_svr_mapdata.iwd` (binary release).

## Running a Map in UMI Developer Mode

1. In `server.cfg`, set `dedicated 0` (Listen server).
2. Edit `playMod.bat` to load the desired map.
3. Set `developer 1` and `developer_script 1` in `playMod.bat`.
4. Update `fs_game` to point to your mod folder (e.g. `mods/rotudev`).

To edit waypoints and tradespawns, set `umiEditorMode = true` in the map’s main `.gsc` file.  
Additionally, for screenshot mode, set `screenshotMode = true` in the map’s main `.gsc` file.  This prevents all the UMI stuff from spawning, for clean screenshots.

To test the map with zombies, set `umiEditorMode = false`.

- `umiEditorMode = true`: No zombies, editor tools active.
- `umiEditorMode = false`: Normal gameplay with zombies.

The UMI Editor follows the **devPlayer** defined in `admin.cfg` (`set admin_forced_guid ""`).

## Showing Spawnpoints

In the map’s main `.gsc` file, you will usually see:

    umiEditorMode = true;   // toggle true/false to switch between editor and game mode
    screenshotMode = true;  // hide all the UMI stuff to facilitate screenshots

```bash
    if (umiEditorMode) {
        if (!screenshotMode) {
            devDrawAllPossibleSpawnpoints();
        }
        maps\mp\_umiEditor::initMapEditor();
    } else {
        buildWeaponShopsByTargetname("ammostock");
        buildShopsByTargetname("weaponupgrade");
    }
```
The call to `devDrawAllPossibleSpawnpoints();` draws a red vertical laser at each possible spawnpoint.  The purpose of this is to prevent you from placing a tradespawn (shop or weapons upgrade) on top of or too close to a spawnpoint.

# Commands
The UMI Editor commands are available from the menu by pressing b then 5.  Admin commands are available from b then 4, in case you need to teleport through an obstacle to get to a waypoint location.  Additionally, there are keyboard shortcuts for some commands, as noted in the HUD.

# Map Screenshots
**Since:** RotU 2.2.2-git

Set the `screenshotMode = true;` as noted above.

In playMod.bat, ensure the following values are set in the command line for `iw3mp.exe`:

```bash
  +set dedicated 0 \
  +set developer 1 \
  +set developer_script 1 \

  +set r_fullscreen \
  +set sv_pure 0 \
  +set thereisacow 1337
```

  * Launch the game
  * Choose a class
  * Change teams to spectator
  * Fly around to get the view you want.
  * Use in-game console (use backtick\tilde key \` to toggle in-game console on/off)
  * Turn off minimap & all hud elements, good for screenshots:
```bash
/exec minimap
```

  * Alt+Tab, set up screenshot program for full screen capture after a delay
  * Alt+Tab back to game;  Save screenshot.

Spectacle on KDE gave me a 16 MiB, 4K *.png.  Probably a bit more than I need.

# Waypoints
When running a map in umiEditorMode, nearby linked waypoints are marked by blue flags.  Unlinked waypoints are marked with red flags. While creating a waypoint link, you will be carrying a black flag.

Waypoint links are drawn in a variety of colors, and they are drawn 10 units higher than they actually are for better visibility.  The current waypoint link is always drawn in bright green.  On a very large map, with too many waypoint links, we aren't able to draw them all.  In that case, we only draw the links within 2500 units of the devPlayer.

  ## Dropping a Waypoint
  Whenever you drop a waypoint, like when you emplace or move a waypoint, the waypoint flag will drop to the ground or a solid surface, and that point will be the actual waypoint.  There is no need to have a waypoint in the air, but if you want one in the air, you will need to manually edit the waypoint in the generated file.

  ## Moving Waypoints
  You make pick up and move linked and unlinked waypoints. Use 'f' to pick up the nearest waypoint, then 'fire' to drop it in its new location.

  ## Linking a Waypoint
  To create a link between two waypoints, use the 'link waypoint' command.  The command will begin a link from the closest waypoint, and will give you a black flag. Plant this flag near the waypoint that will be the other end of the waypoint link.  If your waypoints are too close to each other, you may need to rotate or otherwise adjust your position so your body is closer to the end of the waypoint link than it is to the beginning of the link.

  ## Deleting a Waypoint Link
  Do *NOT* delete a waypoint link, as this will cause the game to crash.  Instead, delete the waypoint, then recreate the waypoint, linking it as you like.

  ## Deleting a Waypoint
  To delete a linked or unlinked waypoint, use the 'delete waypoint' command.  The command will delete the closest waypoint, and if it is a linked waypoint, will also delete all the waypoint links that waypoint has.

  ## Adding Waypoints
  To add new waypoints to a map, use 'waypoint mode' via the 'toggle give waypoints' command. When you turn on waypoint mode, you will be given an unlinked waypoint flag (a red flag).  When you have positioned the flag where you want it, 'fire' to emplace the flag.  You will then be given another unlinked waypoint flag so you can continue adding waypoints.

  There is a limit of 20 unlinked waypoints.  When you have emplaced the last available unlinked waypoint, 'waypoint mode' will toggle off, and you will be told you need to link some waypoints to recycle the flags.

  If you want to stop emplacing unlinked waypoints before you have emplaced them all, just 'toggle give waypoints' to turn off 'waypoint mode'.

  ## Saving Waypoints
  To save the waypoints, use the 'save waypoints' command.  The command will write a proper waypoints file to the server_mp.log file.  You should save your work often in case the game crashes.  I like to save them whenever I'm done emplacing or linking a set of waypoints.

  ## Autolinking Waypoints
  After you have emplaced a bunch of unlinked waypoints, you may use the 'autolink waypoints' command to intelligently create waypoint links for you.  The autolinking algorithm is quite fast, and it will create correct links about 75% of the time.  It assumes that the unlinked waypoints are in a small contiguous area, so if you plan on using this command, work on one area of the map at a time.  After the waypoints are auto-linked, the command automatically saves the waypoints to server_mp.log.

  For any links the command creates that you don't want, you may delete the link.  However, note the bug and the workaround described under 'Deleting a Waypoint Link'.

  ## Waypoint Types
  You can change the type of the current (closest) waypoint with the 'cycle waypoint type' command.  RotU doesn't use this currently, but the new AI under development will.

  ## Best Practices
   * Place a waypoint at the exact bottom and top of each flight of stairs or ramp.
   * If two flights of stairs connect at 90 degrees at a landing, place one additional waypoint on that landing.
   * If two flights of stairs connect at a landing but keep going in the same direction, place one additional waypoint on the landing.
   * If two flights of stairs connect at 180 degrees at a landing, place two additional waypoints on the landing.
   * Use enough waypoints.  A good rule of thumb is to have them no further apart than twice the height of a player.
   * Avoid placing a waypoint so close to an obstruction that a zombie would be inside the obstruction if it were at the waypoint or following the waypoint link.
   * If several waypoints are linked in a line, offset each waypoint slightly so the zombie won't travel in a straight line while following the links.
   * Place a line of waypoint links along natural lines of drift, such as along rivers, ditches, ridges, roads, paths, and valleys.

# Tradespawns
The shops and weapon upgrades are collectively called tradespawns. The number of equipment shops in a map must equal the number of weapon upgrades in the map.

Use the 'give equipment shop' command to be given an equipment shop.  You can then emplace it with 'fire'.  You may also pick up an equipment shop and move it.  When you emplace the shop, it will position itself on the plane representing solid ground.  If the shop is wildly rotated, it means you tried to put it someplace it can't be, such as partially in a wall or partially in mid-air.  In that case, just pick it up and try again.

Use the 'give weapon upgrade' command to be given a weapons crate.  Weapon upgrades are handled the way as the equipment shops.

When you have the tradespawns positioned where you like them, use the 'save tradespawns' command to save the data to the server_mp.log.

# Creating and Updating Waypoint and Tradespawn Files
Waypoint and tradespawn files are handled the same way; for this example we will use a waypoints file.

After using the 'save waypoints' command the waypoints in memory will be dumped into the server_mp.log file like this (most waypoints omitted for brevity):
```gsc
 65:23 // =============================================================================
 65:23 // File Name = 'mp_firingrange_v2_waypoints.gsc'
 65:23 // Map Name = 'mp_firingrange_v2'
 65:23 // =============================================================================
 65:23 //
 65:23 // This file was generated by the RotU admin development command 'Save Waypoints'
 65:23 //
 65:23 // =============================================================================
 65:23 //
 65:23 // This file contains the waypoints for the map 'mp_firingrange_v2'
 65:23 //
 65:23 // N.B. You will need to delete the timecodes at the beginning of these lines!
 65:23 //
 65:23 load_waypoints()
 65:23 {
 65:23     level.waypoints = [];
 65:23     
 65:23     level.waypoints[0] = spawnstruct();
 65:23     level.waypoints[0].origin = (4976.31,295.838,4.625);
 65:23     level.waypoints[0].childCount = 5;
 65:23     level.waypoints[0].children[0] = 7;
 65:23     level.waypoints[0].children[1] = 1;
 65:23     level.waypoints[0].children[2] = 6;
 65:23     level.waypoints[0].children[3] = 5;
 65:23     level.waypoints[0].children[4] = 4;

...

 65:23     level.waypoints[327] = spawnstruct();
 65:23     level.waypoints[327].origin = (6213.91,-1568.55,-57.5624);
 65:23     level.waypoints[327].childCount = 4;
 65:23     level.waypoints[327].children[0] = 250;
 65:23     level.waypoints[327].children[1] = 249;
 65:23     level.waypoints[327].children[2] = 247;
 65:23     level.waypoints[327].children[3] = 246;
 65:23     
 65:23     level.waypointCount = level.waypoints.size;
 65:23 }

```
You will need to copy all those lines and paste them over the existing waypoints file, or into a new waypoints file if one doesn't exist yet. Once that is done, you will need to delete the timecodes at the beginning of each line.

A global replacement of, in this example, '65:23 ' with an empty string "" will delete all of the timecodes except two of them.  Those two must be deleted manually.  The two commented lines in the header reminding you to delete the timecodes may also be deleted.  You should also ensure there is a final newline in the file, i.e. a blank line after the final closing brace `}'.

The final file should look like:
```gsc
// =============================================================================
// File Name = 'mp_firingrange_v2_waypoints.gsc'
// Map Name = 'mp_firingrange_v2'
// =============================================================================
//
// This file was generated by the RotU admin development command 'Save Waypoints'
//
// =============================================================================
//
// This file contains the waypoints for the map 'mp_firingrange_v2'
load_waypoints()
{
    level.waypoints = [];

    level.waypoints[0] = spawnstruct();
    level.waypoints[0].origin = (4976.31,295.838,4.625);
    level.waypoints[0].childCount = 5;
    level.waypoints[0].children[0] = 7;
    level.waypoints[0].children[1] = 1;
    level.waypoints[0].children[2] = 6;
    level.waypoints[0].children[3] = 5;
    level.waypoints[0].children[4] = 4;

...

    level.waypoints[327] = spawnstruct();
    level.waypoints[327].origin = (6213.91,-1568.55,-57.5624);
    level.waypoints[327].childCount = 4;
    level.waypoints[327].children[0] = 250;
    level.waypoints[327].children[1] = 249;
    level.waypoints[327].children[2] = 247;
    level.waypoints[327].children[3] = 246;

    level.waypointCount = level.waypoints.size;
}

```

Note that this wiki won't show the final blank line.

# Troubleshooting Errors

If there are errors, open `console_mp.log` and search for " error" (note the leading space).  A single error will often cause many other errors, so the only error we care about is the first one this search finds.

There are two types of errors: compile errors and runtime errors. A compile error usually means you have a typo in your code, or you called a function that doesn't exist, or called a function with incorrect parameters, or you made some other syntax error.  A runtime error happens while the code is running, and the most often cause is that a variable is undefined.

  ## Error: Loading non-existent tradespawns
  ```
******* script runtime error *******
undefined is not an array, string, or vector: (file 'maps/mp/_umi.gsc', line 610)
    if (!isDefined(level.tradespawns[int(weapons[0])])) {
                         *
Error: called from:
(file 'maps/mp/mp_damnalley.gsc', line 72)
        buildWeaponShopsByTradespawns("0 2 4 6 8 10 12");
        *
Error: started from:
(file 'maps/mp/_umi.gsc', line 929)
        wait .5;
        *
Error: ************************************
```
  This runtime error happens because in the map's main `*.gsc` file, you are telling it to load weapon shops by tradespawns, but there aren't any.  Either the tradespawns file doesn't exist, or you neglected to load it.  You may also be running the map with `umiEditorMode = false` when you mean to to have it be `true`.
