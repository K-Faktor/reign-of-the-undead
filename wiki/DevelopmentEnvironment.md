# Setting Up a Development Environment for RotU

## Introduction

This page contains instructions and information about setting up a development environment for **Reign of the Undead (RotU)**.

See second half of document for the original Windows Vista/7 documentation.


# Linux

**Applies to:** RotU 2.2.2+  
**Tested on:** Kubuntu 25.10  
**Status:** Draft

## Prerequisite Software

All of the software below is either [Free Software](http://www.gnu.org/licenses/gpl.html) or [Open Source Software](http://opensource.org/), except for the **COD Mod Tools**, which is governed by Activision/IW's EULA. All software is available at no cost.

### Git
You need a git client to download the source code from the [Github repository](https://github.com/marktaff/reign-of-the-undead)

```
sudo apt update
sudo apt install git
```

### Python
TODO: Port to python.

### Perl
**Deprecated**
Use python now with makeMod.py instead of makeMod.pl.

The build system is written in Perl, which should already be installed in Kubuntu.  Check with:
```bash
perl --version
```

If not present, then:
```bash
sudo apt update
sudo apt install perl
```

### Text Editor
A good programmer's text editor is required.  
**Strongly recommended:** [MS Visual Studio Code](https://code.visualstudio.com/)

```bash
# Download Microsoft GPG key:
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg

# Install the GPG key:
sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/

# Add the VS Code repository:
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt update
sudo apt install code
```

Install VS Code extensions (Ctrl+P, then paste, then \<enter\>):
```
# *.gsc syntax highlighting. https://marketplace.visualstudio.com/items?itemName=se2dev.cod-sense
ext install se2dev.cod-sense
```

> Note: Notepad is **not** sufficient. Wordpad is not a real text editor.

### Kompare
Useful for viewing unified diff files (`.diff`).  

```bash
sudo apt update
sudo apt install kompare
```

### 3rd Party CoD4 tools

*Untested*

[Many tools by Tom Crowley](https://tom-crowley.co.uk/downloads/).  Of particular interest are Tom IWIViewer, Tom IWI & DDS Converter, Tom FastFile Extractor, Tom xAnim Extractor, TomXmodelUtils v1.

### GIMP
For editing raster images (textures, etc.).
**Recommended:** [GIMP](http://www.gimp.org/)

```bash
sudo apt update
sudo apt install gimp
```

#### DirectDraw Surface (DDS) Plugin
Uncertain about Gimp's 2026 handing of DDS files.  This is all Untested.
  - Google Code Archive: [GIMP DDS Plugin](https://code.google.com/archive/p/gimp-dds/)
  - Github: [GIMP DDS Plugin](https://github.com/realh/gimp-dds)

Other potential options might be ImageMagick, if compiled with DDS support, or use dedicated tools like NVIDIA Texture Tools or GIMP plugins for batch conversion.

### Inkscape
For editing SVG (Scalable Vector Graphics) files.  
**Recommended:** [Inkscape](http://inkscape.org/)

```bash
sudo apt update
sudo apt install inkscape
```

## Backup CoD4

Before you begin, **strongly recommended**:  
Zip your entire `CoD4` folder and store it somewhere safe in case anything goes wrong, e.g. `CoD4.original.install.zip`

### COD4 Mod Tools
Required to build the mod.  
Download: [Call of Duty 4 Modern Warfare Mod Tools](http://callofduty.filefront.com/file/Call_of_Duty_4_Modern_Warfare_Mod_Tools;85947)

Copy `cod4mw_modtools_v1.zip` into `/home/mark/.wine/drive_c/Program Files (x86)/Activision/Call of Duty 4 - Modern Warfare/`. Then extract the zip file.  Once unzipped, you can delete the zip file (or move it elsewhere for archiving).  These tools provide `bin/linker_pc.exe`, required to build the mod.ff file for RotU.

The installed path should be like `.../Program Files (x86)/Activision/Call of Duty 4 - Modern Warfare/bin/linker_pc.exe`.  Ensure there are no other folders bewteen the main game folder and the `bin` folder.

## Backup CoD4 Again

After Mod Tools install, **strongly recommended**:  
Zip your entire `CoD4` folder and store it somewhere safe in case anything goes wrong, e.g. `CoD4.post.modtools.install.zip`

## Add to ~/.bashrc, then source it

```bash
export WINEPREFIX="$HOME/.wine_cod4"   # change to whatever prefix you're actually using for CoD4
export WINEARCH=win32                  # CoD4/mod tools are 32-bit; this is usually safer
export WINE_LARGE_ADDRESS_AWARE=1      # helps with out of memory errors during build

# May be needed (run in bash) of you get memory errors building rotu mod.ff
# ulimit -Sv unlimited
```

## Get the Source Code

Use git to clone the source code repository to a convenient local working directory.

> *Important*: Do **not** put the working copy inside your CoD4 game folder.  
> Example location: `~/rotu`
```
mkdir ~/rotu
cd ~/rotu
git clone https://github.com/marktaff/reign-of-the-undead.git
```

## Install Winetools

Trying to get linker_pc.exe to work.

```bash
# Create a new 32-bit Wine prefix specifically for CoD4 mod tools
WINEARCH=win32 WINEPREFIX=~/.wine_cod4 wineboot -u

# Install common runtime dependencies (highly recommended)
WINEPREFIX=~/.wine_cod4 winetricks vcrun2008 vcrun2010 dotnet20 corefonts
```

Installing these extra packages makes stock ModBuilder.exe run.  We do not use that exe, but if that will run under wine, and the gui starts up, that is a good indication that makeMod.pl will succeed.

```bash
winetricks dotnet40 dotnet48 d3dx9 d3dx10 vcrun2005 vcrun2010 d3dcompiler_43
```

## Common Game File Formats

`*.iwd` files are used to store compressed assets such as graphics, weapons, scripts, and audio.  These files are technically ZIP archives with a different extension, allowing them to be opened, viewed, or extracted using standard compression tools. Note that while they can be opened/edited with standard zip tools, the game may depend on specific structure and assets being in specific files.

`*.gsc` (Game Script Code) files are game script files used to store code that controls in-game events, actions, and behaviors.  They are plain-text. The [syntax](https://www.plutonium.pw/docs/modding/gsc/how-to-gsc/) is derived from C++ (this link may cover newer versions of gsc than what CoD4 uses).

 `*.ff` files are the "Fast File" format used by Infinity Ward and Treyarch, which acts as a proprietary container for game assets like 3D models, textures, audio, and scripts.  They cannot be edited with standard tools like WinRAR without risking game errors. They are produced by ModTools.

## Configure the Build System
The build system is contained primarily within `tools\makeMod.pl`.  The configuration for `makeMod.pl` is contained in `[project_root]/.env` which doesn't exist.  You need to save `tools/env.sample.txt` as `[project_root]/.env`, then edit the values in .env using your text editor. Save your changes, then use your text editor to open `tools/makeMod.pl`.

The first line is the path to the perl interpreter you previously installed. You need to edit the line as required, depending on where you installed perl.  Make sure the line begins with the shebang `#!`, and that it is the very first line in the file.  Save your changes, then close the files.

## Build the Mod
To build the mod, open a command line (cmd.exe, i.e. 'Command Prompt'), then cd as required to get to the tools directory (`~/rotu/trunk/tools` or similar). To get an idea of makeMod.pl's features, at the command prompt execute

### makeMod.pl Deprecated, use makeMod.py Instead

Old perl:
```bash
perl makeMod.pl -h
perl -w makeMod.pl
```

New python:
```bash
./makeMod.py -h
./makeMod.py
```

to build the mod.  Building may take a minute or more, depending on the speed of your computer.  When the script finishes, the mod will have been compiled, installed, and relevant files copied to the uploadPath you specified in `.env`.

## Configure the the Mod
After you build the mod the first time, copy the `*.cfg` files from the `build` folder to the `local` folder.  Those local `*.cfg` files won't be programatically edited, but they will be copied into `build` and into your built mod every time you rebuild the mod. That way, your configuration changes won't be lost every time you rebuild the mod. **Implemented in makeMod.py**

### PORTING: Work In Progess Below

In the src folder are several `*_default.bat` batch files.  These files will need to be edited. Using your text editor, open each of these files and save it in the src folder without the `_default`, i.e. save `playMod_default.bat` as `playMod.bat`.  *After* you have saved the file under the new name, edit the batch file as appropriate for your system and as desired.

## Play the Mod
Using your file manager, browse to the modPath you specified earlier, then click on `playMod.bat` to play the mod.  If it starts up OK, it is safe to copy the files from the uploadPath to your server.



# Windows Vista / Windows 7

**Applies to:** RotU 2.2  
**Tested on:** Microsoft Windows Vista, Microsoft Windows 7  
**Status:** Final


## Prerequisite Software

All of the software below is either [Free Software](http://www.gnu.org/licenses/gpl.html) or [Open Source Software](http://opensource.org/), except for the **COD Mod Tools**, which is governed by Activision/IW's EULA. All software is available at no cost.

### Subversion
You need a Subversion client to download the source code.  
**Recommended:** [TortoiseSVN](http://tortoisesvn.net/)  
[TortoiseSVN Primer](http://tortoisesvn.net/docs/release/TortoiseSVN_en/tsvn-dug.html)

### Perl
The build system is written in Perl.  
**Recommended:** [Strawberry Perl](http://strawberryperl.com/)

### Text Editor
A good programmer's text editor is required.  
**Strongly recommended:** [Kate (KDE Advanced Text Editor)](http://kate-editor.org/get-it/)

> Note: Notepad is **not** sufficient. Wordpad is not a real text editor.

### Kompare
Useful for viewing unified diff files (`.diff`).  
Usually installed together with the KDE for Windows tools (when you install Kate).

### GIMP
For editing raster images (textures, etc.).  DDS is 'DirectDraw Surface'
**Recommended:** [GIMP](http://www.gimp.org/) + [GIMP DDS Plugin](http://code.google.com/p/gimp-dds/)

### Inkscape
For editing SVG (Scalable Vector Graphics) files.  
**Recommended:** [Inkscape](http://inkscape.org/)

### COD4 Mod Tools
Required to build the mod.  
Download: [Call of Duty 4 Modern Warfare Mod Tools](http://callofduty.filefront.com/file/Call_of_Duty_4_Modern_Warfare_Mod_Tools;85947)

## Backup CoD4

Before you begin, **strongly recommended**:  
Zip your entire `CoD4` folder and store it somewhere safe in case anything goes wrong.

## Get the Source Code

Use your Subversion client to check out the source code to a convenient local working directory.

> **Important**: Do **not** put the working copy inside your CoD4 folder.  
> Example location: `C:\Users\Mark\work\rotu\trunk`

### Anonymous Checkout (recommended for most users)
```plaintext
http://reign-of-the-undead.googlecode.com/svn/trunk
```

### Developers Checkout

  Developers should checkout using a secure https connection using the credentials you were given:

```plaintext
https://reign-of-the-undead.googlecode.com/svn/trunk
```

## Configure the Build System
The build system is contained primarily within `build\makeMod.pl`.  The configuration for `makeMod.pl` is contained in `build\makeConfig.pl`. Using your text editor, open `makeConfig.pl` and edit the `codPath`, `modPath`, and `uploadPath` variables as required for your system. Save your changes, then use your text editor to open `makeMod.pl`.

The first line is the path to the perl interpreter you previously installed. You need to edit the line as required, depending on where you installed perl.  Make sure the line begins with the shebang `#!`, and that it is the very first line in the file.  Save your changes, then close the files.

### Windows 7 Note:
If your `CoD4` install is on a different drive than the source code you downloaded, the mod will not compile as is.  This is because Microsoft changed the 'cd' command.  If this applies to you, delete the file `build\makeFF.bat`, then rename `build\makeFF_win7.bat` to `build\makeFF.bat`.

## Configure the the Mod
In the src folder are several `*_default.cfg` configuration files.  These files will need to be edited. Using your text editor, open each of these files and save it in the src folder without the `_default`, i.e. save `server_default.cfg` as `server.cfg`.  *After* you have saved the file under the new name, edit the config settings as appropriate for your system and as desired.

In the src folder are several `*_default.bat` batch files.  These files will need to be edited. Using your text editor, open each of these files and save it in the src folder without the `_default`, i.e. save `playMod_default.bat` as `playMod.bat`.  *After* you have saved the file under the new name, edit the batch file as appropriate for your system and as desired.

## Build the Mod
To build the mod, open a command line (cmd.exe, i.e. 'Command Prompt'), then cd as required to get to the build directory (C:\Users\Mark\work\rotu\trunk\build or similar). To get an idea of makeMod.pl's features, at the command prompt execute

`perl makeMod.pl -h`

Once you've read that brief documentation, execute

`perl makeMod.pl`

to build the mod.  Building may take a minute or more, depending on the speed of your computer.  When the script finishes, the mod will have been compiled, installed, and relevant files copied to the uploadPath you specified in `makeConfig.pl`.

## Play the Mod
Using your file manager, browse to the modPath you specified earlier, then click on `playMod.bat` to play the mod.  If it starts up OK, it is safe to copy the files from the uploadPath to your server.

**New home of the source code**: [https://github.com/marktaff/reign-of-the-undead](https://github.com/marktaff/reign-of-the-undead)

*Originally released from the Google Code SVN repository.*
