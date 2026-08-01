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

## macOS

The **.dmg** is not signed with a Developer ID and not notarized, so Gatekeeper refuses it on first launch. Open it anyway:

1. Open the **.dmg** and drag **petscii** to **Applications**.
2. Launch it once. macOS refuses, with either *"petscii is damaged and can't be opened"* or *"cannot be opened because the developer cannot be verified"*.
3. Open **System Settings → Privacy & Security**, scroll to the bottom and click **Open Anyway** next to the message about petscii. Confirm at the password prompt.

The right-click → **Open** trick works on older macOS, but no longer on Sequoia and later.

If **Open Anyway** never appears, strip the quarantine flag by hand and launch again:

```sh
xattr -dr com.apple.quarantine /Applications/petscii.app
```

Pick the .dmg matching your CPU: Apple silicon or Intel. The Intel build runs on Apple silicon under Rosetta, but the native one is better.

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

Note: Release candidates with equal version number cannot be automatically upgraded. Uninstall the old one first manually.

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

## Custom charsets in .c files

Saving keeps the charset each frame is drawn with, so a picture with a charset of its own survives a save and load. Frames may differ: a `.c` can hold one charset per frame. Identical charsets are stored once and shared, and frames using the machine's own font store nothing at all, so a picture that never left the ROM charset saves exactly as it always did.

Everything past the frames is written as C, not as comments. This is format 2:

```c
unsigned char frame0000[]={ ... };
unsigned char frame0001[]={ ... };
static const int version=2;
static const unsigned char charset0000[]={// 256 characters, 8 bytes each
0,0,0,0,0,0,0,0,
...
};
static const int fonts[]={0,-1}; // charset per frame, -1 = the machine's own
static const int meta[]={40,25,1}; // width height case, 1 = upper
// META: 40 25 C64 upper
```

| Declaration | Holds |
|-------------|-------|
| `version` | The format version, a running integer. Files without it are format 1: frames and the `// META:` comment, nothing else. |
| `charsetNNNN` | One charset, 256 characters of 8 bytes, bit 7 leftmost. Only written when a frame needs it. |
| `fonts` | The charset each frame is drawn with, in frame order. `-1` is the machine's own font. Only written when there are charsets. |
| `meta` | Width, height and case, `1` being upper. The machine is read from the `// META:` comment, which is written for older versions anyway. |

The file still compiles with cc65, which only warns about the declarations being unused.

The `static const` is deliberate. PETSCII stops reading frames at the first line that does not begin with `unsigned char`, so a version older than format 2 loads the picture, draws it with the ROM charset and ignores the rest of the file. Such a version reads the metadata from the `// META:` comment only, which is why that line is still written, and still written last. It cannot write any of the new data back, though: re-saving in an old version drops the charsets.

Loading a charset `.png`, tracing an image or toggling **Case** applies to the whole picture — every frame — as before. Only a file that carries per-frame charsets gets them, and switching frames then switches the characters with it.

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
