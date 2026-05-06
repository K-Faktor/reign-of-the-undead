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
"""Ported makeMod.pl for Reign of the Undead, partially by Claude Haiku 4.5.

This script is intended to replicate the current makeMod.pl behavior for no-argument
builds and the common build/install workflows.
"""

import argparse
import hashlib
import os
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

# Globals (assumed declared at module level)
license = []
tab = []
todo = []
bug = []
deprecated = []
hack = []
fixme = []
oldLogging = []
undocumentedFunctions = []
documentedFunctions = []
functionEntrance = []
doxErrors = []
deprecatedFiles = []
unusedFunctions = []
unusedIncludes = []
quality = ""
sloc = 0
funcKeysByFile = {}
funcDefs = {}
processedFiles = {}
functionCounts = {}
uses = []


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


def normalize_path(value: str, project_path: Path) -> Path:
    if not value:
        return None
    path = Path(value.strip())
    if not path.is_absolute():
        path = project_path / path
    return path.expanduser().resolve()


def ensure_dir(path: Path):
    path.mkdir(parents=True, exist_ok=True)


def delete_file(path: Path):
    if not path.exists():
        return
    if path.is_file() or path.is_symlink():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def file_md5(path: Path) -> str:
    hash_md5 = hashlib.md5()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


def path_md5(path: Path) -> str:
    return hashlib.md5(str(path).encode("utf-8")).hexdigest()


def copy_file(src: Path, dst: Path, overwrite: bool = True):
    ensure_dir(dst.parent)
    if not src.exists():
        raise FileNotFoundError(f"Source file not found: {src}")
    if dst.exists() and not overwrite:
        return
    shutil.copy2(src, dst)


def build_iwd(archive_name: str, source_folders, description: str, mod_path: Path):
    archive_path = mod_path / archive_name
    ensure_dir(archive_path.parent)
    if archive_path.exists():
        archive_path.unlink()

    compression = zipfile.ZIP_DEFLATED
    with zipfile.ZipFile(archive_path, mode="w", compression=compression) as zf:
        added = False
        for rel_folder in source_folders:
            full_path = Path(rel_folder).resolve()
            if not full_path.is_dir():
                print(f"Warning: Source folder not found: {full_path}")
                continue
            basename = full_path.name
            for root, dirs, files in os.walk(full_path):
                dirs[:] = [d for d in dirs if d.lower() != ".svn"]
                root_path = Path(root)
                for file_name in files:
                    file_path = root_path / file_name
                    rel_path = file_path.relative_to(full_path)
                    arcname = Path(basename) / rel_path
                    zf.write(file_path, arcname.as_posix())
                    added = True
        if not added:
            print(f"Warning: No folders were added for {archive_name}")
            return
    print(f"Rebuilt {description}")


def build_non_debug_script_file(source_file: Path, dest_file: Path):
    ensure_dir(dest_file.parent)

    open_comment_count = 0
    remove_line = False
    in_multiline = False

    with source_file.open("r", encoding="utf-8", errors="replace") as src, \
            dest_file.open("w", encoding="utf-8") as dst:
        for line in src:
            open_count = line.count("/*")
            close_count = line.count("*/")
            open_comment_count += open_count - close_count
            if open_comment_count:
                dst.write(line)
                continue
            if "*/" in line:
                dst.write(line)
                continue

            if "<debug>" in line:
                remove_line = True
                in_multiline = True
            elif "</debug>" in line:
                remove_line = True
                in_multiline = False
            elif "//" in line and "<debug />" in line:
                remove_line = True
            elif line.lstrip().startswith("log(\"trace\""):
                remove_line = True
            elif line.lstrip().startswith("log(\"debug\""):
                remove_line = True
            elif line.lstrip().startswith("log(\"value\""):
                remove_line = True
            elif line.lstrip().startswith("log(\"signal\""):
                remove_line = True
            elif line.lstrip().startswith("log(\"dev\""):
                remove_line = True
            elif line.lstrip().startswith("log(\"automaptest\""):
                remove_line = True
            if remove_line:
                line = "\n"
                if not in_multiline:
                    remove_line = False
            dst.write(line)


def load_files(root_dir: Path):
    files = []
    for path in root_dir.rglob("*"):
        if path.is_dir():
            continue
        strpath = path.as_posix()
        if "/.svn" in strpath:
            continue
        if "/rotu21" in strpath:
            continue
        if "checksums.txt" in path.name.lower():
            continue
        if strpath.endswith("_spawnlogic.gsc") or strpath.endswith("_spawnlogic_cod_original.gsc"):
            continue
        files.append(path)
    return files


def find_changes(root_dir: Path, checksum_file: Path, config):
    files = load_files(root_dir)
    current_map = {}
    try:
        with checksum_file.open("r", encoding="utf-8") as fh:
            for line in fh:
                line = line.rstrip("\n")
                if not line:
                    continue
                parts = line.split("|", 1)
                if len(parts) != 2:
                    continue
                current_map[parts[0]] = parts[1]
    except Exception as exc:
        print(f"Checksum file unreadable: {exc}")
        return None, files

    rebuild_flags = {
        "rebuild2D": False,
        "rebuildWeapons": False,
        "rebuildSound": False,
        "rebuildServerCustom": False,
        "rebuildServerScripts": False,
        "rebuildCustomIwd": False,
        "rebuildCustomMapsIwd": False,
        "rebuildMod": False,
        "installConfig": False,
        "installBatchFiles": False,
    }

    for file_path in files:
        if not file_path.is_file():
            continue
        if "checksum" in file_path.name.lower():
            continue
        try:
            digest = file_md5(file_path)
        except Exception as exc:
            print(f"Warning: Unable to hash {file_path}: {exc}")
            continue
        key = path_md5(file_path)
        if current_map.get(key) == digest:
            continue

        if "/maps/" in file_path.as_posix() or "/scripts/" in file_path.as_posix():
            rebuild_flags["rebuildServerScripts"] = True
            rebuild_flags["rebuildCustomMapsIwd"] = True
        elif "/custom/" in file_path.as_posix():
            rebuild_flags["rebuildCustomIwd"] = True
        elif "/custom_scripts/" in file_path.as_posix() or "/animtrees/" in file_path.as_posix():
            rebuild_flags["rebuildServerScripts"] = True
            rebuild_flags["rebuildServerCustom"] = True
        elif "/images/" in file_path.as_posix():
            rebuild_flags["rebuild2D"] = True
            rebuild_flags["rebuildMod"] = True
        elif "/weapons/" in file_path.as_posix():
            rebuild_flags["rebuildWeapons"] = True
            rebuild_flags["rebuildMod"] = True
        elif "/sound/" in file_path.as_posix():
            rebuild_flags["rebuildSound"] = True
            rebuild_flags["rebuildMod"] = True
        elif any(x in file_path.as_posix() for x in ["/ui_mp/", "/mp/", "/english/", "/soundaliases/", "/xanim/", "/xmodel/", "/xmodelparts/", "/xmodelsurfs/", "/materials", "/material_properties/", "/fx/", "/shock/", "/vision/"]):
            rebuild_flags["rebuildMod"] = True
        elif file_path.name.lower().endswith(".cfg"):
            rebuild_flags["installConfig"] = True
        elif file_path.name.lower() in {"playmod.bat", "host.bat", "join.bat", "playmod.sh", "host.sh", "join.sh"}:
            rebuild_flags["installBatchFiles"] = True

        current_map[key] = digest

    return rebuild_flags, files, current_map


def build_new_checksum_file(root_dir: Path, checksum_file: Path):
    files = load_files(root_dir)
    ensure_dir(checksum_file.parent)
    with checksum_file.open("w", encoding="utf-8") as fh:
        for file_path in files:
            if not file_path.is_file():
                continue
            key = path_md5(file_path)
            digest = file_md5(file_path)
            fh.write(f"{key}|{digest}\n")
    print("Created new checksum file.")


