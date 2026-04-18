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

import argparse
import os
import json
import subprocess
import time
import re
from dotenv import load_dotenv
import datetime
import zoneinfo
import shutil
from pathlib import Path
import signal
import sys
import hashlib
# from datetime import datetime
from datetime import datetime, timezone

here = Path(__file__).resolve()
project_default = here.parents[2] if len(here.parents) >= 3 else here.parent
env_path = project_default / ".env"
# env = parse_env(env_path)
load_dotenv(env_path)

PROJECT_PATH = os.getenv('PROJECT_PATH')
MOD_PATH = os.getenv('MOD_PATH')
COD_PATH = os.getenv('COD_PATH')
TEST_ENVIRONMENT = os.getenv('TEST_ENVIRONMENT')

if not PROJECT_PATH or not MOD_PATH:
    print("PROJECT_PATH or MOD_PATH not set in .env")
    exit(1)

if not TEST_ENVIRONMENT:
    print("You need to set the TEST_ENVIRONMENT variable in your .env file")
    exit(1)

# Paths
map_names_json = os.path.join(PROJECT_PATH, 'master.map.names.json')
maps_json = os.path.join(PROJECT_PATH, 'maps.json')
history_file = os.path.join(PROJECT_PATH, '_private.map.test.history.txt')
master_maps_dir = os.path.join(PROJECT_PATH, 'master_maps')
playmod_script = os.path.join(MOD_PATH, 'playMod.sh')
server_log = os.path.join(MOD_PATH, 'server_mp.log')
console_log = os.path.join(MOD_PATH, 'console_mp.log')
usermaps_path = os.path.join(COD_PATH, 'usermaps')
test_platform = TEST_ENVIRONMENT 

# prob deprecated, we read from master en names now, but may be used to write new dvars to mapvote.cfg
map_cfg_path = os.path.join(PROJECT_PATH, 'trunk', 'src', 'mapvote_default.cfg')

# load master map name data
with open(map_names_json, 'r') as f:
    name_data = json.load(f)
    # Create a dictionary with mapName as key and englishName as value
    map_lookup_dict = {entry['mapName']: entry['englishName'] for entry in name_data}


