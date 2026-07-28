#!/bin/sh
#
# build.sh - compile / export the PETSCII sketch from the console
#
# Wraps Processing's command-line "Commander" (processing.mode.java.Commander)
# using a locally installed Processing app, since the stock `processing-java`
# launcher is often broken (stale AppTranslocation path).
#
# Output goes to ./build (git-ignored). The repo itself is never touched.
#
# Usage:
#   ./build.sh                       Export every variant (same as: export all)
#   ./build.sh build                 Compile the sketch to build/classes
#   ./build.sh export [variant ...]  Export standalone app(s) to build/<variant>
#   ./build.sh export all            Export every known variant
#   ./build.sh clean                 Remove the build directory
#
# Variants (Processing 4 naming):
#   macos-x86_64   macOS (Intel 64-bit)
#   macos-aarch64  macOS (Apple Silicon)
#   windows-amd64  Windows (Intel 64-bit)
#   linux-amd64    Linux (Intel 64-bit)
#   linux-arm      Linux (Raspberry Pi 32-bit)
#   linux-aarch64  Linux (Raspberry Pi 64-bit)
#
# Override the Processing app location with PROCESSING_APP=/path/to/Processing.app
# Export without a bundled Java runtime with EMBED_JAVA=0 (much smaller output,
# but the target machine must have its own Java installed).
#
# macOS note: Processing embeds its own bundled JDK, so an Intel Processing build
# produces a broken macos-aarch64 app (arm64 launcher + x86_64 JRE => "Unable to
# load Java Runtime Environment"). This script auto-detects the mismatch and, if a
# matching-arch JDK 17 is installed, swaps it in and re-signs (ad-hoc) the app.
#
set -eu

SKETCH_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SKETCH_DIR/build"

ALL_VARIANTS="macos-x86_64 macos-aarch64 windows-amd64 linux-amd64 linux-arm linux-aarch64"

die() { echo "build.sh: $*" >&2; exit 1; }

# --- locate a Processing (4.x) installation -------------------------------
# Resolve the directory holding Processing's jars: "Contents/Java" inside a macOS
# .app, or the root of an unpacked Linux release (processing-4.x, which uses the
# same core/ and modes/ layout).
find_jdir() {
    if [ -n "${PROCESSING_APP:-}" ]; then
        [ -d "$PROCESSING_APP" ] || die "PROCESSING_APP not found: $PROCESSING_APP"
        if [ -d "$PROCESSING_APP/Contents/Java" ]; then
            printf '%s\n' "$PROCESSING_APP/Contents/Java"
        elif [ -d "$PROCESSING_APP/core/library" ]; then
            printf '%s\n' "$PROCESSING_APP"
        else
            die "No Processing jars under PROCESSING_APP: $PROCESSING_APP"
        fi
        return
    fi
    # Prefer a versioned Processing 4.x app, then any Processing app.
    for pat in "/Applications/Processing-4"*.app "/Applications/Processing.app" \
               "$HOME/Applications/Processing-4"*.app "$HOME/Applications/Processing.app"; do
        for app in $pat; do
            [ -d "$app/Contents/Java" ] && { printf '%s\n' "$app/Contents/Java"; return; }
        done
    done
    # An unpacked Linux release, e.g. from processing-4.x-linux-x64.tgz
    for dir in "$SKETCH_DIR/processing-4"* "$HOME/processing-4"* /opt/processing-4*; do
        [ -d "$dir/core/library" ] && { printf '%s\n' "$dir"; return; }
    done
    die "No Processing install found. Set PROCESSING_APP=/path/to/Processing.app or to an unpacked processing-4.x"
}

JDIR="$(find_jdir)"

