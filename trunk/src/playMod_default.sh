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

UNIXEPOCH=$(date +%s)

WINEPREFIX=~/.wine_cod4
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

# If run from command line, change back to original folder
# (Optional, since script ends here)
cd Mods/rotudev