#!/usr/bin/env bash

set -eo pipefail

if command -v magick &> /dev/null; then
    _IMAGEMAGICK=magick
elif command -v convert &> /dev/null; then
    _IMAGEMAGICK=convert
else
    echo "ERROR: ImageMagick not found. Install it first"
    exit 1
fi

check_dimensions(){
    $_IMAGEMAGICK "$1" -format "(%w,%h)" info:
}

to_charset(){
    $_IMAGEMAGICK "$1" -crop 128x8 +repage +append "$2"
}
from_charset(){
    $_IMAGEMAGICK "$1" -crop 128x8 +repage -append "$2"
}

usage(){
    echo "Usage: $0 [options] <input_file>"
    echo ""
    echo "Convert 128x128 pixels image to PETSCII editor charset or vice versa"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message and exit"
    echo "  -o, --output    Output file"
    echo ""
    echo "Examples: 
    echo "  Convert 128x128 pixels .png to charset or vice versa: 
    echo "  $0 input.png -o=output.png"
    echo ""
    echo "  Print dimensions of the image in (x,y) format:"
    echo "  $0 input.png"
    echo ""
}
# argument parser logic for each argument
for arg in "$@"; do
    case "$arg" in
        "-h"|"--help") 
            usage
            exit 0
            ;;
        "-o="*|"--output="*)
            _OUTPUT="${arg#*=}"
            ;;
        *) 
            [ -z "$_INPUT" ] && _INPUT="$arg"
        ;;
    esac
done

if [ ! -f "$_INPUT" ]; then
    echo "ERROR: Input file '$_INPUT' not found"
    exit 1
fi

_DIM=$(check_dimensions "$_INPUT")

# if output is not provided, print the dimensions and exit
if [ -z "$_OUTPUT" ]; then
    echo "$_DIM"
    exit 0
elif [ $_DIM == "(128,128)" ]; then
    echo "Converting (128x128) image '$_INPUT' to PETSCII editor charset '$_OUTPUT'"
    to_charset "$_INPUT" "$_OUTPUT"
elif [ $_DIM == "(2048,8)" ]; then
    echo "Converting PETSCII editor charset '$_INPUT' to (128x128) image '$_OUTPUT' "
    from_charset "$_INPUT" "$_OUTPUT"
else
    echo "ERROR: Unsupported image dimensions $_DIM"
    exit 1
fi
