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
CatmullRom Path Visualizer from Log File
Reads a log file, extracts the split JSON for *first instance* of CatmullRom data,
and plots the paths in 2D (X-Y top-down view).
"""

import json
import sys
import re
import matplotlib.pyplot as plt
from dotenv import load_dotenv              # apt install python3-dotenv
import os

getToBestWaypointData = None
waypoints = None

def extract_catmullrom_json(filename: str):
    global getToBestWaypointData, waypoints
    raw_json = ""
    waypoint_json = ""
    getToBestWaypointData_json = ""

    """Find the first line with {"name": "CatmullRom", read it + next line, clean and parse."""
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    readData = False

    for i, line in enumerate(lines):
        if 'bestWaypointData' in line:
            line = line.strip()
            line = re.sub(r'^[\d:\s]+ ', '', line).strip()
            waypoint_json = line
            break

    for i, line in enumerate(lines):
        if 'getToBestWaypointData' in line:
            line = line.strip()
            line = re.sub(r'^[\d:\s]+ ', '', line).strip()
            getToBestWaypointData_json = line
            break


    for i, line in enumerate(lines):
        if '#CatmullRomStart' in line:
            readData = True
            continue
        if '#CatmullRomEnd' in line:
            readData = False
            break

        if readData:
            line = line.strip()
            line = re.sub(r'^[\d:\s]+ ', '', line).strip()
            # line = line[5:].strip()
            raw_json += line

    # Concatenate and close the JSON properly
    json_str = raw_json
    # Ensure it ends with }
    if not json_str.endswith('}'):
        json_str += '}'

    try:
        waypoints = json.loads(waypoint_json)
        print(f"✅ Successfully parsed first CatmullRom data from server_mp.log lines ending at {i+1}")
    except json.JSONDecodeError as e:
        print(f"JSON parse error: {e}")
        print("Raw concatenated string:", waypoint_json)

    if getToBestWaypointData_json is not None:
        try:
            getToBestWaypointData = json.loads(getToBestWaypointData_json)
            print(f"✅ Successfully parsed first CatmullRom data from server_mp.log lines ending at {i+1}")
        except json.JSONDecodeError as e:
            print(f"JSON parse error: {e}")
            print("Raw concatenated string:", getToBestWaypointData_json)

    try:
        data = json.loads(json_str)
        print(f"✅ Successfully parsed first CatmullRom data from server_mp.log lines ending at {i+1}")
        return data
    except json.JSONDecodeError as e:
        print(f"JSON parse error: {e}")
        print("Raw concatenated string:", json_str[:500])
        sys.exit(1)
    


    print("Could not find any line containing 'CatmullRom'")
    sys.exit(1)


def plot_paths(data):
    """Plot the different path segments with requested styling."""
    fig = plt.figure(figsize=(12, 8))
    ax = fig.add_subplot(111)

    # Helper to extract x,y (ignore z for top-down view)
    def get_xy(points):
        return [p[0] for p in points], [p[1] for p in points]

    # Change colors:
    # 'b-'  → blue line,   'r--' red dashed, etc.
    # color='blue', 'orange', 'red', 'limegreen'

    # Change marker size:
    # s=60   → bigger number = bigger dots

    # Change line thickness:
    # linewidth=2.0

    # For 3D plot instead of 2D, replace the plotting section with:
    # from mpl_toolkits.mplot3d import Axes3D
    # ax = fig.add_subplot(111, projection='3d')
    # ax.plot(x, y, z, 'b-')   # etc.

    centroid = True
    if centroid:
        if getToBestWaypointData is not None:
            meta = getToBestWaypointData["getToBestWaypointData"]
            getToBestWaypointData
            if "origin" in meta:
                x = meta["origin"][0]
                y = meta["origin"][1]
                ax.scatter(x, y, color='yellow', s=80, zorder=7,  marker='X', label='Spawn')  # dots
            if "centroid" in meta:
                x = meta["centroid"][0]
                y = meta["centroid"][1]
                ax.scatter(x, y, color='pink', s=80, zorder=7, marker='X', label='Centroid')  # dots
            if "bestWpPos" in meta:
                x = meta["bestWpPos"][0]
                y = meta["bestWpPos"][1]
                ax.scatter(x, y, color='purple', s=80, zorder=7, marker='X', label='FirstWp')  # dots
            if "nextWpPos" in meta:
                x = meta["nextWpPos"][0]
                y = meta["nextWpPos"][1]
                ax.scatter(x, y, color='grey', s=80, zorder=7, marker='X', label='SecondWp')  # dots
            if "cornerPos" in meta:
                x = meta["cornerPos"][0]
                y = meta["cornerPos"][1]
                ax.scatter(x, y, color='brown', s=80, zorder=7, marker='X', label='Proj Point')  # dots
    else:
# origin": [2379.55, 1934.11, 0.125], "wp1Pos": [2412.82, 1966.39, 0.125], "wp2Pos": [2271.89, 1824.94, 6.125], "wp3Pos": [2529.21, 1851.47, 0.125], "bestWpPos": [2271.89, 1824.94, 6.125]')
        d = waypoints["bestWaypointData"]
        if "origin" in d:
        # if ["bestWaypointData"]"origin" in waypoints:
            x = d["origin"][0]
            y = d["origin"][1]
            ax.scatter(x, y, color='yellow', s=80, zorder=7,  marker='X', label='Spawn')  # dots
        if "wp1Pos" in d:
            x = d["wp1Pos"][0]
            y = d["wp1Pos"][1]
            ax.scatter(x, y, color='pink', s=80, zorder=7, marker='X', label='wp1Pos')  # dots
        if "wp2Pos" in d:
            x = d["wp2Pos"][0]
            y = d["wp2Pos"][1]
            ax.scatter(x, y, color='purple', s=80, zorder=7, marker='X', label='wp2Pos')  # dots
        if "wp3Pos" in d:
            x = d["wp3Pos"][0]
            y = d["wp3Pos"][1]
            ax.scatter(x, y, color='grey', s=80, zorder=7, marker='X', label='wp3Pos')  # dots
        if "bestWpPos" in d:
            x = d["bestWpPos"][0]
            y = d["bestWpPos"][1]
            ax.scatter(x, y, color='grey', s=80, zorder=7, marker='*', label='bestWpPos')  # dots


    # 1. Original path - Blue dots + connecting lines
    if "original" in data:
        x, y = get_xy(data["original"])
        ax.plot(x, y, 'b-', linewidth=2.0, label='Original Path')           # line
        ax.scatter(x, y, color='blue', s=60, zorder=5, label='_nolegend_')  # dots

    # 2. Midpoints - Orange dots only
    if "midpoints" in data:
        x, y = get_xy(data["midpoints"])
        ax.scatter(x, y, color='orange', s=60, marker='o', 
                  edgecolors='darkorange', linewidth=1.5, label='Midpoints')

    # 3. Noised - Red dots only
    if "noised" in data:
        x, y = get_xy(data["noised"])
        ax.scatter(x, y, color='red', s=140, marker='*', 
                  edgecolors='darkred', linewidth=1, label='Noised Points')

    # 4. SmoothPath - Green dots + connecting lines
    if "smoothPath" in data:
        x, y = get_xy(data["smoothPath"])
        ax.plot(x, y, 'g-', linewidth=2.5, label='Smooth Path')
        ax.scatter(x, y, color='limegreen', s=20, zorder=4, label='_nolegend_')

    # Styling
    ax.set_title('Catmull-Rom Spline Path Visualization', fontsize=18, pad=20)
    ax.set_xlabel('X Position')
    ax.set_ylabel('Y Position')
    ax.grid(True, linestyle='--', alpha=0.7)
    ax.legend(fontsize=12, loc='best')

    # Optional: equal aspect ratio so paths don't look stretched
    ax.set_aspect('equal', adjustable='datalim')

    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    # Load environment variables
    load_dotenv()
    
    project_path = os.getenv("PROJECT_PATH")
    mod_path = os.getenv("MOD_PATH")
    server_log = os.path.join(mod_path, "server_mp.log") 
    
    # waypoints = json.loads('{"origin": [2800, 680, 102.125], "wp1Pos": [2833.39, 705.005, 102.125], "wp2Pos": [2821.61, 543.46, 102.125], "wp3Pos": [2634.59, 702.665, 110.125], "bestWpPos": [2634.59, 702.665, 110.125]}')
    # meta = json.loads('{"origin": [2800, 680, 102.125], "centroid": [2745.43, 694.15, 102.125], "distance": 167.147, "nextWpPos": [2403.39, 706.648, 110.125], "bestWpPos": [2634.59, 702.665, 110.125], "cornerPos": [2801.71, 699.786, 110.125]}')
    data = extract_catmullrom_json(server_log)
    plot_paths(data)

