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
Map checking and validation script for Reign of the Undead.
Checks for missing files, md5sums, json entries, custom GSC files, and map_testing folders.
"""

import os
import sys
import json
import hashlib
from pathlib import Path
from dotenv import load_dotenv              # apt install python3-dotenv

def get_md5(file_path):
    """Calculate MD5 hash of a file."""
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def create_md5sum_file(file_path):
    """Create a .md5sum file for the given file."""
    md5_hash = get_md5(file_path)
    md5_file_path = f"{file_path}.md5sum"
    print(f"Needed md5: md5_file_path")
    with open(md5_file_path, "w") as f:
        f.write(f"{md5_hash} {os.path.basename(file_path)}\n")
    return md5_file_path

def find_readme(map_dir):
    """Find readme.txt with case-insensitive and spelling variations."""
    readme_patterns = [
        "readme.txt",
        "README.txt",
        "Readme.txt",
        "readme.TXT",
        "README.TXT",
        "readmed.txt",
        "readmme.txt",
    ]
    for pattern in readme_patterns:
        readme_path = os.path.join(map_dir, pattern)
        if os.path.exists(readme_path):
            return True
    return False

def main():
    # Load environment variables
    load_dotenv()
    
    project_path = os.getenv("PROJECT_PATH")
    cod_path = os.getenv("COD_PATH")
    
    if not project_path:
        print("Error: PROJECT_PATH not set in .env file")
        sys.exit(1)
    
    # Ensure paths are absolute
    project_path = os.path.abspath(project_path)
    
    # Define paths
    master_maps_dir = os.path.join(project_path, "master_maps")
    maps_json_path = os.path.join(project_path, "maps.json")
    custom_maps_dir = os.path.join(project_path, "trunk", "src", "custom_maps", "maps", "mp")
    map_testing_dir = os.path.join(project_path, "map_testing")
    log_file = os.path.join(project_path, "_private.maps.log")
    
    # Open log file for writing
    with open(log_file, "w") as log:
        log.write("=" * 80 + "\n")
        log.write("MAP VALIDATION REPORT\n")
        log.write("=" * 80 + "\n\n")
        
        # Check if master_maps directory exists
        if not os.path.isdir(master_maps_dir):
            log.write(f"ERROR: master_maps directory not found at {master_maps_dir}\n")
            return
        
        # Get list of all maps
        all_maps = sorted([d for d in os.listdir(master_maps_dir) 
                          if os.path.isdir(os.path.join(master_maps_dir, d))])
        
        log.write(f"Found {len(all_maps)} maps in master_maps/\n\n")
        
        # ===== SECTION 1: Missing Files =====
        log.write("=" * 80 + "\n")
        log.write("SECTION 1: MISSING FILES\n")
        log.write("=" * 80 + "\n\n")
        
        created_md5_files = set()
        
        for map_name in all_maps:
            map_dir = os.path.join(master_maps_dir, map_name)
            missing_files = []
            
            # Define expected files
            expected_files = [
                f"{map_name}.ff",
                f"{map_name}_load.ff",
                f"{map_name}.iwd",
                "readme.txt",
                f"small_{map_name}.jpg",
                f"listing_{map_name}.jpg",
            ]
            
            # Check for .ff and .iwd files and their md5sums
            for file_pattern in [f"{map_name}.ff", f"{map_name}_load.ff", f"{map_name}.iwd"]:
                file_path = os.path.join(map_dir, file_pattern)
                # print(file_path)
                if os.path.exists(file_path):
                    md5_file = f"{file_path}.md5sum"
                    # print(md5_file)
                    if not os.path.exists(md5_file):
                        # print("File doen't exist", md5_file)
                        create_md5sum_file(file_path)
                        created_md5_files.add(file_pattern)
            
            # Check for regular files
            for expected_file in expected_files:
                file_path = os.path.join(map_dir, expected_file)
                if expected_file == "readme.txt":
                    if not find_readme(map_dir):
                        missing_files.append(expected_file)
                elif not os.path.exists(file_path):
                    missing_files.append(expected_file)
            
            # Report missing files for this map
            if missing_files:
                log.write(f"{map_name}/:\n")
                for missing_file in missing_files:
                    log.write(f"  - {missing_file}\n")
                log.write("\n")
        
        # ===== SECTION 2: Not in maps.json =====
        log.write("=" * 80 + "\n")
        log.write("SECTION 2: NOT IN MAPS.JSON\n")
        log.write("=" * 80 + "\n\n")
        
        maps_not_in_json = []
        
        if os.path.exists(maps_json_path):
            try:
                with open(maps_json_path, "r") as f:
                    maps_data = json.load(f)
                
                # Get list of maps in JSON
                json_maps = set()
                if "maps" in maps_data:
                    for map_entry in maps_data["maps"]:
                        if isinstance(map_entry, dict) and "codeName" in map_entry:
                            json_maps.add(map_entry["codeName"])
                
                # Find maps not in JSON
                for map_name in all_maps:
                    if map_name not in json_maps:
                        maps_not_in_json.append(map_name)
                
                if maps_not_in_json:
                    log.write(f"Found {len(maps_not_in_json)} maps not in maps.json:\n")
                    for map_name in sorted(maps_not_in_json):
                        log.write(f"  - {map_name}\n")
                else:
                    log.write("All maps are present in maps.json.\n")
            except json.JSONDecodeError:
                log.write(f"ERROR: Could not parse {maps_json_path}\n")
        else:
            log.write(f"WARNING: maps.json not found at {maps_json_path}\n")
        
        log.write("\n")
        
        # ===== SECTION 3: Missing Custom GSC =====
        log.write("=" * 80 + "\n")
        log.write("SECTION 3: MISSING CUSTOM GSC\n")
        log.write("=" * 80 + "\n\n")
        
        missing_gsc = []
        
        if os.path.isdir(custom_maps_dir):
            for map_name in all_maps:
                gsc_file = os.path.join(custom_maps_dir, f"{map_name}.gsc")
                if not os.path.exists(gsc_file):
                    missing_gsc.append(map_name)
            
            if missing_gsc:
                log.write(f"Found {len(missing_gsc)} maps missing custom GSC files:\n")
                for map_name in sorted(missing_gsc):
                    log.write(f"  - {map_name}.gsc\n")
            else:
                log.write("All maps have custom GSC files.\n")
        else:
            log.write(f"WARNING: custom_maps directory not found at {custom_maps_dir}\n")
        
        log.write("\n")
        
        # ===== SECTION 4: Missing in map_testing =====
        log.write("=" * 80 + "\n")
        log.write("SECTION 4: MISSING IN MAP_TESTING\n")
        log.write("=" * 80 + "\n\n")
        
        missing_map_testing = []
        
        if os.path.isdir(map_testing_dir):
            for map_name in all_maps:
                testing_dir = os.path.join(map_testing_dir, map_name)
                if not os.path.isdir(testing_dir):
                    missing_map_testing.append(map_name)
            
            if missing_map_testing:
                log.write(f"Found {len(missing_map_testing)} maps missing from map_testing:\n")
                for map_name in sorted(missing_map_testing):
                    log.write(f"  - {map_name}/\n")
            else:
                log.write("All maps are present in map_testing.\n")
        else:
            log.write(f"WARNING: map_testing directory not found at {map_testing_dir}\n")
        
        log.write("\n")
        
        # ===== SUMMARY =====
        log.write("=" * 80 + "\n")
        log.write("SUMMARY\n")
        log.write("=" * 80 + "\n\n")
        log.write(f"Total maps checked: {len(all_maps)}\n")
        log.write(f"Maps not in maps.json: {len(maps_not_in_json)}\n")
        log.write(f"Maps missing custom GSC: {len(missing_gsc)}\n")
        log.write(f"Maps missing from map_testing: {len(missing_map_testing)}\n")
        log.write(f"MD5sum files created: {len(created_md5_files)}\n")
        log.write("\n")
        log.write("=" * 80 + "\n")
        log.write("END OF REPORT\n")
        log.write("=" * 80 + "\n")
    
    print(f"Report written to {log_file}")

if __name__ == "__main__":
    main()
