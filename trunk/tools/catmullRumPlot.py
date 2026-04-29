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
from matplotlib.widgets import Slider
from dotenv import load_dotenv              # apt install python3-dotenv
import os
from collections import defaultdict

getToBestWaypointData = None
waypoints = None
data = []
showCentroid = True

def extract_catmullrom_json(filename: str):
    """
    Extracts MULTIPLE navigation paths from the log file.
    Returns a list of dicts, each containing:
    {
        'pathId': int,
        'catmullRom': dict,
        'bestWaypoint': dict,
        'getToBest': dict
    }
    Only complete paths (with all 3 pieces and non-null pathId) are included.
    """
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    data_by_path = defaultdict(dict)

    def extract_json_from_line(line: str):
        """Robustly pull the first valid JSON object from a log line."""

        line = line.strip()
        line = re.sub(r'^[\d:\s]+ ', '', line).strip()
        try:
            return json.loads(line)
        except json.JSONDecodeError:
            return None

    # === 1. Parse all bestWaypointData entries ===
    for line in lines:
        if 'bestWaypointData' in line:
            item = extract_json_from_line(line)
            if item and isinstance(item.get('pathId'), int):  # must be integer, not null
                path_id = item['pathId']
                data_by_path[path_id]['bestWaypoint'] = item

    # === 2. Parse all getToBestWaypointData entries ===
    for line in lines:
        if 'getToBestWaypointData' in line:
            item = extract_json_from_line(line)
            if item and isinstance(item.get('pathId'), int):
                path_id = item['pathId']
                data_by_path[path_id]['getToBest'] = item

    # === 3. Parse all CatmullRom blocks (multi-line) ===
    i = 0
    while i < len(lines):
        if '#CatmullRomStart' in lines[i]:
            raw_json = ""
            i += 1
            while i < len(lines) and '#CatmullRomEnd' not in lines[i]:
                line = lines[i]
                line = line.strip()
                line = re.sub(r'^[\d:\s]+ ', '', line).strip()
                raw_json += line                
                i += 1

            if raw_json:
                # Ensure valid JSON closure
                if not raw_json.strip().endswith('}'):
                    raw_json += '}'
                try:
                    item = json.loads(raw_json)
                    if isinstance(item.get('pathId'), int):
                        path_id = item['pathId']
                        data_by_path[path_id]['catmullRom'] = item
                except json.JSONDecodeError as e:
                    print(f"⚠️  CatmullRom JSON parse error for a block: {e}")
        else:
            i += 1

    # === Build final list (only complete paths) ===
    result = []
    
    max_pid = max(data_by_path.keys())
    # Pre-allocate list so we can index directly with pathId
    result = [None] * (max_pid + 1)

    count = 0
    for pid in sorted(data_by_path.keys()):
        d = data_by_path[pid]
        result[pid] = {
            'pathId': pid,
        }
        if {'catmullRom'} <= d.keys():
            result[pid]["catmullRom"] = d['catmullRom']
        if {'bestWaypoint'} <= d.keys():
            result[pid]["bestWaypoint"] = d['bestWaypoint']
        if {'getToBest'} <= d.keys():
            result[pid]["getToBest"] = d['getToBest']

        count += 1

    print(f"✅ Extracted {count} complete navigation path(s)")
    return result