def parse_env(env_path: Path):
    env = {}
    if not env_path.is_file():
        raise FileNotFoundError(f".env file not found at {env_path}")

    with env_path.open("r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            env[key.strip()] = value.strip()
    return env


def print_version():
    print(f"autoMapTester.py   version: git-{get_git_rev()}")


def print_help():
    print("Usage: autoMapTester.py [-s] [-r] [-h] [-v] [-m map_name]")
    print("  -s, --sort     Sort maps.json in ascending alpa order by map codeName")
    print("  -r, --readme   Rebuild all README.md files, including summary README.md file")
    print("  -n, --names    Pack English map names into dvar strings")
    print("  -h, --help     Show help")
    print("  -v, --version  Show version")
    print("  -m, --map      Test the given map")
    print("")
    print("  Test one specific map:")
    print("    ./autoMapTester.py -m mp_surv_testmap")
    print("")
    print("  Test all maps not in history file, one map per invocation:")
    print("    ./autoMapTester.py")


def packMapNames():
    with open(map_names_json, 'r') as f:
        data = json.load(f)

    # Ensure the key exists and is a list
    if isinstance(data, list):
        # Sort the list of maps by 'mapName', mp_surv_testmap
        data = sorted(data, key=lambda x: x['mapName'])
        packedString = ""
        characterLimit = 600
        dvarCounter = 1
        dvarName = f"sv_mapnames{dvarCounter}"
        mapCounter = 0

        # "surv_testmap:Official Test Map,"
        for item in data:
            mapCounter += 1
            key = item['mapName'].replace("mp_", "")
            val = item['englishName']
            packedItem = f"{key}:{val}"
            if len(packedString + packedItem) < characterLimit:
                if len(packedString) == 0:
                    packedString = f"{packedItem}"          # no leading comma
                else:
                    packedString = f"{packedString},{packedItem}"
            else:
                # finish old dvar
                print(f"set {dvarName} \"{packedString}\"")

                # start new dvar
                packedString = packedItem
                dvarCounter += 1
                dvarName = f"sv_mapnames{dvarCounter}"
        if dvarCounter >= 20:
            print(f"BUG: Created >= 20 dvars, but RotU will only read 20.")
        print(f"Packed {mapCounter} map names.")


def make_readme(map_data):
    # Path(master_maps_dir) / map_name
    tests = map_data['tests']
    readme_content = f"""\
![Screenshot of map]({map_data['smallImage']})

# {map_data['englishName']}

{map_data['desc']}

 - **name**: {map_data['codeName']}
 - **author**: {map_data['author']}
 - **email**: {map_data['authorContact']}
 - **web**: {map_data['authorWebsite']}

**Works\\***: {map_data['works']}
 
\\* *'Works' here just means it passed my basic checks.  It does not mean it doesn't have bugs or is a good map; just that it appears to function as a RotU map.*

**Blacklisted\\***: {map_data['blacklisted']}
 
\\* *'Blacklisted' means the map is, or will be after I exhaust efforts to fix it, blacklisted by RotU, and the mod will refuse to load the map. This helps minimize server crashes, and people trying unsuitable maps.*

## Notes

{map_data['notes']}

## Tested Version

These test results apply to the files with the MD5 hashes below. There may be multiple versions of map out there
with the same name but different data.

```
{map_data['md5Map']}
{map_data['md5Load']}
{map_data['md5Iwd']}
```

## Test Results

 - **RotU git revision**: {tests['gitRevision']}
 - **test timestamp**: {tests['timestamp']}
 - **platform**: {tests['platform']}
 - **map started**: {tests['didStartMap']}
 - **player spawned**: {tests['didSpawnHuman']}
 - **zombie spawned & stalked player**: {tests['didSpawnZombie']}
 - **waypoint validity**: {tests['waypointsValid']}
 - **weapon shops**: {tests['weaponShopCount']}
 - **equipment shops**: {tests['equipmentShopCount']}
 - **waypoint count**: {tests['waypointCount']}
 - **waypoints type**: {tests['waypointType']}
 - **compile error count**: {tests['compileErrors']}
 - **runtime error count**: {tests['runtimeErrors']}
 - **overall success**: {tests['overallSuccess']}
""".strip()

    # Save to disk
    readme_file = os.path.join(master_maps_dir, map_data['codeName'], "README.md")
    # print(readme_content)
    with open(readme_file, 'w', encoding='utf-8') as f:
        f.write(readme_content)

def get_timestamp():
    # Get current time in UTC, then convert to local timezone
    # utc_now = datetime.datetime.now(datetime.UTC)
    utc_now = datetime.now(timezone.utc)
    
    # Use America/Chicago for Central Time (automatically handles CDT/CST)
    local_tz = zoneinfo.ZoneInfo("America/Chicago")
    local_now = utc_now.astimezone(local_tz)
    
    # Format: 2026-04-07 17:05:01 CDT (UTC-5)
    timestamp = local_now.strftime("%Y-%m-%d %H:%M:%S %Z (UTC%z)")
    
    # Optional: Clean up the UTC offset (remove leading zero, e.g. -0500 → -5)
    timestamp = timestamp.replace("(UTC-0500)", "(UTC-5)") \
                         .replace("(UTC+0500)", "(UTC+5)") \
                         .replace("(UTC-0600)", "(UTC-6)") \
                         .replace("(UTC+0600)", "(UTC+6)")
    
    return timestamp


# rsync-like copy of map files from master.maps to CoD4 usermaps folder so they can be tested
def syncToUsermaps(map_name):
    src_dir = Path(master_maps_dir) / map_name
    dst_dir = Path(usermaps_path) / map_name
    
    copied = 0
    updated = 0
    
    # Create destination folder (and any parent folders) if needed
    dst_dir.mkdir(parents=True, exist_ok=True)

    for src_file in src_dir.iterdir():
        if src_file.is_file():
            dst_file = dst_dir / src_file.name

            # Copy if file doesn't exist OR source is newer than destination
            should_copy = (
                not dst_file.exists() or 
                src_file.stat().st_mtime > dst_file.stat().st_mtime
            )

            if should_copy:
                shutil.copy2(src_file, dst_file)   # copy2 preserves timestamps + metadata
                if dst_file.exists() and dst_file.stat().st_mtime >= src_file.stat().st_mtime:
                    status = "Updated" if dst_file.stat().st_size == src_file.stat().st_size else "Copied"
                    # print(f"   {status}: {src_file.name}")
                    if "Updated" in status:
                        updated += 1
                    else:
                        copied += 1

    print(f"Syncing map: {map_name}")



# get english name for the given map name
def get_map_english_name(map_name):
    # map_name = 'mp_brecourt_v2'
    if map_name in map_lookup_dict:
        # print(f"{map_name} maps to {map_lookup_dict[map_name]}")
        return map_lookup_dict[map_name]
    else:
        # print(f"{map_name} not found.")
        return None


# Get git revision
def get_git_rev():
    result = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], cwd=PROJECT_PATH, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else ''


