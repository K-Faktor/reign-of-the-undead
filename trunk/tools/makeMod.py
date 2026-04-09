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
"""Ported makeMod.pl for Reign of the Undead, by Claude Haiku 4.5.

This script is intended to replicate the current makeMod.pl behavior for no-argument
builds and the common build/install workflows.
"""

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path


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
            elif line.lstrip().startswith("debugPrint("):
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
        if not config["opt_d"]:
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
    print("Usage: makeMod.py [-f] [-s] [-c] [-q] [-h] [-v] [-r RELEASE_NAME]")
    print("  -f  Force a full rebuild")
    print("  -s  Force rebuild of server scripts only")
    print("  -c  Clean build outputs")
    print("  -q  Quality checks")
    print("  -h  Show help")
    print("  -v  Show version")
    print("  -r  Prepare a release")


def quality_check(root_dir: Path):
    """Run code quality checks on GSC files."""
    print("Running quality checks...")
    files = load_files(root_dir)
    src_files = [f for f in files if "/src/" in f.as_posix() and f.suffix.lower() == ".gsc"]
    
    license_issues = []
    tab_issues = []
    todo_items = []
    bug_items = []
    deprecated_items = []
    hack_items = []
    fixme_items = []
    
    print(f"Found {len(src_files)} GSC files to check...")
    
    # License check
    for file_path in src_files:
        if "_waypoints.gsc" in file_path.name or "_tradespawns.gsc" in file_path.name:
            continue
        try:
            content = file_path.read_text(encoding="utf-8", errors="replace")
        except Exception as exc:
            print(f"Warning: Unable to read {file_path}: {exc}")
            continue
        
        if not ("Copyright (c) 2010-2013 Reign of the Undead Team" in content and
                'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND' in content):
            rel = file_path.relative_to(root_dir)
            license_issues.append(str(rel))
    
    # Tab check
    text_suffixes = {".gsc", ".menu", ".cfg", ".txt"}
    text_files = [f for f in files if "/src/" in f.as_posix() and f.suffix.lower() in text_suffixes]
    for file_path in text_files:
        try:
            content = file_path.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        if "\t" in content:
            rel = file_path.relative_to(root_dir)
            tab_issues.append(str(rel))
    
    # Line-by-line checks for notations
    for file_path in src_files:
        try:
            with file_path.open("r", encoding="utf-8", errors="replace") as fh:
                for line_num, line in enumerate(fh, 1):
                    rel = file_path.relative_to(root_dir)
                    if "@todo" in line.lower():
                        todo_items.append(f"{rel}:{line_num}")
                    if "@bug" in line.lower():
                        bug_items.append(f"{rel}:{line_num}")
                    if "@deprecated" in line.lower():
                        deprecated_items.append(f"{rel}:{line_num}")
                    if "hack:" in line.lower():
                        hack_items.append(f"{rel}:{line_num}")
                    if "fixme" in line.lower():
                        fixme_items.append(f"{rel}:{line_num}")
        except Exception:
            continue
    
    # Report
    print("\n--- Quality Report ---")
    print(f"Files with license issues:     {len(license_issues)}")
    if license_issues:
        for item in license_issues[:5]:
            print(f"  - {item}")
        if len(license_issues) > 5:
            print(f"  ... and {len(license_issues) - 5} more")
    
    print(f"Files with tab characters:     {len(tab_issues)}")
    if tab_issues:
        for item in tab_issues[:5]:
            print(f"  - {item}")
        if len(tab_issues) > 5:
            print(f"  ... and {len(tab_issues) - 5} more")
    
    print(f"@todo items found:             {len(todo_items)}")
    print(f"@bug items found:              {len(bug_items)}")
    print(f"@deprecated items found:       {len(deprecated_items)}")
    print(f"hack: items found:             {len(hack_items)}")
    print(f"fixme items found:             {len(fixme_items)}")
    print("---")


def release(config, root_dir: Path, release_name: str, bash_path: str):
    """Prepare a release package."""
    print(f"Creating a RotU release named {release_name}...")
    
    config["opt_d"] = False
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
        "uploadPath": normalize_path(env.get("UPLOAD_PATH"), project_path),
        "releasePath": normalize_path(env.get("RELEASE_PATH"), project_path),
        "workPath": normalize_path(env.get("WORK_PATH"), project_path),
        "buildTarget": env.get("BUILD_TARGET", "DEBUG"),
        "platform": env.get("PLATFORM", "LINUX"),
        "projectPath": project_path,
        "configFiles": [item.strip() for item in env.get("CONFIG_FILES", "").split(",") if item.strip()],
        "opt_d": False,
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
    parser.add_argument("-q", action="store_true")
    parser.add_argument("-h", action="store_true")
    parser.add_argument("-v", action="store_true")
    parser.add_argument("-r", type=str, default=None)
    parser.add_argument("-d", action="store_true")
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
        quality_check(root_dir)
        return
    if args.r:
        release(config, root_dir, args.r, bash_path)
        return

    config["opt_d"] = args.d

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
