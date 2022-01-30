# My PETSCII fork

This is Vent's fork of Marq's PETSCII editor. 

See here for the original editor: http://www.kameli.net/marq/?page_id=2717

## Why?

* to fix the preview / export image size to meet the CSDb specs
* to learn some Processing/Java basics
* to try out few random ideas

# Installation

All versions are available in a single .zip package, as with the original PETSCII. 

Installation as mentioned in [Marq's PETSCII editor page](http://www.kameli.net/marq/?page_id=2717)

> It should be straightforward to download and unzip the package, after which you can run the version that corresponds to your operating system of choice: Linux, Mac or Windows. 32-bit binaries are still included, but you may encounter problems with old Windows or Mac OS versions – I can’t support and test each and every one of them.

Some enhancements done for Linux, though.

## Linux

I wanted a simple way to install and upgrade PETSCII on both mine and Junior's PCs. Hence, a package with a desktop icon!

Package -based installation introduced to simplify the updates. Desktop icon introduced for convenience.

Download the package from [releases page](https://github.com/ventti/petscii/releases/) and use your package manager to install the PETSCII editor.

Examples, assuming the currently latest release:

```sh
sudo dpkg -i petscii_0.2.0-1_amd64.deb
```

or

```sh
sudo dnf install petscii-0.2.0-1-x86_64.rpm
```

Note that .rpm is created using [Alien](https://en.wikipedia.org/wiki/Alien_(file_converter)) and the release is untested.

# Configuration

## Linux

Linux version in this fork includes slight enhancements.

User preference file `prefs.txt` and export plugin `plugin.js` are loaded as per the following priority order:

* image-specific: from current image directory
* user-specific: `$HOME/.petscii`
* system-specific: `/etc/petscii/`
* home directory (legacy option): `$HOME` 
* petscii installation directory (legacy option): `/usr/share/petscii/` 

# Notes to self

This README is just a note for myself to remember what I did to get the dev env up and running.

## Compilation

Compilation of PETSCII is done with Processing 3.

### Pre-requirements

* Processing 3 installed (here, [3.5.4](https://github.com/processing/processing/releases/download/processing-0270-3.5.4/processing-3.5.4-linux64.tgz))
* Java JRE 8 (e.g. `sudo apt install openjdk-8-jre` in Ubuntu)
* Cross-binutils for Win64 (x64) using MinGW-w64 (i.e. `sudo apt-get install binutils-mingw-w64-x86-64`) for patching the Launch4j

### Patching the Launch4j

Processing 3 comes with Launch4j executable wrapper that has ([issues](https://sourceforge.net/p/launch4j/feature-requests/74/)).

Ld and Windres need to be patched with their 64bit equivalents.

After extracting Processing archive, replace the 

```sh
cd processing-3.5.4/modes/java/application/launch4j/bin/windres
rm ld windres
ln -sf /usr/bin/x86_64-w64-mingw32-ld ./ld
ln -sf /usr/bin/x86_64-w64-mingw32-windres ./windres
```

## Import original repo from svn

Brief explanation on how this repo was created from the original subversion location.

### Pre-requirements

* git, svn and git-svn are installed
* authors-file created (here [users.txt](extras/users.txt))

### Import svn repository

```sh
git svn clone --no-metadata --authors-file=users.txt svn://kameli.net/marq/petscii
```

# Added functionality

## PETSCII_CLI

`petscii_cli` is an experimental add-on to run PETSCII editor headless in Linux systems. 

The purpose of this is to enable PETSCII as an integral part of a modern cross-dev CI automation toolchain, so that 
format conversion work and other export routine jobs can be automated.

### Pre-requirements

As PETSCII is based on Processing sketch, it [cannot be run headless natively](https://github.com/processing/processing/wiki/Running-without-a-Display#why-do-i-need-to-do-this). Virtual X framebuffer is needed.

* [Xvfb](https://en.wikipedia.org/wiki/Xvfb) for acting as a X11 display server
* [xdotool](http://manpages.ubuntu.com/manpages/trusty/man1/xdotool.1.html) for running the keyboard commands

### Usage

```
usage: petscii_cli /path/to/petscii /path/to/image.c MACHINE "cmd;cmd;cmd"
```

* `MACHINE` is one of the machines the PETSCII supports
* commands are given as a list of keyboard commands separated with a semicolon, with `xdotool` syntax

### Example

This example loads `/tmp/example.c`, exports it as `.prg` and creates screenshots as `.png` with borders.

```sh
./petscii_cli ../application.linux64/petscii /tmp/example.c C64 "e;P"
```

## Export plugin scripting with Javascript

Experimental Javascript scripting functionality is added to the editor.

On top of the export formats PETSCII supports natively, the purpose of the plugin API is to enable exporting the PETSCII data to (almost) any user-specified output format.


`Ctrl-e` can be used to call `plugin.js` located at the folder of the PETSCII executable.

**TODO**: if `plugin.js` does not exist, a file selector dialog is to be invoked.

It is a design choice to expose only a subset of parameters to the scripting. The API binds the following variables to the user scripts:

| variable        | type        | purpose                                                                                   |
|-----------------|-------------|-------------------------------------------------------------------------------------------|
| `stdout`        | PrintStream | exposes [System.out](https://docs.oracle.com/javase/8/docs/api/java/lang/System.html#out) |
| `outputs`       | ArrayList<Output> | ArrayList of output writers, see below                                              |
| `colors`        | int[]      | color array                                                                                |
| `chars`         | int[]      | character array                                                                            |
| `border`        | int        | border color                                                                               |
| `bg`            | int        | background color                                                                           |
| `filename`      | String     | path and file name of the current image                                                    |
| `fileprefix`    | String     | filename without `.c` suffix                                                               |
| `currentframe`  | int        | index of the current frame                                                                 |
| `machine`       | String     | the target MACHINE in PETSCII editor                                                       |

### Output objects

Output object binds together a file name and a [PrintWriter](https://docs.oracle.com/javase/8/docs/api/java/io/PrintWriter.html) for it.

| variable        | type        |
|-----------------|-------------|
| `pwriter`       | PrintWriter |
| `filename`      | String      |

These output objects are handled through `outputs` ArrayList. Initialising an output file via `outputs` requires minimal boilerplate:

```js
// get the file index
var fp = outputs.add_file("myfile.ext");

// get the corresponding output object's PrintWriter
var outfile = outputs.get(fp).pwriter;
```

Then the PrintWriter is consequently available for use:

```js
// using the printwriter instance
outfile.println("Hello world");
```

Adding multiple output files works just by repeating that pattern. Using `fileprefix` makes file naming quite convenient.

```js
var fpa = outputs.add_file(fileprefix + ".asm");
var asmfile = outputs.get(fpa).pwriter;

var fpt = outputs.add_file(fileprefix + ".txt");
var txtfile = outputs.get(fpt).pwriter;
```

Same file cannot be added as output twice. `add_file` will return the file index of the existing

File index can also be acquired with `get_file`. `-1` is returned if no corresponding file found:

```js
var fp = outputs.get_file("myfile.ext");
if (fp < 0){
    stdout.println("myfile.ext is not an output");
}
```

### Platform-specific scoping

Plugin can be scoped with PETSCII `machine`, e.g. as follows:

```js
if (machine == "C64"){
    // do stuff applicable for C64
}
else if (machine == "VIC20"){
    // do stuff applicable for VIC20
}
// etc.
```

Trying to add same output twice will return the index of the file.

Note that the PrintWriter is flushed and closed after script execution, thus no need to do it explicitly in the script.

### Example

Examples can be found at [/extras/plugins](extras/plugins). 

Copy a script to PETSCII executable's folder as `plugin.js`, try `Ctrl-e` and see what happens.