# Sort json file for maps are in same order as file system
def sortJson():
    with open(maps_json, 'r') as f:
        data = json.load(f)

    # Ensure the 'maps' key exists and is a list
    if 'maps' in data and isinstance(data['maps'], list):
        # Sort the list of maps by 'codeName'
        data['maps'] = sorted(data['maps'], key=lambda x: x['codeName'])

        # Save the updated data back to the file
        with open(maps_json, 'w') as f:
            json.dump(data, f, indent=2)
  

# summarize the maps.json file results
def prepareSummary():
    with open(maps_json, 'r') as f:
        data = json.load(f)

    now = datetime.now()
    # Format the time as hour:minute with am/pm
    time_str = now.strftime('%I:%M%p').lstrip('0').lower()
    # Format the full date
    date_str = now.strftime('%A, %B %d, %Y')
    # Combine into the desired format
    friendly_timestamp = f"{time_str} {date_str}"        

    summary = "# Map Testing Report\n"
    summary += f"**Generated**: {friendly_timestamp}\n\n"
    summary += "[Planned] You can see the test results for each map in the README.md file in map's testing folder: map_testing/[mp_mapname]/README.md\n"

    mapsThatWork = []
    mapsWithErrors = []
    mapsWithRaygunErrors = []
    mapsWithoutFastFile = []
    mapsWithoutAuthors = []
    mapsWithoutImages = []
    mapsWithoutNames = []
    mapsToPortToRotU = []
    mapName = None
    # Ensure the 'maps' key exists and is a list
    if 'maps' in data and isinstance(data['maps'], list):
        for map in data['maps']:
            mapName = map['codeName']
            if map['works'] == "Yes":
                mapsThatWork.append(mapName)
                if map['author'] == "":
                    mapsWithoutAuthors.append(mapName)
                if map['englishName'] == "":
                    mapsWithoutNames.append(mapName)

                imgPath = os.path.join(master_maps_dir, mapName, map['listingImage'])
                if not os.path.isfile(imgPath):
                    mapsWithoutImages.append(mapName)

            if map['works'] == "Yes" or map['works'] == "Partial":
                if map['tests']['compileErrors'] > 0 or map['tests']['runtimeErrors'] > 0:
                    mapsWithErrors.append(mapName)
                if "canBuyRaygun" in map['notes']:
                    mapsWithRaygunErrors.append(mapName)

            if map['works'] == "Partial":
                if map['tests']['compileErrors'] == 0 and map['tests']['runtimeErrors'] == 0 and \
                   map['tests']['equipmentShopCount'] == 0 and map['tests']['weaponShopCount'] == 0:
                    if "Crashes" not in map['notes']:
                        mapsToPortToRotU.append(mapName)



            ffPath = os.path.join(master_maps_dir, mapName, f"{mapName}.ff")
            if not os.path.isfile(ffPath):
                mapsWithoutFastFile.append(mapName)

    summary += f"\n## Missing Authors ({len(mapsWithoutAuthors)}):\n"
    summary += "No author in readme, or extracted loadscreen, or loadscreen is in the fastfile, so wasn't extracted. More research is required.\n"
    for m in mapsWithoutAuthors: summary += f" - {m}\n"

    summary += f"\n## Working Maps Missing Names ({len(mapsWithoutNames)}):\n"
    summary += "No name in master english names json yet, as the map doesn't work well enough yet.\n"
    for m in mapsWithoutNames: summary += f" - {m}\n"

    summary += f"\n## Missing FastFiles ({len(mapsWithoutFastFile)}):\n"
    summary += "These are maps I lost files to over the years, some certainly used to work in RotU.\n"
    for m in mapsWithoutFastFile: summary += f" - {m}\n"

    summary += f"\n## Maps that Work ({len(mapsThatWork)}):\n"
    summary += "These maps passed rudimentary tests.\n"
    for m in mapsThatWork: summary += f" - {m}\n"

    summary += f"\n## Maps with Compile or Runtime Errors ({len(mapsWithErrors)}):\n"
    summary += "These maps have errors that need to be investigated. Some are errors in the maps, and some are errors in RotU.\n"
    for m in mapsWithErrors: summary += f" - {m}\n"

    summary += f"\n## Maps to Port to RotU ({len(mapsToPortToRotU)}):\n"
    summary += "These maps likely just need waypoints & tradespawns to port to RotU.\n"
    for m in mapsToPortToRotU: summary += f" - {m}\n"

    # The raygun bug was fixed, but the cause was the map was a TDM, DR, etc map, that never
    # loaded zombie stuff or called startGame()
    # summary += f"\n## Maps with Raygun Error ({len(mapsWithRaygunErrors)}):\n"
    # summary += "Wierdness here.  Could be 'out of dvars' on these maps, or they could be overriding the gametype dvar, so their entry point isn't _survival, where canBuyRaygun is set.\n"
    # for m in mapsWithRaygunErrors: summary += f" - {m}\n"


    summary_file = os.path.join(PROJECT_PATH, 'map_testing', 'READEME.md')
    with open(summary_file, "w") as f:
        f.write(f"{summary}\n")
    print(summary)