def write_updated_checksums(checksum_file: Path, checksums_map: dict):
    """Write updated checksums after an incremental build."""
    ensure_dir(checksum_file.parent)
    with checksum_file.open("w", encoding="utf-8") as fh:
        for key, digest in sorted(checksums_map.items()):
            fh.write(f"{key}|{digest}\n")


def rebuild_mod(config, root_dir: Path):
    if not config["rebuildMod"]:
        print("We do not need to rebuild mod.ff")
        return

    print("Copying files as required so we can build mod.ff...")
    cod_path = config["codPath"]
    build_raw = cod_path / "raw"
    build_zone_source = cod_path / "zone_source"
    build_zone_english = cod_path / "zone" / "english"

    for p in [build_raw, build_zone_source, build_zone_english]:
        ensure_dir(p)

    folders = [
        "ui_mp",
        "mp",
        "maps",
        "animtrees",
        "english",
        "soundaliases",
        "xanim",
        "xmodel",
        "xmodelparts",
        "xmodelsurfs",
        "materials",
        "material_properties",
        "fx",
        "shock",
        "vision",
        "images",
        "sound",
        "weapons",
    ]

    for folder in folders:
        source = root_dir / "src" / folder
        destination = build_raw / folder
        ensure_dir(destination)
        if source.is_dir():
            copied = 0
            for src_file in source.rglob("*"):
                if src_file.is_dir():
                    continue
                if ".svn" in src_file.as_posix().lower():
                    continue
                relative = src_file.relative_to(source)
                dest_file = destination / relative
                ensure_dir(dest_file.parent)
                shutil.copy2(src_file, dest_file)
                copied += 1
            if copied:
                print(f"Copied {copied} files from {folder}")
        else:
            print(f"Warning: Source folder not found: {source}")

    mod_csv_src = root_dir / "src" / "mod.csv"
    mod_csv_dst = build_zone_source / "mod.csv"
    if mod_csv_src.exists():
        shutil.copy2(mod_csv_src, mod_csv_dst)
    else:
        print(f"Warning: mod.csv not found at {mod_csv_src}")

    zs_src = root_dir / "src" / "zone_source"
    if zs_src.is_dir():
        copied = 0
        for src_file in zs_src.rglob("*.csv"):
            if src_file.is_dir():
                continue
            relative = src_file.relative_to(zs_src)
            dest_file = build_zone_source / relative
            ensure_dir(dest_file.parent)
            shutil.copy2(src_file, dest_file)
            copied += 1
        if copied:
            print(f"Copied {copied} zone_source files")
    else:
        print(f"Warning: Source zone_source folder not found: {zs_src}")

    linker_exe = cod_path / "bin" / "linker_pc.exe"
    if not linker_exe.is_file():
        raise FileNotFoundError(f"Error: linker_pc.exe not found at {linker_exe}")

    original_cwd = Path.cwd()
    os.chdir(linker_exe.parent)
    wine_prefix = Path.home() / ".wine_cod4"
    cmd = [
        "wine",
        str(linker_exe),
        "-language",
        "english",
        "-compress",
        "-cleanup",
        "-verbose",
        "mod",
    ]
    environment = os.environ.copy()
    environment["WINEPREFIX"] = str(wine_prefix)
    print("Running linker with 32-bit prefix:")
    print(" ", " ".join(cmd))
    if shutil.which("wine") is None:
        raise RuntimeError("wine executable not found on PATH")
    process = subprocess.run(
        [
            "wine",
            str(linker_exe),
            "-language",
            "english",
            "-compress",
            "-cleanup",
            "-verbose",
            "mod",
        ],
        env={**os.environ, "WINEPREFIX": str(wine_prefix)},
        check=False,
    )
    os.chdir(original_cwd)
    if process.returncode != 0:
        raise RuntimeError(f"linker_pc.exe failed with code {process.returncode}")

    ff_src = cod_path / "zone" / "english" / "mod.ff"
    if not ff_src.is_file():
        raise FileNotFoundError(f"mod.ff was not created in {ff_src.parent}")

    ensure_dir(config["modPath"])
    ff_dst = config["modPath"] / "mod.ff"
    shutil.copy2(ff_src, ff_dst)
    print("Rebuilt mod.ff")
    print("Finished building the mod.ff fastfile. The rumble errors are harmless.")


def install_config(config, root_dir: Path):
    if not config["installConfig"]:
        print("We do not need to install config files.")
        return

    ensure_dir(config["modPath"])
    local_dir = root_dir / "local"
    build_dir = root_dir / "build"
    for file_name in config["configFiles"]:
        base = Path(file_name).stem
        local_source = local_dir / f"{base}.cfg"
        default_source = root_dir / "src" / f"{base}_default.cfg"
        build_target = build_dir / file_name
        if local_source.is_file():
            copy_file(local_source, build_target)
            print(f"  ✓ Copied local {local_source.name} to build")
        elif default_source.is_file():
            copy_file(default_source, build_target)
            print(f"  ✓ Created {build_target} from default")
        else:
            print(f"Warning: Default config not found: {default_source}")
            continue

        dest = config["modPath"] / file_name
        copy_file(build_target, dest)
        print(f"  ✓ Installed {file_name} to mod folder")
    print(f"Installed config files to {config['modPath']}")


def install_batch_files(config, root_dir: Path, bash_path: str):
    if not config["installBatchFiles"]:
        print("We do not need to install batch files.")
        return

    ensure_dir(config["modPath"])
    local_dir = root_dir / "local"
    build_dir = root_dir / "build"
    base_files = ["playMod", "host", "join"]
    for base in base_files:
        for ext in ["bat", "sh"]:
            local_source = local_dir / f"{base}.{ext}"
            default_source = root_dir / "src" / f"{base}_default.{ext}"
            build_target = build_dir / f"{base}.{ext}"
            if local_source.is_file():
                copy_file(local_source, build_target)
            elif default_source.is_file():
                if ext == "sh":
                    content = default_source.read_text(encoding="utf-8", errors="replace")
                    content = content.replace("\r\n", "\n")
                    content = content.split("\n", 1)
                    if len(content) > 1 and content[0].startswith("#!"):
                        content = content[1]
                    else:
                        content = content[0] if len(content) == 1 else content[1]
                    build_target.write_text(f"#!{bash_path}\n" + content, encoding="utf-8")
                else:
                    copy_file(default_source, build_target)
            else:
                print(f"Warning: Default batch file not found: {default_source}")
                continue

            dest = config["modPath"] / f"{base}.{ext}"
            copy_file(build_target, dest)
            dest.chmod(0o700)
            print(f"  ✓ Installed {base}.{ext} to mod folder")
    print(f"Installed shell files to {config['modPath']}")


def update_upload_folder(config):
    ensure_dir(config["uploadPath"])
    print("Updating the upload folder...")

    def copy_to_upload(filename: str):
        src = config["modPath"] / filename
        dst = config["uploadPath"] / filename
        if src.is_file():
            copy_file(src, dst)
            print(f"Copied {filename} to {config['uploadPath']}")
        else:
            print(f"Warning: {filename} not found in {config['modPath']} (skipping)")

    if config["rebuildServerScripts"]:
        copy_to_upload("rotu_svr_scripts.iwd")
    if config["rebuildServerCustom"]:
        copy_to_upload("rotu_svr_custom.iwd")
    if config["rebuildCustomIwd"]:
        copy_to_upload("yz_custom.iwd")
    if config["rebuildCustomMapsIwd"]:
        copy_to_upload("rotu_svr_mapdata.iwd")
    if config["rebuildSound"]:
        copy_to_upload("sound.iwd")
    if config["rebuild2D"]:
        copy_to_upload("2d.iwd")
    if config["rebuildWeapons"]:
        copy_to_upload("weapons.iwd")
    if config["rebuildMod"]:
        copy_to_upload("mod.ff")
    if config["installConfig"]:
        for file_name in config["configFiles"]:
            copy_to_upload(file_name)

    print("Upload folder update completed.")


