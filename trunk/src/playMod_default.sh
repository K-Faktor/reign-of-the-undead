#!/usr/bin/bash
#******************************************************************************
#     Reign of the Undead, v2.x
#
#     Copyright (c) 2010-2026 Reign of the Undead Team.
#     See AUTHORS.txt for a listing.
#
#     Permission is hereby granted, free of charge, to any person obtaining a copy
#     of this software and associated documentation files (the "Software"), to
#     deal in the Software without restriction, including without limitation the
#     rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
#     sell copies of the Software, and to permit persons to whom the Software is
#     furnished to do so, subject to the following conditions:
#
#     The above copyright notice and this permission notice shall be included in
#     all copies or substantial portions of the Software.
#
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#     SOFTWARE.
#
#     The contents of the end-game credits must be kept, and no modification of its
#     appearance may have the effect of failing to give credit to the Reign of the
#     Undead creators.
#
#     Some assets in this mod are owned by Activision/Infinity Ward, so any use of
#     Reign of the Undead must also comply with Activision/Infinity Ward's modtools
#     EULA.
#******************************************************************************

# Depends on: being run from the mods/rotudev folder

# Suppress output by redirecting to /dev/null if needed, but here we'll just run commands
# Ensure the correct current working directory gets set
cd "$(dirname "$0")"/../../

# Launch the Listen server
#   In a listen server, the COD4 client and server run in the same process, which makes
#   it the easiest to set up.  The downside is that there can be only one player, and
#   you can't change maps.  When the game ends, the process ends.  I always use a listen
#   server for testing code changes and for editing maps with the UMI Map Editor.
#
#   fs_game sets the name of the mod run
#   sv_punkbuster must be 0 for zombies to appear!
#   developer and developer_script should be 0 for regular games, but must be 1 to use the UMI Editor
#   exec server.cfg loads all of the various *.cfg files
#   devmap sets the name of the map to load when the server starts
#   +set real_time_offset value is an integer, -5 for CDT (US Chicago).  If not set, you get UTC.
#   +set real_time_tz_str "CDT (UTC-5) US Chicago" used as a string
#   +set rotu_auto_map_test 1  sets rotu into map test mode; kills all delays to check map loading waypoints, and if zombies spawn

# To enable clear screenshotMode in a UMI Listen server, ensure the following values
# are set in the command line for `iw3mp.exe`:
#
#   +set dedicated 0 \
#   +set developer 1 \
#   +set developer_script 1 \
#   +set enable_umi_editor 1 \
#   <snip>
#   +set r_fullscreen \
#   +set sv_pure 0 \
#   +set thereisacow 1337



#!/bin/bash

# ================================================
# playMod.sh - CoD4 mod launcher with multiple modes
# ================================================

# -------------------------------
# Usage / Help
# -------------------------------
usage() {
    echo "Usage: $0 [COMMAND] [MAPNAME]" >&2
    echo "" >&2
    echo "Commands:" >&2
    echo "  (no arguments)         Normal game startup (uses hard-coded settings)" >&2
    echo "  <mapname>              Start normal game on specific map" >&2
    echo "  maptest <mapname>      Start map in test mode (Used by autoMapTest.py)" >&2
    echo "  screenshot <mapname>   Start map in screenshot mode" >&2
    echo "  umi <mapname>          Start map in UMI Editor mode" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0                           # Normal start" >&2
    echo "  $0 mp_surv_texas             # Normal game on this map" >&2
    echo "  $0 maptest mp_surv_texas     # Used by autoMapTest.py" >&2
    echo "  $0 screenshot mp_surv_texas  # Screenshot mode on this map" >&2
    exit 1
}

# ================================================
# Parameter parsing and validation
# ================================================

MODE=""
MAPNAME=""

case $# in
    0)
        # No arguments → normal startup
        MODE="normal"
        ;;

    1)
        # One argument → treat as mapname for normal game
        MODE="normal"
        MAPNAME="$1"
        ;;

    2)
        # Two arguments → command + mapname
        case "$1" in
            maptest)
                MODE="maptest"
                MAPNAME="$2"
                ;;
            screenshot)
                MODE="screenshot"
                MAPNAME="$2"
                ;;
            umi)
                MODE="umi"
                MAPNAME="$2"
                ;;
            *)
                echo "Error: Unknown command '$1'" >&2
                usage
                ;;
        esac
        ;;

    *)
        # Too many arguments
        echo "Error: Too many arguments ($#)" >&2
        usage
        ;;
esac