def get_md5(file_path):
    """Calculate MD5 hash of a file."""
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


def loadMd5sum(base_file):
    if os.path.isfile(base_file):
        sum_file = os.path.join(f'{base_file}.md5sum')
        if os.path.isfile(sum_file):
            try:
                with open(sum_file, 'r') as f:
                    return f.read().strip()
            except:
                return ''
        else:
            # create md5sum file if needed, and returnits contents
            md5_hash = get_md5(base_file)
            result = f"{md5_hash} {os.path.basename(base_file)}\n".strip()
            with open(sum_file, "w") as f:
                f.write(f"{result}\n")
            return result          


def rebuildAllMapReadmeFiles():
    with open(maps_json, 'r') as f:
        data = json.load(f)

    # Ensure the 'maps' key exists and is a list
    if 'maps' in data and isinstance(data['maps'], list):
        for item in data['maps']:
            map_name = item['codeName']
            # Check for md5sums that aren't noted in the json yet
            map_dir = os.path.join(master_maps_dir, map_name)

            file_path = os.path.join(map_dir, f'{map_name}.ff')
            item['md5Map'] = loadMd5sum(file_path)

            file_path = os.path.join(map_dir, f'{map_name}_load.ff')
            item['md5Load'] = loadMd5sum(file_path)

            file_path = os.path.join(map_dir, f'{map_name}.iwd')
            item['md5Iwd'] = loadMd5sum(file_path)

            make_readme(item)
        
        # Save maps.json, since new md5sum file may have been noticed
        with open(maps_json, 'w') as f:
            json.dump(data, f, indent=2)


# Get next map not in history file
def getNextMap():
    # Load tested maps
    if os.path.exists(history_file):
        with open(history_file, 'r') as f:
            tested_maps = set(line.strip() for line in f if line.strip())
    else:
        tested_maps = set()

    # Get all maps in master_maps
    all_maps = set(os.listdir(master_maps_dir))

    # Untested maps
    untested_maps = all_maps - tested_maps

    if not untested_maps:
        return False

    # Pick first untested map
    return sorted(untested_maps)[0]