def rebuild_scripts_only(config, root_dir: Path, checksum_file: Path):
    build_new_checksum_file(root_dir, checksum_file)
    config.update({
        "rebuildMod": False,
        "installConfig": False,
        "installBatchFiles": False,
        "rebuild2D": False,
        "rebuildWeapons": False,
        "rebuildSound": False,
        "rebuildServerCustom": True,
        "rebuildServerScripts": True,
        "rebuildCustomIwd": False,
        "rebuildCustomMapsIwd": False,
    })
    build_iwd_files(config, root_dir)
    update_upload_folder(config)
    print("The server script files have been rebuilt.")
    # Rebuild checksum file for consistency
    build_new_checksum_file(root_dir, checksum_file)


def build_iwd_files(config, root_dir: Path):
    print("Building IWD files...")
    if config["rebuildServerScripts"]:
        generateUmiInterface(config)
        if config["buildDebugScripts"]:
            folders = [root_dir / "src" / "custom_scripts", root_dir / "src" / "maps", root_dir / "src" / "scripts"]
            build_iwd("rotu_svr_scripts.iwd", folders, "debug version of rotu_svr_scripts.iwd", config["modPath"])
        else:
            prepare_non_debug_build(root_dir)
            folders = [root_dir / "src" / "custom_scripts", root_dir / "src" / "maps", root_dir / "build" / "non_debug" / "scripts"]
            build_iwd("rotu_svr_scripts.iwd", folders, "non-debug version of rotu_svr_scripts.iwd", config["modPath"])
    else:
        print("We do not need to rebuild rotu_svr_scripts.iwd")

    if config["rebuildServerCustom"]:
        folders = [root_dir / "src" / "custom_scripts", root_dir / "src" / "animtrees"]
        build_iwd("rotu_svr_custom.iwd", folders, "rotu_svr_custom.iwd", config["modPath"])
    else:
        print("We do not need to rebuild rotu_svr_custom.iwd")

    if config["rebuildCustomIwd"]:
        folders = [root_dir / "src" / "custom" / "images", root_dir / "src" / "custom" / "sound"]
        build_iwd("yz_custom.iwd", folders, "yz_custom.iwd", config["modPath"])
    else:
        print("We do not need to rebuild yz_custom.iwd")

    if config["rebuildCustomMapsIwd"]:
        folders = [root_dir / "src" / "custom_maps" / "maps"]
        build_iwd("rotu_svr_mapdata.iwd", folders, "rotu_svr_mapdata.iwd", config["modPath"])
    else:
        print("We do not need to rebuild rotu_svr_mapdata.iwd")

    if config["rebuildSound"]:
        folders = [root_dir / "src" / "sound"]
        build_iwd("sound.iwd", folders, "sound.iwd", config["modPath"])
    else:
        print("We do not need to rebuild sound.iwd")

    if config["rebuild2D"]:
        folders = [root_dir / "src" / "images"]
        build_iwd("2d.iwd", folders, "2d.iwd", config["modPath"])
    else:
        print("We do not need to rebuild 2d.iwd")

    if config["rebuildWeapons"]:
        folders = [root_dir / "src" / "weapons"]
        build_iwd("weapons.iwd", folders, "weapons.iwd", config["modPath"])
    else:
        print("We do not need to rebuild weapons.iwd")


def prepare_non_debug_build(root_dir: Path):
    non_debug_dir = root_dir / "build" / "non_debug" / "scripts"
    if non_debug_dir.exists():
        shutil.rmtree(non_debug_dir)
    ensure_dir(non_debug_dir)
    src_scripts = root_dir / "src" / "scripts"
    if not src_scripts.is_dir():
        print(f"Warning: source scripts folder not found: {src_scripts}")
        return
    for source_file in src_scripts.rglob("*.gsc"):
        if source_file.is_file() and ".svn" not in source_file.as_posix().lower():
            dest_file = non_debug_dir / source_file.relative_to(src_scripts)
            build_non_debug_script_file(source_file, dest_file)


def clean(config, root_dir: Path):
    targets = [
        "2d.iwd",
        "rotu_svr_custom.iwd",
        "rotu_svr_scripts.iwd",
        "rotu_svr_mapdata.iwd",
        "rotu_svr_scripts.debug",
        "sound.iwd",
        "weapons.iwd",
        "yz_custom.iwd",
        "mod.ff",
        "console_mp.log",
        "server_mp.log",
        "host.bat",
        "join.bat",
        "playMod.bat",
        "host.sh",
        "join.sh",
        "playMod.sh",
    ]
    for target in targets:
        delete_file(config["modPath"] / target)
    for file_name in config["configFiles"]:
        delete_file(config["modPath"] / file_name)
    print(f"Cleaned files from {config['modPath']}")
    non_debug_dir = root_dir / "build" / "non_debug" / "scripts"
    if non_debug_dir.is_dir():
        shutil.rmtree(non_debug_dir)
    print(f"Cleaned non-debug build directory at {non_debug_dir}")


def print_version():
    print("makeMod.py port of makeMod.pl")


def print_help():
    print("Usage: makeMod.py [-f] [-s] [-d] [-c] [-q] [-h] [-v] [-r RELEASE_NAME]")
    print("  -f  Force a full rebuild")
    print("  -s  Force rebuild of server scripts only")
    print("  -d  Creates the debug version of the server script files")
    print("  -c  Clean build outputs")
    print("  -q  Quality checks")
    print("  -h  Show help")
    print("  -v  Show version")
    print("  -r  Prepare a release")


def countSloc(config):
    global sloc
    sloc = 0  # reset counter

    work_path = Path(config["workPath"])  # should end with /trunk/src

    # Define the folders and their rules
    folders = [
        (work_path / "scripts",         "*.gsc", None),
        (work_path / "maps/mp",         "*.gsc", None),
        (work_path / "custom_scripts",  "*.gsc", None),
        (work_path / "custom_maps/maps/mp", "*.gsc", {"tradespawns", "waypoints"}),
    ]

    for base_dir, pattern, exclude_keywords in folders:
        if not base_dir.exists():
            print(f"Warning: Directory not found: {base_dir}")
            continue

        for file_path in base_dir.rglob(pattern):
            filename = file_path.name.lower()
            
            # Skip excluded files in the last folder
            if exclude_keywords and any(kw in filename for kw in exclude_keywords):
                continue

            # Process the file
            lines = stripCommentsPure(str(file_path))
            sloc += count_meaningful_lines(lines)

    # print(f"Total SLOC: {sloc}")
    return sloc

def count_meaningful_lines(lines):
    """Count lines that are actual code (exclude empty, braces-only, whitespace)"""
    count = 0
    for line in lines:
        stripped = line.strip()
        if (stripped and 
            stripped not in {'{', '}', '};', '}; ', '{ }', '} ;'} and
            not stripped.startswith('#') and          # in case any preprocessor left
            len(stripped) > 1):                       # avoid single-char noise
            count += 1
    return count


