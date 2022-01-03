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
* authors-file created (here [users.txt](users.txt))

### Import svn repository

```sh
git svn clone --no-metadata --authors-file=users.txt svn://kameli.net/marq/petscii
```

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