def testMap(map_name):
    # make sure the map folder exists before we start changing/testing stuff
    map_dir = os.path.join(master_maps_dir, map_name)
    if not os.path.exists(map_dir):
        print(f"No such map folder {map_name} in {master_maps_dir}")
        exit(1)
    
    print(f"Testing map: {map_name}")

    # Load maps.json
    with open(maps_json, 'r') as f:
        maps_data = json.load(f)

    # Clear server log before each run
    if os.path.exists(server_log):
        with open(server_log, 'w') as f:
            f.write('')

    git_rev = get_git_rev()

    # maps need to be in CoD4 usermaps folder to test them
    syncToUsermaps(map_name)

    # Run the test
    cmd = [playmod_script, 'maptest', map_name]
    # proc = subprocess.Popen(cmd, cwd=PROJECT_PATH)
    proc = subprocess.Popen(cmd, cwd=PROJECT_PATH, preexec_fn=os.setsid)   # ← important


    # Wait up to 40 seconds
    start_time = time.time()
    while proc.poll() is None and time.time() - start_time < 120:
        time.sleep(0.1)

    if proc.poll() is None:
        print("Test took too long, killing...")
        proc.terminate()
        time.sleep(1)
        os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
        proc.wait()    
        # proc.kill()
        # proc.wait()

    # Read server_mp.log
    if os.path.exists(server_log):
        with open(server_log, 'r') as f:
            log_content = f.read()

        # Parse JSON snippets from automaptest events
        test_data = {}
        for line in log_content.split('\n'):
            match = re.search(r'{"event":\s*"automaptest".*?"msg":\s*"[^"]*",\s*(.+?)\s*}', line)
            if match:
                try:
                    snippet = json.loads('{' + match.group(1) + '}')
                    test_data.update(snippet)
                except json.JSONDecodeError:
                    pass        
    else:
        test_data = {}

    # Find or create map entry
    map_entry = None
    for m in maps_data['maps']:
        if m['codeName'] == map_name:
            map_entry = m
            break

    if not map_entry:
        # New map
        map_entry = {
            "codeName": map_name,
            "englishName": test_data.get('mapEnglishName', ''),
            "listingImage": f"listing_{map_name}.jpg",
            "smallImage": f"small_{map_name}.jpg",
            "desc": "",
            "author": "",
            "authorContact": "",
            "authorWebsite": "",
            "rating": 4,
            "works": "No",
            "blacklisted": True,
            "md5Map": "",
            "md5Load": "",
            "md5Iwd": "",
            "notes": "",
            "overallSuccess": False,
            "tests": []
        }
        maps_data['maps'].append(map_entry)

    # Add notes key if needed
    if 'notes' not in map_entry:
        map_entry['notes'] = ""

    # Normalize old-style entries into the tests list
    if 'tests' not in map_entry or not isinstance(map_entry['tests'], list):
        map_entry['tests'] = []

    # Update with test data
    map_entry['englishName'] = test_data.get('mapEnglishName', map_entry.get('englishName', ''))


    cfg_englishName = get_map_english_name(map_name)
    if map_entry['englishName'] == "" and cfg_englishName is not None:
        print(cfg_englishName)
        map_entry['englishName'] = cfg_englishName

    # Read md5 TODO: if the md5sum file doesn't exist, but the underlying file does, make the md5sum file (from checkMaps.py)
    map_dir = os.path.join(master_maps_dir, map_name)
    try:
        with open(os.path.join(map_dir, f'{map_name}.ff.md5sum'), 'r') as f:
            map_entry['md5Map'] = f.read().strip()
    except:
        map_entry['md5Map'] = ''
    try:
        with open(os.path.join(map_dir, f'{map_name}_load.ff.md5sum'), 'r') as f:
            map_entry['md5Load'] = f.read().strip()
    except:
        map_entry['md5Load'] = ''
    try:
        with open(os.path.join(map_dir, f'{map_name}.iwd.md5sum'), 'r') as f:
            map_entry['md5Iwd'] = f.read().strip()
    except:
        map_entry['md5Iwd'] = ''

    # Booleans
    server_is_up = test_data.get('serverIsUp', False)
    human_spawned = test_data.get('humanPlayerSpawned', False)
    bot_stalking = test_data.get('botSpawnedAndStalking', False)

    # Read console_mp.log, counting compile and runtime errors
    if os.path.exists(console_log):
        compileNeedle = "compile error **"
        runtimeNeedle = "runtime error **"
        compileErrorCount = 0
        runtimeErrorCount = 0
        with open(console_log, 'r') as f:
            log_content = f.read()

            for line in log_content.split('\n'):
                if compileNeedle in line: compileErrorCount += 1
                if runtimeNeedle in line: runtimeErrorCount += 1

    # Create test dict
    test_dict = {
        'gitRevision': git_rev,
        'platform': test_platform,
        'didStartMap': server_is_up,
        'didSpawnHuman': human_spawned,
        'didSpawnZombie': bot_stalking,
        'timestamp': get_timestamp(), #test_data.get('timestamp', ''),
        'waypointsValid': test_data.get('waypointsValid', ''),
        'waypointCount': int(test_data.get('waypointCount', 0)),
        'waypointType': test_data.get('waypointType', ''),
        'weaponShopCount': int(test_data.get('weaponShopCount', 0)),
        'equipmentShopCount': int(test_data.get('equipmentShopCount', 0)),
        'compileErrors': compileErrorCount,
        'runtimeErrors': runtimeErrorCount,
        'overallSuccess': bot_stalking
    }

    # Append to tests
    if 'tests' not in map_entry or not isinstance(map_entry['tests'], list):
        map_entry['tests'] = []

    # append to extisting tests, or
    # map_entry['tests'].append(test_dict)
    # clobber existing tests
    map_entry['tests'] = test_dict

    # Update top level
    map_entry['overallSuccess'] = bot_stalking
    map_entry['works'] = 'Yes' if bot_stalking else ('Partial' if server_is_up else 'No')
    map_entry['blacklisted'] = not bot_stalking

    make_readme(map_entry)

    # Save maps.json
    with open(maps_json, 'w') as f:
        json.dump(maps_data, f, indent=2)

    # Add to history
    with open(history_file, 'a') as f:
        f.write(map_name + '\n')

    print(f"Tested {map_name}, updated maps.json and history.")