def quality_check(root_dir: Path, config):
    """Run code quality checks on GSC files."""
    global license, tab, todo, bug, deprecated, hack, fixme, oldLogging
    global undocumentedFunctions, documentedFunctions, functionEntrance, doxErrors
    global deprecatedFiles, unusedFunctions, unusedIncludes, quality, sloc

    print("Running quality checks...")

    files = load_files(root_dir)

    # Find function definitions
    print("Finding function definitions...", end="")
    for file in files:
        file_str = file.as_posix()          # <--- use string for all checks
        # only test source files
        if '/src/' not in file_str:
            continue
        # only test *.gsc files
        if not file_str.endswith('.gsc'):
            continue
        findFunctionDefinitions(file_str)   # pass string path
    print("done.")

    print("Preparing files for analysis...", end="")
    for file in files:
        file_str = file.as_posix()
        if '/src/' not in file_str:
            continue
        if not file_str.endswith('.gsc'):
            continue
        stripCommentsQuality(file_str)
    print("done.")

    print("Checking files for a proper license...", end="")
    for file in files:
        file_str = file.as_posix()
        if '/src/' not in file_str:
            continue
        if not file_str.endswith('.gsc'):
            continue
        if '_waypoints.gsc' in file_str or '_tradespawns.gsc' in file_str:
            continue

        try:
            with open(file, 'r', encoding='utf-8', errors='ignore') as R:
                contents = R.read()
        except Exception as e:
            print(f"Warning: can't open {file}: {e}")
            continue

        match = re.search(r'.*/(src/.*)', file_str)
        relFile = match.group(1) if match else file_str

        if not (re.search(r'Copyright \(c\) 2010-2026 Reign of the Undead Team', contents) and
                re.search(r'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND', contents)):
            license.append(f"Missing or improper license: {relFile}")
    print("done.")

    print("Checking files for tab characters (use spaces instead!)...", end="")
    for file in files:
        file_str = file.as_posix()
        if '/src/' not in file_str:
            continue
        if not re.search(r'(\.gsc|\.menu|\.cfg|\.txt)$', file_str):
            continue

        try:
            with open(file, 'r', encoding='utf-8', errors='ignore') as R:
                contents = R.read()
        except Exception:
            continue

        match = re.search(r'.*/(src/.*)', file_str)
        relFile = match.group(1) if match else file_str

        if '\t' in contents:
            tab += f"Found tab character: {relFile}\n"
    print("done.")

    print("Checking for 'bug', 'todo', 'hack', 'fixme', and 'deprecated' notations...", end="")
    for file in files:
        file_str = file.as_posix()
        if '/src/' not in file_str or not file_str.endswith('.gsc'):
            continue
        if '/custom_maps/maps/mp/' in file_str:
            continue

        try:
            with open(file, 'r', encoding='utf-8', errors='ignore') as R:
                lines = R.readlines()
        except Exception:
            continue

        match = re.search(r'.*/(src/.*)', file_str)
        relFile = match.group(1) if match else file_str

        lineNumber = 1
        lineIndex = 0
        functionLines = []

        for line in lines:
            # line = line.strip()
            if re.search(r'@todo\b', line, re.IGNORECASE):
                todo.append(f"Todo found: {relFile}:{lineNumber}:  {line.strip()}")
            elif re.search(r'@bug\b', line, re.IGNORECASE):
                bug.append(f"Bug found: {relFile}:{lineNumber}:  {line.strip()}")
            elif re.search(r'@deprecated\b', line, re.IGNORECASE):
                if "_zombiescript.gsc" not in file_str:
                    deprecated.append(f"Deprecated item found: {relFile}:{lineNumber}:  {line.strip()}")
            elif re.search(r'hack:', line, re.IGNORECASE):
                hack.append(f"Hack found: {relFile}:{lineNumber}:  {line.strip()}")
            elif re.search(r'fixme', line, re.IGNORECASE):
                fixme.append(f"Fixme found: {relFile}:{lineNumber}:  {line.strip()}")
            elif re.search(r'debugprint\(', line, re.IGNORECASE) or  \
                 re.search(r'errorprint\(', line, re.IGNORECASE) or \
                 re.search(r'warnprint\(', line, re.IGNORECASE) or \
                 re.search(r'noticeprint\(', line, re.IGNORECASE):
                oldLogging.append(f"Old logging method found: {relFile}:{lineNumber}:  {line.strip()}")
            # elif re.search(r'^\w*\(.*\)\n', line, re.IGNORECASE):
            elif re.search(r'^\w+\s*\([^)]*\)\s*(?://.*quality:external_interface)?', line, re.IGNORECASE):
                functionLines.append(lineIndex)

            lineNumber += 1
            lineIndex += 1

        for index in functionLines:
            if index - 1 < 0 or index >= len(lines):
                continue
            testLine = lines[index - 1]
            functionLine = lines[index]
            lineNumber = index + 1

            filename = file.name[:-4] if file.name.endswith('.gsc') else file.name

            match = re.search(r'(^\w*)\((.*)\).*;{0,0}\n', functionLine, re.IGNORECASE)
            functionName = match.group(1) if match else ""
            # args = match.group(2) if match else ""

            # Load function ID for unused check
            path = relFile.replace('src/', '', 1).replace('.gsc', '').replace('/', '\\')
            if functionName not in ("init", "main"):
                function = f"{path}::{functionName}"
                functionCounts[function] = 0

            if (re.search(r'main\(\)', functionLine) or
                re.search(r'load_tradespawns\(\)', functionLine) or
                re.search(r'load_waypoints\(\)', functionLine)):
                continue

            testLine = lines[index + 2] if index + 2 < len(lines) else ""
            pattern = re.compile(
                r'    log\("trace", "msg|in ' + re.escape(filename) +
                r'::' + re.escape(functionName) + r'\(\)"'
            )
            # print(testLine)
            if not pattern.search(testLine):
                # if not re.search(r'most-called function', testLine) or not re.search(r'quality:ignore_trace', testLine):
                if ("most-called function" not in testLine and 
                    "quality:ignore_trace" not in testLine):
                        if "_unified_mapping_interface.gsc" not in file_str:
                            functionEntrance.append(f"Missing or wrong function entrance debug statement found: {relFile}:{lineNumber}:  {functionLine.strip()}  {testLine.strip()}")
    print("done.")

    print("Analyzing functions...", end="")
    start_file = "../src/maps/mp/gametypes/surv.gsc"
    # Convert to absolute if needed
    if not os.path.isabs(start_file):
        start_file = str((root_dir / start_file.lstrip('../')).resolve())

    findFunctionCalls(start_file, config)

    # Deprecated files check
    uniqueFiles = [v.replace('/', '\\') for v in processedFiles.values()]
    sorted_unique = sorted(set(uniqueFiles))

    for file in files:
        file_str = file.as_posix()
        if '/src/' not in file_str or not file_str.endswith('.gsc'):
            continue
        if '/custom_maps/maps/mp/' in file_str:
            continue
        match = re.search(r'.*/src/(.*)', file_str)
        relFile = match.group(1).replace('/', '\\') if match else file_str

        if relFile not in sorted_unique:
            if relFile not in ('maps\\mp\\_load.gsc',
                               'maps\\mp\\gametypes\\dm.gsc',
                               'maps\\mp\\gametypes\\surv.gsc',
                               'maps\\mp\\gametypes\\war.gsc'):
                deprecatedFiles.append(f"Possibly deprecated file: {file_str}")

    # Unused functions
    for key in sorted(funcDefs.keys()):
        if len(funcDefs[key]['uses']) == 0 and not re.search(r'zombiescript', key):
            if not re.search(r'custom_maps\\maps\\mp', key) and not funcDefs[key]['isExternalInterface']:
                unusedFunctions.append(f"Unused function found: {key}()  line: {str(funcDefs[key]['lineNumber'])}")
    print("done.")

    sloc = countSloc(config)

    # === Build summary ===
    global quality
    quality = (
        f"  Found {len(license)} improperly licensed files\n"
        f"  Found {len(tab)} files with tab characters\n"
        f"  Found {len(todo)} @todo items\n"
        f"  Found {len(bug)} @bug items\n"
        f"  Found {len(deprecated)} @deprecated items\n"
        f"  Found {len(hack)} hack items\n"
        f"  Found {len(fixme)} fixme items\n"
        f"  Found {len(oldLogging)} old logging items\n"
        f"  Found {len(funcDefs)} function definitions\n"
        f"  Found {len(undocumentedFunctions)} undocumented functions\n"
        f"  Found {len(documentedFunctions)} documented functions\n"
        f"  Found {len(functionEntrance)} functions with missing or improper function entrance debug statements\n"
        f"  Found {len(doxErrors)} doxygen errors\n"
        f"  Found {len(deprecatedFiles)} possibly deprecated files\n"
        f"  Found {len(unusedFunctions)} apparently unused functions\n"
        f"  Found {len(unusedIncludes)} unused #include statements\n"
        f"\n  {sloc} Source Lines of Code in *.gsc files\n"
    )

    # Print to console
    printList(license, 25)
    printList(tab, 25)
    printList(todo, 25)
    printList(bug, 25)
    printList(deprecated, 25)
    printList(hack, 25)
    printList(fixme, 25)
    printList(oldLogging, 25)
    printList(undocumentedFunctions, 25)
    printList(functionEntrance, 25)
    printList(doxErrors, 25)
    printList(deprecatedFiles, 25)
    printList(unusedFunctions, 25)
    printList(unusedIncludes, 25)
    print(quality, end='')

    # Write report
    with open("qualityReport.log", "w", encoding="utf-8") as Q:
        Q.write(quality + "\n")
        for item in license:
            Q.write(f"{item}\n")
        for item in tab:
            Q.write(f"{item}\n")
        for item in todo:
            Q.write(f"{item}\n")
        for item in bug:
            Q.write(f"{item}\n")
        for item in deprecated:
            Q.write(f"{item}\n")
        for item in hack:
            Q.write(f"{item}\n")
        for item in fixme:
            Q.write(f"{item}\n")
        for item in oldLogging:
            Q.write(f"{item}\n")
        for item in undocumentedFunctions:
            Q.write(f"{item}\n")
        for item in functionEntrance:
            Q.write(f"{item}\n")
        for item in doxErrors:
            Q.write(f"{item}\n")
        for item in deprecatedFiles:
            Q.write(f"{item}\n")
        for item in unusedFunctions:
            Q.write(f"{item}\n")
        for item in unusedIncludes:
            Q.write(f"{item}\n")

    printFunctionUses()