# Processing's own bundled JDK: PlugIns on macOS, java/ in a Linux release
JAVA=""
for j in "$JDIR/../PlugIns"/*/Contents/Home/bin/java "$JDIR/java/bin/java"; do
    [ -x "$j" ] && { JAVA="$j"; break; }
done
[ -n "$JAVA" ] || JAVA="$(command -v java || true)"
[ -n "$JAVA" ] || die "No java runtime found in $JDIR or on PATH"

# --- assemble the classpath from the app's jars ---------------------------
CP=""
add_jars() {
    for jar in "$1"/*.jar; do
        [ -f "$jar" ] || continue
        CP="${CP:+$CP:}$jar"
    done
}
add_jars "$JDIR"
add_jars "$JDIR/core/library"
add_jars "$JDIR/modes/java/mode"
[ -n "$CP" ] || die "Could not assemble Processing classpath from $JDIR"

# --- run the Commander ----------------------------------------------------
# Note: --build/--export must be the FINAL argument; anything after them is
# passed through to the sketch, not to Processing.
commander() {
    ( cd "$JDIR" && "$JAVA" -Djna.nosys=true -Djava.awt.headless=true \
        -cp "$CP" processing.mode.java.Commander "$@" )
}

do_build() {
    local out="$BUILD_DIR/classes"
    rm -rf "$out"
    echo ">> Compiling sketch -> $out"
    commander --sketch="$SKETCH_DIR" --output="$out" --force --build
    echo ">> Done. $(find "$out" -name '*.class' | wc -l | tr -d ' ') class files."
}

do_export() {
    local variants="$*"
    [ -n "$variants" ] || variants="$(host_variant)"
    [ "$variants" = "all" ] && variants="$ALL_VARIANTS"

    # EMBED_JAVA=0 exports without a bundled runtime (Commander's --no-java):
    # ~140 MB smaller per variant, but the machine running it needs its own Java.
    local nojava=""
    [ "${EMBED_JAVA:-1}" = "0" ] && nojava="--no-java"

    for v in $variants; do
        local out="$BUILD_DIR/$v"
        rm -rf "$out"
        echo ">> Exporting $v -> $out${nojava:+ (no embedded JRE)}"
        commander --sketch="$SKETCH_DIR" --output="$out" --force --variant="$v" $nojava --export
        # Only an embedded runtime can be arch-mismatched; there is nothing to fix
        # when Java was left out.
        [ -n "$nojava" ] || fix_macos_jre "$v" "$out"
    done
    echo ">> Done."
}

# Processing embeds *its own* bundled JDK regardless of target arch. An Intel
# Processing build therefore embeds an x86_64 JRE even into a macos-aarch64
# export, producing an arm64 launcher + x86_64 JRE mismatch that fails at launch
# with "Unable to load Java Runtime Environment". If the host has a matching-arch
# JDK 17, swap it in and re-sign so the exported app is internally consistent.
fix_macos_jre() {
    local variant="$1" out="$2"
    [ "$(uname -s)" = "Darwin" ] || return 0
    case "$variant" in
        macos-x86_64)  local want=x86_64 ;;
        macos-aarch64) local want=arm64 ;;
        *) return 0 ;;
    esac

    local app home
    app="$(find "$out" -maxdepth 1 -name '*.app' | head -1)"
    [ -n "$app" ] || return 0
    home="$(find "$app/Contents/PlugIns" -maxdepth 3 -path '*/Contents/Home' -type d | head -1)"
    [ -n "$home" ] || return 0

    local have
    have="$(file "$home/bin/java" 2>/dev/null | grep -oE 'x86_64|arm64' | head -1)"
    [ "$have" = "$want" ] && return 0   # already correct

    echo "   ! embedded JRE is $have but $variant needs $want; looking for a matching JDK 17"
    local jdk
    jdk="$(/usr/libexec/java_home -a "$want" -v 17 2>/dev/null || true)"
    if [ -z "$jdk" ] || [ ! -x "$jdk/bin/java" ]; then
        echo "   ! no $want JDK 17 found (try: /usr/libexec/java_home -a $want -v 17)."
        echo "   ! app will NOT run natively. Install an Apple Silicon Processing build" >&2
        echo "   ! or a $want JDK 17, or use the macos-x86_64 variant under Rosetta." >&2
        return 0
    fi

    echo "   > swapping in $want JDK: $jdk"
    rm -rf "$home"
    mkdir -p "$home"
    cp -R "$jdk"/ "$home"/
    codesign --remove-signature "$app" 2>/dev/null || true
    codesign --force --deep -s - "$app" >/dev/null 2>&1 || true
    echo "   > re-signed; embedded JRE now $(file "$home/bin/java" | grep -oE 'x86_64|arm64' | head -1)"
}

host_variant() {
    case "$(uname -s)" in
        Darwin) [ "$(uname -m)" = "arm64" ] && echo macos-aarch64 || echo macos-x86_64 ;;
        Linux)  case "$(uname -m)" in
                    aarch64) echo linux-aarch64 ;;
                    arm*)    echo linux-arm ;;
                    *)       echo linux-amd64 ;;
                esac ;;
        *)      echo windows-amd64 ;;
    esac
}

# No arguments => export every variant.
[ $# -eq 0 ] && { do_export all; exit 0; }

cmd="$1"
case "$cmd" in
    build)  do_build ;;
    export) shift; do_export "$@" ;;
    clean)  rm -rf "$BUILD_DIR"; echo ">> Removed $BUILD_DIR" ;;
    -h|--help|help) awk 'NR>1 && /^#/{sub(/^# ?/,"");print;next} NR>1{exit}' "$0" ;;
    *)      die "Unknown command '$cmd' (try: build | export | clean | help)" ;;
esac