def main():
    here = Path(__file__).resolve()
    project_default = here.parents[2] if len(here.parents) >= 3 else here.parent
    env_path = project_default / ".env"
    env = parse_env(env_path)
    
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("-s", "--sort", action="store_true")
    parser.add_argument("-r", "--readme", action="store_true")
    parser.add_argument("-n", "--names", action="store_true")
    parser.add_argument("-h", "--help", action="store_true")
    parser.add_argument("-v", "--version", action="store_true")
    parser.add_argument("-m", "--map", type=str, default=None)
    parser.add_argument("-x", action="store_true")
    args = parser.parse_args()

    if args.help:
        print_help()
        return
    if args.version:
        print_version()
        return
    if args.map:
        # test one, specific map given on cmd line, regardless of history file
        map_name = args.map
        testMap(map_name)
        return
    if args.sort:
        # sort maps.json file to match file system order
        sortJson()
        return
    if args.names:
        # pack map names into dvar strings
        packMapNames()
        return
    if args.readme:
        # rebuild all README.md files, including summary README.md file, then exit
        # print(f"In args.r")
        rebuildAllMapReadmeFiles()
        prepareSummary()
        return    
    if args.x:
        # -x: not in help(): for dev, calls specific method(s) to test/dev this script.
        # prepareSummary()
        pass
        return

    # print(f"In default case")
    # - default, no param operation: test all maps not in history,
    #   one map per script invocation
    map_name = getNextMap()
    if not map_name:
        print("Nothing to do, all maps tested. Remove maps from history file to re-test.")
    else:
        testMap(map_name)



if __name__ == "__main__":
    main()