def generateUmiInterface(config):
    frontmatter = """/******************************************************************************
 *    Reign of the Undead, v2.x
 *
 *    Copyright (c) 2010-2026 Reign of the Undead Team.
 *    See AUTHORS.txt for a listing.
 *
 *    Permission is hereby granted, free of charge, to any person obtaining a copy
 *    of this software and associated documentation files (the "Software"), to
 *    deal in the Software without restriction, including without limitation the
 *    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *    sell copies of the Software, and to permit persons to whom the Software is
 *    furnished to do so, subject to the following conditions:
 *
 *    The above copyright notice and this permission notice shall be included in
 *    all copies or substantial portions of the Software.
 *
 *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *    SOFTWARE.
 *
 *    The contents of the end-game credits must be kept, and no modification of its
 *    appearance may have the effect of failing to give credit to the Reign of the
 *    Undead creators.
 *
 *    Some assets in this mod are owned by Activision/Infinity Ward, so any use of
 *    Reign of the Undead must also comply with Activision/Infinity Ward's modtools
 *    EULA.
 ******************************************************************************/

/** @file _unified_mapping_interface.gsc An unified interface specification for
 * maps into CoD4 zombie mods.  Each mod should copy this interface as
 * @code maps\\mp\\_umi.gsc @endcode and then implement the specified interface in
 * @code _umi.gsc @endcode as required for their mod.
 *
 * Attention Mappers:
 *      Use `#include maps\\mp\\_umi.gsc` in your main map file--
 *      not `#include maps\\mp\\_unified_mapping_interface.gsc`.
 *
 *      This file is auto-generated, and doesn't contain the implementation.
 *      It is a reference to methods we make available for mapmakers.
 */

"""

    work_path = Path(config["workPath"])
    input_file = work_path / "maps/mp/_umi.gsc"
    output_file = work_path / "maps/mp/_unified_mapping_interface.gsc"

    if not input_file.exists():
        print(f"Error: {input_file} not found")
        return

    with open(input_file, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()

    buffer = []
    i = 0
    n = len(lines)
    functions_found = 0

    while i < n:
        line = lines[i].rstrip()

        # ONLY trigger on lines that contain the exact marker
        if '// quality:external_interface' in line:
            func_line_idx = i

            # === BACKTRACK to find the start of THIS function's Doxygen block ===
            doc_start = None
            for j in range(func_line_idx - 1, -1, -1):
                if lines[j].strip().startswith('/**'):
                    doc_start = j
                    break

            # If no Doxygen found, just use the function line itself
            if doc_start is None:
                doc_start = func_line_idx

            # === Copy the Doxygen block (unchanged) ===
            for k in range(doc_start, func_line_idx):
                buffer.append(lines[k].rstrip())

            # === Clean the function line ===
            # 1. Remove the quality comment
            cleaned = re.sub(r'// quality:external_interface.*$', '', lines[func_line_idx]).rstrip()
            # 2. Force empty body (replace anything after ) with {})
            if not cleaned.strip().endswith('}'):
                # Remove any existing body if present
                cleaned = re.sub(r'\s*\{.*$', '', cleaned).rstrip()
                cleaned += ' {}'

            buffer.append(cleaned)

            # Two blank lines between functions (as requested)
            buffer.append('')
            buffer.append('')

            functions_found += 1
            i = func_line_idx + 1
            continue

        i += 1

    # Write the output
    with open(output_file, 'w', encoding='utf-8') as f:
        temp = frontmatter + '\n'.join(buffer)
        f.write(temp)

    print(f"Generated Unified Mapping Interface: {output_file}")
    # print(f"   → Found and processed {len([b for b in buffer if b.strip().startswith('/**')])} functions")
    
    # if functions_found == 0:
    #     print("   ⚠️  No functions with '// quality:external_interface' were found")


def printList(lst, limit=None):
    if limit is None:
        limit = len(lst)          # print all
    # max(0, ...) protects against negative limits
    for item in lst[:max(0, limit)]:
        print(item)

    delta = len(lst) - limit;
    if delta > 0:
        print(f"Plus {delta} more items not shown.")


def printFunctionUses():
    file = "functionUseReport.log"
    try:
        with open(file, 'w', encoding='utf-8') as F:
            for key in sorted(funcDefs.keys()):
                # $key =~ m/(.*)\:\:/;
                match = re.search(r'(.*)::', key)
                name = match.group(1) if match else key

                F.write("Function " + name + "::" + funcDefs[key]['fnPrototype'] + "\n")
                F.write("    Definition:\n")
                F.write("        " + funcDefs[key]['file'] + ":" +
                        str(funcDefs[key]['lineNumber']) + ":" +
                        str(funcDefs[key]['columnNumber']) + "\n")
                F.write("    Uses:\n")

                useCount = len(funcDefs[key]['uses'])
                if useCount:
                    for use in funcDefs[key]['uses']:
                        # $use->{file} =~ m!.*/src/(.*)!;
                        match = re.search(r'.*/src/(.*)', use['file'])
                        relFile = match.group(1) if match else use['file']
                        # $relFile =~ s!/!\\!g;
                        relFile = relFile.replace('/', '\\')

                        F.write("        " + relFile + ":" +
                                str(use['line']) + ":" +
                                str(use['column']) + "\n")
                else:
                    F.write("        No uses of this function were found\n")

                F.write("\n")
    except Exception as e:
        raise Exception(f"can't open file: {e}")
    

# Create a version of file $contents without comments, but preserving line numbers,
def stripCommentsPure(file):
    try:
        with open(file, 'r', encoding='utf-8', errors='ignore') as R:
            lineNumber = 0
            openCommentCount = 0
            lines = []
            lines.append("")
            for line in R:
                # $open =()= $line =~ /\/\*/gi;
                open_matches = re.findall(r'/\*', line, re.IGNORECASE)
                open_count = len(open_matches)
                
                # $close =()= $line =~ /\*\//gi;
                close_matches = re.findall(r'\*/', line, re.IGNORECASE)
                close_count = len(close_matches)
                
                if open_count == 1 and close_count == 1:
                    # This line has a single /* comment */, remove it
                    line = re.sub(r'/\*.*?\*/', '', line, flags=re.IGNORECASE | re.DOTALL)
                
                # Add number of opening multi-line comment delimiters in this line
                openCommentCount += open_count
                # Subtract number of closing multi-line comment delimiters in this line
                openCommentCount -= close_count
                
                # If $openCommentCount is non-zero, we are in a multiline comment
                if openCommentCount:
                    # replace contents of line with \n
                    line = "\n"
                    lineNumber += 1
                    lines.append(line)
                    #             print $line;
                    continue
                
                # this is the last line of a multi-line comment
                if re.search(r'(.*\*/)(.*)', line, re.IGNORECASE):
                    match = re.match(r'(.*\*/)(.*)', line, re.IGNORECASE)
                    if match:
                        part1 = match.group(1)
                        part2 = match.group(2)
                        pad = ' ' * len(part1)
                        line = pad + part2 + "\n"
                        lineNumber += 1
                        lines.append(line)
                        #             print $line;
                        continue
                
                # strip // comments
                line = re.sub(r'//.*', '', line)
                lineNumber += 1
                lines.append(line)
                #         print $line;
            return lines
    except Exception as e:
        raise Exception(f"can't open file {file}: {e}")


# Create a version of file $contents without comments, but preserving line numbers
# This method does some extra stuff for code quality at the end, so worthless as a standalone
# method now.
def stripCommentsQuality(file):
    #     print "$file\n";
    try:
        with open(file, 'r', encoding='utf-8', errors='ignore') as R:
            lineNumber = 0
            openCommentCount = 0
            lines = []
            lines.append("")
            for line in R:
                # $open =()= $line =~ /\/\*/gi;
                open_matches = re.findall(r'/\*', line, re.IGNORECASE)
                open_count = len(open_matches)
                
                # $close =()= $line =~ /\*\//gi;
                close_matches = re.findall(r'\*/', line, re.IGNORECASE)
                close_count = len(close_matches)
                
                if open_count == 1 and close_count == 1:
                    # This line has a single /* comment */, remove it
                    line = re.sub(r'/\*.*?\*/', '', line, flags=re.IGNORECASE | re.DOTALL)
                
                # Add number of opening multi-line comment delimiters in this line
                openCommentCount += open_count
                # Subtract number of closing multi-line comment delimiters in this line
                openCommentCount -= close_count
                
                # If $openCommentCount is non-zero, we are in a multiline comment
                if openCommentCount:
                    # replace contents of line with \n
                    line = "\n"
                    lineNumber += 1
                    lines.append(line)
                    #             print $line;
                    continue
                
                # this is the last line of a multi-line comment
                if re.search(r'(.*\*/)(.*)', line, re.IGNORECASE):
                    match = re.match(r'(.*\*/)(.*)', line, re.IGNORECASE)
                    if match:
                        part1 = match.group(1)
                        part2 = match.group(2)
                        pad = ' ' * len(part1)
                        line = pad + part2 + "\n"
                        lineNumber += 1
                        lines.append(line)
                        #             print $line;
                        continue
                
                # strip // comments
                line = re.sub(r'//.*', '', line)
                lineNumber += 1
                lines.append(line)
                #         print $line;
    except Exception as e:
        raise Exception(f"can't open file {file}: {e}")

    # $file =~ m!.*/src/(.*)!;
    # Extract relative path after /src/
    match = re.search(r'.*/src/(.*)', file)
    if match:
        relFile = match.group(1)
    else:
        relFile = file  # fallback if no /src/ found
    
    # $relFile =~ s!/!\\!g;
    relFile = relFile.replace('/', '\\')

    # Store the comment-stripped @lines for later use
    if relFile not in funcKeysByFile:
        funcKeysByFile[relFile] = {}
    funcKeysByFile[relFile]['fileLines'] = lines[:]


def findFunctionCalls(file, config):
    global unusedIncludes, processedFiles

    # $file =~ m!.*/src/(.*)!;
    match = re.search(r'.*/src/(.*)', file)
    relFile = match.group(1) if match else file
    # $relFile =~ s!/!\\!g;
    relFile = relFile.replace('/', '\\')

    # Mark this file as already being processed
    file_hash = hashlib.md5(relFile.encode('utf-8')).hexdigest()
    processedFiles[file_hash] = relFile

    internalFuncKeys = []
    internalFileKeys = []
    lineNumber = 0
    lookingForIncludes = 1
    contents = "".join(funcKeysByFile.get(relFile, {}).get('fileLines', []))

    includeFiles = {}

    internalFileKeys.append(relFile)
    # Load the keys for the functions defined in this file
    for key in funcKeysByFile.get(relFile, {}).get('fnKeys', []):
        internalFuncKeys.append(key)

    for line in funcKeysByFile.get(relFile, {}).get('fileLines', []):
        lineNumber += 1
        include_match = re.search(r'#include\s+(.*);\n', line)
        if include_match:
            inc = include_match.group(1) + '.gsc'
            internalFileKeys.append(inc)
            includeFiles[include_match.group(1)] = {'count': 0}

            inc_hash = hashlib.md5(inc.encode('utf-8')).hexdigest()
            if inc_hash not in processedFiles:
                # recurse
                newFile = '../src/' + inc
                newFile = newFile.replace('\\', '/')
                if not os.path.exists(newFile):
                    codPath = str(config.get('codPath', ''))
                    rawFile = codPath + '/raw/' + inc
                    rawFile = rawFile.replace('\\', '/')
                    if not os.path.exists(rawFile):
                        unusedIncludes += f"Include file {inc} included in {file} does not exist in src or raw\n"
                    else:
                        findFunctionCalls(rawFile, config)
                else:
                    findFunctionCalls(newFile, config)

            # Load the keys for the functions defined in this include file
            for key in funcKeysByFile.get(inc, {}).get('fnKeys', []):
                internalFuncKeys.append(key)

        if lookingForIncludes and re.match(r'^\w', line):
            lookingForIncludes = 0

    # Search this file for function calls using the scoping operator
    for key in sorted(funcDefs.keys()):
        matchPos = 0
        extRegex = funcDefs[key]['extRegex']
        while True:
            match = extRegex.search(contents, matchPos)
            if not match:
                break
            pos = match.start(1)          # $-[1] in Perl
            matchSize = len(match.group(0))
            matchPos = pos

            # Find line and column
            lineN = 0
            colN = 0
            tmp_pos = 0
            for m in re.finditer(r'(\n)', contents):
                lineN += 1
                if m.start(1) >= pos:
                    break
                colN = pos - m.start(1)   # rough equivalent

            # Update search position
            matchPos = match.end(0)

            line = funcKeysByFile.get(relFile, {}).get('fileLines', [])[lineN] if lineN < len(funcKeysByFile.get(relFile, {}).get('fileLines', [])) else ""

            use = {
                'file': file,
                'line': lineN,
                'column': colN,
                'contents': line,
            }
            funcDefs[key]['uses'].append(use)

        # If $matchPos is non-zero, we found at least one use of this external function
        if matchPos:
            key_match = re.search(r'(.*)::', key)
            if key_match:
                refRelFile = key_match.group(1) + '.gsc'
                ref_hash = hashlib.md5(refRelFile.encode('utf-8')).hexdigest()
                if ref_hash not in processedFiles:
                    newFile = '../src/' + refRelFile
                    newFile = newFile.replace('\\', '/')
                    if not os.path.exists(newFile):
                        codPath = str(config.get('codPath', ''))
                        rawFile = codPath + '/raw/' + refRelFile
                        rawFile = rawFile.replace('\\', '/')
                        if not os.path.exists(rawFile):
                            print(f"Referenced file {refRelFile} does not exist in src or raw")
                            continue
                    findFunctionCalls(newFile, config)   # note: original calls even if raw doesn't exist, but we follow logic

    # Search this file for internal function calls
    # reset $relFile
    match = re.search(r'.*/src/(.*)', file)
    relFile = match.group(1) if match else file
    relFile = relFile.replace('/', '\\')

    for key in internalFuncKeys:
        matchPos = 0
        intRegex = funcDefs[key]['intRegex']
        while True:
            match = intRegex.search(contents, matchPos)
            if not match:
                break
            pos = match.start(1)
            matchSize = len(match.group(0))
            matchPos = pos

            # Find line and column
            lineN = 0
            colN = 0
            for m in re.finditer(r'(\n)', contents):
                lineN += 1
                if m.start(1) >= pos:
                    break
                colN = pos - m.start(1)

            matchPos = match.end(0)

            # Check if it's really a call (not in string)
            line_text = funcKeysByFile.get(relFile, {}).get('fileLines', [])[lineN] if lineN < len(funcKeysByFile.get(relFile, {}).get('fileLines', [])) else ""
            stripped = re.sub(r'".+?"', '', line_text)
            if intRegex.search(stripped):
                use = {
                    'file': file,
                    'line': lineN,
                    'column': colN,
                    'contents': line_text,
                }
                funcDefs[key]['uses'].append(use)

                # Increment include counters if applicable
                for includeKey in list(includeFiles.keys()):
                    tmp = includeKey.replace('\\', '\\\\')
                    if re.search(tmp, key, re.IGNORECASE):
                        includeFiles[includeKey]['count'] += 1

    # Are any of the include'd files unused?
    for includeKey in includeFiles:
        if includeFiles[includeKey]['count'] == 0:
            if re.search(r'common_scripts', includeKey):
                continue
            # global unusedIncludes
            unusedIncludes.append(f"Unused include file {includeKey} included in {file}")



def findFunctionDefinitions(file):
    global functions, documentedFunctions, funcDefs, funcKeysByFile

    try:
        with open(file, 'r', encoding='utf-8', errors='ignore') as R:
            lineNumber = 0
            openCommentCount = 0
            lines = []
            lines.append("")
            for line in R:
                lineNumber += 1
                lines.append(line)
                
                # Add number of opening multi-line comment delimiters
                openCommentCount += len(re.findall(r'/\*', line, re.IGNORECASE))
                # Subtract number of closing multi-line comment delimiters
                openCommentCount -= len(re.findall(r'\*/', line, re.IGNORECASE))
                
                # If $openCommentCount is non-zero, we are in a multiline comment
                if openCommentCount:
                    continue
                
                isExternalInterface = False
                if re.search(r'// quality:external_interface', line):
                    isExternalInterface = True

                # strip // comments
                line = re.sub(r'//.*', '', line)
                
                # next unless ($line =~ m/^\w/);
                if not re.match(r'^\w', line):
                    continue
                
                # $line =~ m/((\w*)\(.*?\))[ {]{0,}\n/;
                match = re.search(r'((\w*)\(.*?\))[ {]{0,}\n', line)
                if not match:
                    continue
                fnPrototype = match.group(1)
                fnName = match.group(2)
                
                if not fnPrototype:
                    continue
                
                # We don't need documentation on some functions
                if re.search(r'main\(\)', fnPrototype):
                    continue
                if re.search(r'load_tradespawns\(\)', fnPrototype):
                    continue
                if re.search(r'load_waypoints\(\)', fnPrototype):
                    continue
                
                # $file =~ m!.*/src/(.*)!;
                match = re.search(r'.*/src/(.*)', file)
                relFile = match.group(1) if match else file
                
                # $relFile =~ s!/!\\!g;
                relFile = relFile.replace('/', '\\')
                
                key = relFile + '::' + fnName
                key = key.replace('.gsc', '')   # $key =~ s!.gsc!!;
                
                columnNumber = 0
                
                # We found a function definition, now check if it is properly documented
                # if not re.search(r' \*/\n', lines[lineNumber - 1]):
                if not re.search(r' \*/\s*$', lines[lineNumber - 1]):       # allow ' */ \n'
                    global undocumentedFunctions
                    undocumentedFunctions.append(f"Undocumented function found: {relFile}:{lineNumber}:{fnPrototype}")
                else:
                    # todo check the validity of the comment block
                    validateDocumentation(lines, lineNumber, relFile)
                    global documentedFunctions
                    documentedFunctions.append(f"Documented function found: {relFile}:{lineNumber}:{fnPrototype}")
                
                # Build regexes
                tmp = key
                tmp = "(" + tmp + ")"
                tmp = tmp.replace('\\', '\\\\')
                tmp = tmp.replace(':', '\\:')
                extRegex = re.compile(tmp, re.IGNORECASE)
                
                tmp = fnName
                tmp = "(?:[ {(!])(" + tmp + ")"
                intRegex = re.compile(tmp, re.IGNORECASE)
                
                # Store function information indexed by full scope
                funcDefs[key] = {
                    'file': relFile,
                    'fnName': fnName,
                    'fnPrototype': fnPrototype,
                    'lineNumber': lineNumber,
                    'columnNumber': columnNumber,
                    'extRegex': extRegex,
                    'intRegex': intRegex,
                    'isExternalInterface': isExternalInterface,
                    'uses': list(uses),   # copy of @uses
                }
                
                # Store function keys indexed by relative filename
                if relFile not in funcKeysByFile:
                    funcKeysByFile[relFile] = {}
                if 'fnKeys' not in funcKeysByFile[relFile]:
                    funcKeysByFile[relFile]['fnKeys'] = []
                funcKeysByFile[relFile]['fnKeys'].append(key)
                
    except Exception as e:
        raise Exception(f"can't open file {file}: {e}")
    

def validateDocumentation(linesRef, functionIndex, relFile):
    global doxErrors
    dox = ""

    functionLine = linesRef[functionIndex]

    count = 0
    index = functionIndex
    while linesRef[index] != "/**\n":
        index -= 1
        count += 1
        if count > 45:
            return

    # Note: This for-loop logic is preserved exactly as in Perl (including the odd use of $index in the condition)
    for i in range(index, functionIndex):   # We still need a loop variable, but logic stays identical
        dox += linesRef[index]
        index += 1   # This mirrors the original increment behavior

    # Original regex: $functionLine =~ /(^\w*)\((.*)\).*;{0,0}\n/i;
    match = re.search(r'(^\w*)\((.*)\).*;{0,0}\n', functionLine, re.IGNORECASE)
    if match:
        functionName = match.group(1)
        arg = match.group(2)
    else:
        functionName = ""
        arg = ""

    if "_zombiescript.gsc" not in relFile:
        if arg:
            # there is some argument text, perhaps containing multiple arguments
            args = re.split(r',\s*', arg)
            if args:
                # there was at least one argument
                for arg in args:
                    arg = re.sub(r'\s*', '', arg)
                    if not re.search(r'@param ' + re.escape(arg), dox):
                        # global doxErrors
                        doxErrors.append(f"Doxygen block '{arg}' parameter is undocumented: {relFile}:{functionIndex}:  {functionName}()")

        if not re.search(r'@brief', dox):
            # global doxErrors
            doxErrors.append(f"Doxygen block missing the @brief tag: {relFile}:{functionIndex}:  {functionName}()")

        if not re.search(r'@returns', dox):
            # global doxErrors
            doxErrors.append(f"Doxygen block missing the @returns tag: {relFile}:{functionIndex}:  {functionName}()")


def release(config, root_dir: Path, release_name: str, bash_path: str):
    """Prepare a release package."""
    print(f"Creating a RotU release named {release_name}...")
    
    config["buildDebugScripts"] = False
    release_folder = config["releasePath"] / release_name
    ensure_dir(release_folder)
    
    # Copy test map from map_src
    map_folder = release_folder / "mp_surv_testmap"
    ensure_dir(map_folder)
    src_folder = config["workPath"]
    map_src = src_folder.parent.parent / "map_src" / "contrib" / "test_map" / "usermaps" / "mp_surv_testmap"
    
    if map_src.is_dir():
        for map_file in ["mp_surv_testmap.ff", "mp_surv_testmap.iwd", "mp_surv_testmap_load.ff"]:
            src = map_src / map_file
            if src.is_file():
                copy_file(src, map_folder / map_file)
        print(f"Copied test map to {release_folder}")
    else:
        print(f"Warning: Test map source not found: {map_src}")
    
    # Copy config files (rename from _default.cfg)
    src_dir = root_dir / "src"
    for file_name in config["configFiles"]:
        base = Path(file_name).stem
        default_src = src_dir / f"{base}_default.cfg"
        if default_src.is_file():
            copy_file(default_src, release_folder / file_name)
    print(f"Copied config files to {release_folder}")
    
    # Copy batch files (rename from _default versions)
    for base in ["playMod", "host", "join"]:
        for ext in ["bat", "sh"]:
            default_src = src_dir / f"{base}_default.{ext}"
            if default_src.is_file():
                copy_file(default_src, release_folder / f"{base}.{ext}")
    print(f"Copied batch files to {release_folder}")
    
    # Copy text files
    text_files = ["AUTHORS.txt", "CHANGELOG.txt", "LICENSE.txt", "README.txt"]
    for text_file in text_files:
        src = src_dir / text_file
        if src.is_file():
            copy_file(src, release_folder / text_file)
    print(f"Copied text files to {release_folder}")
    
    # Do a full non-debug build
    print("Building full release (non-debug)...")
    build_new_checksum_file(root_dir, root_dir / "build" / "checksums.txt")
    config.update({
        "rebuild2D": True,
        "rebuildWeapons": True,
        "rebuildSound": True,
        "rebuildServerCustom": True,
        "rebuildServerScripts": True,
        "rebuildCustomIwd": True,
        "rebuildCustomMapsIwd": True,
        "rebuildMod": True,
        "installConfig": True,
        "installBatchFiles": True,
    })
    build_iwd_files(config, root_dir)
    rebuild_mod(config, root_dir)
    
    # Copy built files to release folder
    iwds = [
        "rotu_svr_scripts.iwd",
        "rotu_svr_custom.iwd",
        "yz_custom.iwd",
        "rotu_svr_mapdata.iwd",
        "sound.iwd",
        "2d.iwd",
        "weapons.iwd",
    ]
    for iwd_file in iwds:
        src = config["modPath"] / iwd_file
        if src.is_file():
            copy_file(src, release_folder / iwd_file)
            print(f"Copied {iwd_file} to {release_folder}")
    
    # Copy mod.ff
    mod_ff = config["modPath"] / "mod.ff"
    if mod_ff.is_file():
        copy_file(mod_ff, release_folder / "mod.ff")
        print(f"Copied mod.ff to {release_folder}")
    
    # Create zip archive
    zip_path = config["releasePath"] / f"{release_name}.zip"
    print(f"Creating release archive: {zip_path}")
    shutil.rmtree(zip_path, ignore_errors=True)
    
    with zipfile.ZipFile(zip_path, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(release_folder):
            dirs[:] = [d for d in dirs if d.lower() != ".svn"]
            root_path = Path(root)
            for file_name in files:
                file_path = root_path / file_name
                arcname = file_path.relative_to(config["releasePath"])
                zf.write(file_path, arcname.as_posix())
    
    print(f"Saved zip archive of release to {zip_path}")
    print(f"Release {release_name} complete!")


def main():
    here = Path(__file__).resolve()
    project_default = here.parents[2] if len(here.parents) >= 3 else here.parent
    env_path = project_default / ".env"
    env = parse_env(env_path)

    project_path = normalize_path(env.get("PROJECT_PATH"), project_default) or project_default
    config = {
        "codPath": normalize_path(env.get("COD_PATH"), project_path),
        "modPath": normalize_path(env.get("MOD_PATH"), project_path),
        # "codPath": str(normalize_path(env.get("COD_PATH"), project_path)),
        # "modPath": str(normalize_path(env.get("MOD_PATH"), project_path)),
        "uploadPath": normalize_path(env.get("UPLOAD_PATH"), project_path),
        "releasePath": normalize_path(env.get("RELEASE_PATH"), project_path),
        "workPath": normalize_path(env.get("WORK_PATH"), project_path),
        "buildTarget": env.get("BUILD_TARGET", "DEBUG"),
        "platform": env.get("PLATFORM", "LINUX"),
        "server": env.get("PLATFORM", "OFFICIAL"),
        "projectPath": project_path,
        "configFiles": [item.strip() for item in env.get("CONFIG_FILES", "").split(",") if item.strip()],
        "buildDebugScripts": False,
        "rebuild2D": False,
        "rebuildWeapons": False,
        "rebuildSound": False,
        "rebuildServerCustom": False,
        "rebuildServerScripts": False,
        "rebuildCustomIwd": False,
        "rebuildCustomMapsIwd": False,
        "rebuildMod": False,
        "installConfig": False,
        "installBatchFiles": False,
    }

    root_dir = project_path / "trunk"
    checksum_file = root_dir / "build" / "checksums.txt"
    bash_path = shutil.which("bash") or "/bin/bash"

    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("-f", action="store_true")
    parser.add_argument("-s", action="store_true")
    parser.add_argument("-c", action="store_true")
    parser.add_argument("-d", action="store_true")
    parser.add_argument("-q", action="store_true")
    parser.add_argument("-h", action="store_true")
    parser.add_argument("-v", action="store_true")
    parser.add_argument("-r", type=str, default=None)
    args = parser.parse_args()

    if args.h:
        print_help()
        return
    if args.v:
        print_version()
        return
    if args.c:
        clean(config, root_dir)
        return
    if args.q:
        quality_check(root_dir, config)
        return
    if args.r:
        release(config, root_dir, args.r, bash_path)
        return

    if config["buildTarget"] == "DEBUG":
        config["buildDebugScripts"] = True  # build the debug version for DEBUG
    else:
        config["buildDebugScripts"] = False  # build the non-debug version for DEPLOY

    if args.d:
        config["buildDebugScripts"] = args.d  # force the debug version


    if args.f:
        print("Forcing a full rebuild")
        build_new_checksum_file(root_dir, checksum_file)
        config.update({
            "rebuild2D": True,
            "rebuildWeapons": True,
            "rebuildSound": True,
            "rebuildServerCustom": True,
            "rebuildServerScripts": True,
            "rebuildCustomIwd": True,
            "rebuildCustomMapsIwd": True,
            "rebuildMod": True,
            "installConfig": True,
            "installBatchFiles": True,
        })
        build_iwd_files(config, root_dir)
        rebuild_mod(config, root_dir)
        install_config(config, root_dir)
        install_batch_files(config, root_dir, bash_path)
        update_upload_folder(config)
        return
    if args.s:
        print("Forcing a rebuild of scripts only...")
        config.update({
            "rebuildServerScripts": True,
            "rebuildServerCustom": True,
            "installBatchFiles": True,
        })
        rebuild_scripts_only(config, root_dir, checksum_file)
        return

    if not checksum_file.is_file():
        print("Checksum file not found, doing a full build.")
        build_new_checksum_file(root_dir, checksum_file)
        config.update({
            "rebuild2D": True,
            "rebuildWeapons": True,
            "rebuildSound": True,
            "rebuildServerCustom": True,
            "rebuildServerScripts": True,
            "rebuildCustomIwd": True,
            "rebuildCustomMapsIwd": True,
            "rebuildMod": True,
            "installConfig": True,
            "installBatchFiles": True,
        })
        build_iwd_files(config, root_dir)
        rebuild_mod(config, root_dir)
        install_config(config, root_dir)
        install_batch_files(config, root_dir, bash_path)
        update_upload_folder(config)
        build_new_checksum_file(root_dir, checksum_file)
        return

    rebuild_flags, _files, checksums_map = find_changes(root_dir, checksum_file, config)
    if rebuild_flags is None:
        print("Checksum file unreadable, doing a full build.")
        build_new_checksum_file(root_dir, checksum_file)
        config.update({
            "rebuild2D": True,
            "rebuildWeapons": True,
            "rebuildSound": True,
            "rebuildServerCustom": True,
            "rebuildServerScripts": True,
            "rebuildCustomIwd": True,
            "rebuildCustomMapsIwd": True,
            "rebuildMod": True,
            "installConfig": True,
            "installBatchFiles": True,
        })
        build_iwd_files(config, root_dir)
        rebuild_mod(config, root_dir)
        install_config(config, root_dir)
        install_batch_files(config, root_dir, bash_path)
        update_upload_folder(config)
        return

    config.update(rebuild_flags)
    build_iwd_files(config, root_dir)
    rebuild_mod(config, root_dir)
    install_config(config, root_dir)
    install_batch_files(config, root_dir, bash_path)
    update_upload_folder(config)
    
    # Write updated checksums for next run
    write_updated_checksums(checksum_file, checksums_map)
    
    if config.get("rebuildMod"):
        print("Rebuilt mod.ff")
    print("Build complete.")


if __name__ == "__main__":
    main()
