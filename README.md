Marq's PETSCII editor (Vent's fork)
===================================

Fork of [Marq's PETSCII editor](http://www.kameli.net/marq/?page_id=2717), the C64 cross-platform PETSCII art editor.

# Installation

Installers are on the [latest release page](https://github.com/ventti/petscii/releases/latest):

| Platform | Asset |
|----------|-------|
| macOS | `.dmg`, Apple silicon or Intel |
| Windows | `.msi`, 64-bit Intel/AMD |
| Linux | `.deb` / `.rpm`, 64-bit Intel/AMD or ARM |
| Linux, 32-bit ARM | `.tar.gz` |

32-bit ARM Linux `.tar.gz` ships without a runtime and needs Java 17 or later.

## Linux

Depending on your distribution,

```sh
sudo dpkg -i petscii-0.3.1-linux-amd64.deb
```
or

```sh
sudo dnf install petscii-0.3.1-linux-amd64.rpm
```

Installs to `/opt/petscii` with a desktop entry. The .rpm is untested.

## Windows

Run the **.msi**. 

Note: Release candidates all share one installer version, so Windows refuses to replace one with another — uninstall the old one first.

# Added functionality

See the [CHANGELOG.md](CHANGELOG.md) for the detailed list of changes per release.

## Configuration

On Linux, `prefs.txt` and `plugin.js` are searched in this order:

* current image directory
* `$HOME/.petscii`
* `/etc/petscii/`
* `$HOME` (legacy)
* `/usr/share/petscii/` (legacy)

## petscii_cli

Experimental headless runner, for automating conversions and exports in a Linux CI. Processing [cannot run headless natively](https://github.com/processing/processing/wiki/Running-without-a-Display#why-do-i-need-to-do-this), so it needs [Xvfb](https://en.wikipedia.org/wiki/Xvfb) and [xdotool](http://manpages.ubuntu.com/manpages/trusty/man1/xdotool.1.html).

```
petscii_cli /path/to/petscii /path/to/image.c MACHINE "cmd;cmd;cmd"
```

`MACHINE` is any machine PETSCII supports. Commands are `xdotool` keystrokes, separated by semicolons. This loads `/tmp/example.c`, exports a `.prg` and a bordered `.png`:

```sh
./petscii_cli /opt/petscii/bin/petscii /tmp/example.c C64 "e;P"
```

## Export plugin scripting with Javascript

Experimental. `Ctrl-e` runs `plugin.js`, found via the search order above, so each image folder can carry its own exporter. One plugin at a time — custom export code is usually specific to a single demo or game, and this keeps a zoo of exporters out of the editor.

**TODO**: invoke a file selector when `plugin.js` is missing.

Scripts get a deliberately small API:

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

An `Output` pairs a file name with a [PrintWriter](https://docs.oracle.com/javase/8/docs/api/java/io/PrintWriter.html), and they are handled through the `outputs` list:

```js
var fp = outputs.add_file(fileprefix + ".asm");   // file index
var asmfile = outputs.get(fp).pwriter;
asmfile.println("Hello world");
```

Repeat for more files. Adding the same file twice returns the existing index; `outputs.get_file(name)` looks one up, returning `-1` if absent. Writers are flushed and closed after the script runs.

### Platform-specific scoping

```js
if (machine == "C64"){
    // do stuff applicable for C64
}
else if (machine == "VIC20"){
    // do stuff applicable for VIC20
}
```

### Example

Examples are in [/extras/plugins](extras/plugins). Copy one next to the executable as `plugin.js`, press `Ctrl-e` and see what happens.

## Charset conversion script

[/extras/charset_conv.sh](extras/charset_conv.sh) converts a 128x128 image to a PETSCII charset and back.

```
Usage: ./extras/charset_conv.sh [options] <input_file>

Options:
  -h, --help      Show this help message and exit
  -o, --output    Output file

  ./extras/charset_conv.sh input.png -o=output.png   # convert
  ./extras/charset_conv.sh input.png                 # print dimensions as (x,y)
```
