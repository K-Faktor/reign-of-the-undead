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

import os
import zipfile
import tempfile
import subprocess
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load PROJECT_PATH from .env file
load_dotenv()

project_path = os.getenv("PROJECT_PATH")
if not project_path:
    print("Error: PROJECT_PATH not found in .env file")
    sys.exit(1)

project_path = Path(project_path).resolve()
maps_root = project_path / "master_maps"

# Paths to tools (works on both Linux and Windows)
IWI2DDS = "iwi2dds"          # assumes it's in PATH (recommended)
CONVERT  = "convert"         # ImageMagick convert

def extract_loadscreen(map_name: str, iwd_path: Path, output_jpg: Path) -> bool:
    """Extract loadscreen from .iwd and save as JPG"""
    iwi_candidates = [
        f"images/loadscreen_{map_name}.iwi",
        f"images/loadscreen_mp_{map_name}.iwi",
        f"images/loadscreen.iwi",
        f"Images/loadscreen_{map_name}.iwi",
        f"Images/loadscreen_mp_{map_name}.iwi",
        f"Images/loadscreen.iwi",
        f"loadscreen_{map_name}.iwi",
        f"loadscreen_mp_{map_name}.iwi",
        f"loadscreen.iwi",
    ]

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp = Path(tmp_dir)

        # try:
        #     with zipfile.ZipFile(iwd_path) as z:
        #         extracted_iwi = None
                
                # # Try exact candidates first
                # for cand in iwi_candidates:
                #     if cand in z.namelist():
                #         z.extract(cand, tmp)
                #         extracted_iwi = tmp / cand
                #         break
                
                # # Fallback: any loadscreen*.iwi that contains the map name
                # if not extracted_iwi:
                #     for member in z.namelist():
                #         if (member.lower().endswith(".iwi") and 
                #             "loadscreen" in member.lower() and 
                #             map_name.lower() in member.lower()):
                #             z.extract(member, tmp)
                #             extracted_iwi = tmp / member
                #             break

        try:
            with zipfile.ZipFile(iwd_path) as z:
                namelist = z.namelist()
                extracted_iwi = None

                # 1. Try specific named candidates first (most common & fastest)
                specific_candidates = [
                    f"images/loadscreen_{map_name}.iwi",
                    f"images/loadscreen_mp_{map_name}.iwi",
                    f"loadscreen_{map_name}.iwi",
                    f"loadscreen_mp_{map_name}.iwi",
                    "images/loadscreen.iwi",
                    "loadscreen.iwi",
                ]

                for cand in specific_candidates:
                    if cand in namelist:
                        z.extract(cand, tmp)
                        extracted_iwi = tmp / cand
                        break

                # 2. If not found, use catch-all: any loadscreen*.iwi (case-insensitive)
                if not extracted_iwi:
                    for member in namelist:
                        member_lower = member.lower()
                        if member_lower.endswith(".iwi") and "loadscreen" in member_lower:
                            # Optional: make it stricter by requiring map_name in filename
                            if map_name.lower() in member_lower or "loadscreen" in member_lower:
                                z.extract(member, tmp)
                                extracted_iwi = tmp / member
                                break

                if not extracted_iwi:
                    print(f"  ⚠️  No loadscreen.iwi found for {map_name}")
                    return False

                # iwi → dds
                dds_path = tmp / "loadscreen.dds"
                subprocess.run([IWI2DDS, "-i", str(extracted_iwi), "-o", str(dds_path)], 
                             check=True, capture_output=True)

                # dds → high-quality jpg
                output_jpg.parent.mkdir(parents=True, exist_ok=True)
                subprocess.run([CONVERT, str(dds_path), "-quality", "95", str(output_jpg)], 
                             check=True, capture_output=True)

                print(f"  ✅ {map_name}.loadscreen.jpg")
                return True

        except subprocess.CalledProcessError as e:
            print(f"  ❌ Conversion failed for {map_name}: {e}")
            return False
        except Exception as e:
            print(f"  ❌ Error processing {map_name}: {e}")
            return False


def main():
    if not maps_root.exists():
        print(f"Error: Maps folder not found at {maps_root}")
        sys.exit(1)

    print(f"Starting loadscreen extraction from: {maps_root}\n")

    processed = 0
    skipped = 0

    # Iterate through each map folder
    for map_folder in sorted(maps_root.iterdir()):
        if not map_folder.is_dir():
            continue

        map_name = map_folder.name
        iwd_file = map_folder / f"{map_name}.iwd"

        if not iwd_file.exists():
            print(f"⏭️  Skipping {map_name} (no {map_name}.iwd found)")
            skipped += 1
            continue

        output_jpg = map_folder / f"{map_name}.loadscreen.jpg"

        success = extract_loadscreen(map_name, iwd_file, output_jpg)
        if success:
            processed += 1
        else:
            skipped += 1

    print("\n" + "="*50)
    print(f"Done! Processed: {processed} | Skipped: {skipped}")
    print("="*50)


if __name__ == "__main__":
    main()