def plot_paths(data, start_path_id: int = None):
    """Interactive plot: arrow keys + slider. Slider shows REAL pathId."""
    valid_paths = [p for p in data if p is not None]
    if not valid_paths:
        print("❌ No complete paths found to plot.")
        return

    # Find starting index (by real pathId if requested)
    current_idx = 0
    if start_path_id is not None:
        for i, p in enumerate(valid_paths):
            if p['pathId'] == start_path_id:
                current_idx = i
                break

    fig = plt.figure(figsize=(12, 9))
    ax = fig.add_subplot(111)
    plt.subplots_adjust(bottom=0.25)   # room for slider

    # Slider (internal index 0..N-1, but displayed value = real pathId)
    ax_slider = plt.axes([0.15, 0.1, 0.65, 0.03])
    slider = Slider(ax_slider, 'Path ID', 
                    valmin=0, 
                    valmax=len(valid_paths)-1, 
                    valinit=current_idx, 
                    valstep=1, 
                    initcolor='0.8')

    def get_xy(points):
        return [p[0] for p in points], [p[1] for p in points]

    def update_plot(idx):
        nonlocal current_idx
        current_idx = int(idx) % len(valid_paths)
        p = valid_paths[current_idx]
        ax.clear()

        d = p

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

        # ====================== Best Waypoint / GetToBest ======================
        showCentroid = True

        if showCentroid and "getToBest" in d and d["getToBest"]:
            meta = d["getToBest"].get("getToBestWaypointData")
            if meta:
                for key, color, label in [
                    ("origin", "yellow", "Spawn"),
                    ("centroid", "pink", "Centroid"),
                    ("bestWpPos", "purple", "FirstWp"),
                    ("nextWpPos", "grey", "SecondWp"),
                    ("cornerPos", "brown", "Proj Point")
                ]:
                    if key in meta:
                        x, y = meta[key][0], meta[key][1]
                        ax.scatter(x, y, color=color, s=80, zorder=7, marker='X', label=label)

        else:
            if "bestWaypoint" in d and d["bestWaypoint"]:
                bw = d["bestWaypoint"].get("bestWaypointData", {})
                for key, color, label, marker in [
                    ("origin", "yellow", "Spawn", 'X'),
                    ("wp1Pos", "pink", "wp1Pos", 'X'),
                    ("wp2Pos", "purple", "wp2Pos", 'X'),
                    ("wp3Pos", "grey", "wp3Pos", 'X'),
                    ("bestWpPos", "red", "bestWpPos", '*')
                ]:
                    if key in bw:
                        x, y = bw[key][0], bw[key][1]
                        ax.scatter(x, y, color=color, s=80, zorder=7, marker=marker, label=label)

        # ====================== CatmullRom ======================
        if "catmullRom" in d and d["catmullRom"]:
            cat = d["catmullRom"]

            if "original" in cat:
                x, y = get_xy(cat["original"])
                ax.plot(x, y, 'b-', linewidth=2.0, label='Original Path')
                ax.scatter(x, y, color='blue', s=60, zorder=5)

            if "midpoints" in cat:
                x, y = get_xy(cat["midpoints"])
                ax.scatter(x, y, color='orange', s=60, marker='o', 
                          edgecolors='darkorange', linewidth=1.5, label='Midpoints')

            if "noised" in cat:
                x, y = get_xy(cat["noised"])
                ax.scatter(x, y, color='red', s=140, marker='*', 
                          edgecolors='darkred', linewidth=1, label='Noised Points')

            if "smoothPath" in cat:
                x, y = get_xy(cat["smoothPath"])
                ax.plot(x, y, 'g-', linewidth=2.5, label='Smooth Path')
                ax.scatter(x, y, color='limegreen', s=20, zorder=4)

        # ====================== Styling ======================
        ax.set_title(f'Catmull-Rom Spline Path Visualization — Path ID: {p["pathId"]}', 
                     fontsize=18, pad=20)
        ax.set_xlabel('X Position')
        ax.set_ylabel('Y Position')
        ax.grid(True, linestyle='--', alpha=0.7)
        ax.legend(fontsize=11, loc='best')
        ax.set_aspect('equal', adjustable='datalim')

        # === Update slider display to show REAL pathId (not index) ===
        slider.valtext.set_text(str(p['pathId']))

        fig.canvas.draw_idle()

    # ====================== Callbacks ======================
    def on_slider_change(val):
        update_plot(val)

    def on_key(event):
        if event.key == 'right':
            new_idx = current_idx + 1
            update_plot(new_idx)
            slider.set_val(current_idx)          # sync slider position
        elif event.key == 'left':
            new_idx = current_idx - 1
            update_plot(new_idx)
            slider.set_val(current_idx)

    slider.on_changed(on_slider_change)
    fig.canvas.mpl_connect('key_press_event', on_key)

    # Initial plot
    update_plot(current_idx)
    plt.show()


if __name__ == "__main__":
    load_dotenv()
    
    project_path = os.getenv("PROJECT_PATH")
    mod_path = os.getenv("MOD_PATH")
    server_log = os.path.join(mod_path, "server_mp.log") 
    
    data = extract_catmullrom_json(server_log)

    # === Command line argument handling ===
    requested_id = None
    if len(sys.argv) > 1:
        try:
            requested_id = int(sys.argv[1])
        except ValueError:
            print("❌ Usage: python script.py [pathId]")
            print("   pathId must be an integer")
            sys.exit(1)

    # If user specified a pathId, validate it
    if requested_id is not None:
        if requested_id < 0 or requested_id >= len(data) or data[requested_id] is None:
            print(f"❌ Path {requested_id} not found or has incomplete data.")
            
            # Show available paths
            available = [i for i, p in enumerate(data) if p is not None]
            if available:
                print(f"   Available pathIds: {available}")
                print(f"   Example: python script.py {available[0]}")
            else:
                print("   No complete paths found in the log file.")
            sys.exit(1)
    else:
        # No argument → use first available path
        requested_id = next((i for i, p in enumerate(data) if p is not None), None)
        if requested_id is None:
            print("❌ No complete navigation paths found in the log.")
            sys.exit(1)
        print(f"→ No pathId specified, showing first available: {requested_id}")

    # shows centroid data if True, shows bestWaypoint data if False
    showCentroid = True

    # At this point we have a valid path
    plot_paths(data, requested_id)