# ================================================
# Now run your server / game command
# ================================================

UNIXEPOCH=$(date +%s)
WINEPREFIX=~/.wine_cod4

if [ "$MODE" = "maptest" ]; then
    # ======================
    # MAPTEST MODE
    # ======================
    echo "Launching CoD4 in **MAPTEST** mode on map: $MAPNAME"
    wine "./iw3mp.exe" \
      +set fs_game "mods/rotudev" \
      +set sv_punkbuster "0" \
      +set dedicated 0 \
      +set developer 0 \
      +set developer_script 0 \
      +set g_gametype "surv" \
      +set rotu_auto_map_test 1 \
      +set real_time_base "$UNIXEPOCH" \
      +set real_time_offset -5 \
      +set real_time_tz_str "CDT (UTC-5) Dallas, Texas" \
      +exec server.cfg \
      +devmap "$MAPNAME"

elif [ "$MODE" = "screenshot" ]; then
    # SCREENSHOT MODE
    # ======================
    echo "Launching CoD4 in **SCREENSHOT** mode on map: $MAPNAME"
    echo "Incant in the in-game console: ~, then /exec screenshot, then ~"
    wine "./iw3mp.exe" \
      +set fs_game "mods/rotudev" \
      +set sv_punkbuster "0" \
      +set dedicated 0 \
      +set developer 1 \
      +set developer_script 0 \
      +set g_gametype "surv" \
      +set screenshot_mode 0 \
      +set run_mode "screenshotMode" \
      +set enable_umi_editor 1 \
      +set real_time_base "$UNIXEPOCH" \
      +set real_time_offset -5 \
      +set real_time_tz_str "CDT (UTC-5) Dallas, Texas" \
      +set r_fullscreen \
      +set sv_pure 0 \
      +set thereisacow 1337 \
      +exec server.cfg \
      +devmap "$MAPNAME"

elif [ "$MODE" = "umi" ]; then
    # ======================
    # UMI Map Editor MODE
    # ======================
    echo "Launching CoD4 in **UMI** mode on map: $MAPNAME"
    wine "./iw3mp.exe" \
      +set fs_game "mods/rotudev" \
      +set sv_punkbuster "0" \
      +set dedicated 0 \
      +set developer 1 \
      +set developer_script 1 \
      +set g_gametype "surv" \
      +set screenshot_mode 0 \
      +set enable_umi_editor 1 \
      +set real_time_base "$UNIXEPOCH" \
      +set real_time_offset -5 \
      +set real_time_tz_str "CDT (UTC-5) Dallas, Texas" \
      +exec server.cfg \
      +devmap "$MAPNAME"


else
    # ======================
    # NORMAL MODE
    # ======================
    if [ -n "$MAPNAME" ]; then
        echo "Launching CoD4 **normally** on map: $MAPNAME"
        # Normal launch with specific map
        wine "./iw3mp.exe" \
          +set fs_game "mods/rotudev" \
          +set sv_punkbuster "0" \
          +set dedicated 0 \
          +set developer 0 \
          +set developer_script 0 \
          +set g_gametype "surv" \
          +set real_time_base "$UNIXEPOCH" \
          +set real_time_offset -5 \
          +set real_time_tz_str "CDT (UTC-5) Dallas, Texas" \
          +exec server.cfg \
          +devmap "$MAPNAME"
    else
        echo "Launching CoD4 **normally** (hard-coded settings)"
        # Normal startup (no maptest)
        wine "./iw3mp.exe" \
          +set fs_game "mods/rotudev" \
          +set sv_punkbuster "0" \
          +set dedicated 0 \
          +set developer 0 \
          +set developer_script 0 \
          +set g_gametype "surv" \
          +set real_time_base "$UNIXEPOCH" \
          +set real_time_offset -5 \
          +set real_time_tz_str "CDT (UTC-5) Dallas, Texas" \
          +exec server.cfg \
          +devmap mp_surv_testmap
          # +devmap mp_surv_tunnel
          # +devmap mp_xtr_abydos
          # +devmap mp_xtr_arena
          # +devmap mp_surv_bjwifi_beach
          # +devmap mp_surv_bjelovar
          # +devmap mp_surv_bjwifi_fort
          # +devmap mp_surv_new_moon_lg
          # +devmap mp_surv_pacman
          # +devmap mp_surv_springfield
          # +devmap mp_fnrp_simpsons
          # +devmap mp_xtr_volcano
    fi
fi

# If run from command line, change back to original folder
# (Optional, since script ends here)
cd Mods/rotudev
