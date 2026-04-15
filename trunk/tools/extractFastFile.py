#!/usr/bin/env python3
#******************************************************************************
#     Reign of the Undead, v2.2.x 
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

"""
This file tries to extract data from a map's main *.ff file.  The driver here is getting
their scripts, to elucidate how we might fix bugs in the map's scripts.

If I have to go in blindly, I can still make the map work, but I'll likely lose any special
features they implemnted in the main *.gsc file.

NOTE: If the scrpt appears to hang, the first of the commands may be waiting for permission
to overwrite previous unzipping, if you've previously unzipped that FF.

Also, you may need to Ctrl+C after both commands are run to get a prompt back.
"""

import os
import subprocess
from dotenv import load_dotenv
import shutil
from pathlib import Path
import sys
from datetime import datetime


here = Path(__file__).resolve()
project_default = here.parents[2] if len(here.parents) >= 3 else here.parent
env_path = project_default / ".env"
load_dotenv(env_path)

# You may need to adjust your wine prefix on Linux
wine_env = "WINEARCH=win32 WINEPREFIX=~/.wine_cod4"

PLATFORM = os.getenv('PLATFORM')
PROJECT_PATH = os.getenv('PROJECT_PATH')

if not PROJECT_PATH or not PLATFORM:
    print("PROJECT_PATH or PLATFORM not set in .env")
    exit(1)

map_name = sys.argv[1:][0] # "mp_evil_house"
fast_file = f"{map_name}.ff"
print(f"Attempting to extract: {fast_file}")

# Paths
offzip_exe = os.path.join(PROJECT_PATH, 'trunk', 'tools', 'offzip.exe')
iw_ff_extract_exe = os.path.join(PROJECT_PATH, 'trunk', 'tools', 'iw_ff_extract.exe')

extract_main_dir = os.path.join(PROJECT_PATH, 'map_extraction')
master_maps_dir = os.path.join(PROJECT_PATH, 'master_maps') # @todo: switch to map_testing later?
extraction_tmp_dir = os.path.join(extract_main_dir, 'tmp')

maps_unzip_dir = os.path.join(extract_main_dir, f'{map_name}_unzip')
map_extract_dir = os.path.join(extract_main_dir, f'{map_name}_extracted')

ff_src = os.path.join(f'{master_maps_dir}', f'{map_name}', f'{fast_file}')
ff_dst = os.path.join(f'{extraction_tmp_dir}', f'{fast_file}')

# ensure extract_main_dir, extraction_tmp_dir, maps_unzip_dir exist
Path(extract_main_dir).mkdir(parents=True, exist_ok=True)
Path(extraction_tmp_dir).mkdir(parents=True, exist_ok=True)
Path(maps_unzip_dir).mkdir(parents=True, exist_ok=True)

# cp ff_src to ff_dst
shutil.copy(ff_src, ff_dst)

# delete content of maps_unzip_dir before each run; or not, good enough

# execute unzip command, wait unril done
if PLATFORM == "LINUX":
    unzip_cmd = f"{wine_env} wine {offzip_exe} -a {ff_dst} {maps_unzip_dir}"
elif PLATFORM == "WINDOWS":
    unzip_cmd = f"{offzip_exe} -a {ff_dst} {maps_unzip_dir}"

result = subprocess.run(unzip_cmd, shell=True, capture_output=False, text=True)
# print(f"Output: {result.stdout}")
print(f"Exit code: {result.returncode}")

# read maps_unzip_dir for list of *.txt files
txt_files = [f.absolute() for f in Path(maps_unzip_dir).rglob('*.txt')]
for file_path in txt_files:
    if PLATFORM == "LINUX":
        extract_cmd = f"{wine_env} wine {iw_ff_extract_exe} {file_path} {map_extract_dir}"
    elif PLATFORM == "WINDOWS":
        extract_cmd = f"{iw_ff_extract_exe} {file_path} {map_extract_dir}"

    # execute extract command
    result = subprocess.run(extract_cmd, shell=True, capture_output=False, text=True)
    # print(f"Output: {result.stdout}")
    print(f"Exit code: {result.returncode}")


# WINEARCH=win32 WINEPREFIX=~/.wine_cod4 wine "$PATH"offzip.exe -a "$TMP""$MAPNAME".ff "$PATH""$MAPNAME"_unzip
# WINEARCH=win32 WINEPREFIX=~/.wine_cod4 wine "$PATH"iw_ff_extract "$MAPNAME"_unzip/0000000c.txt "$PATH""$MAPNAME"_extracted`
