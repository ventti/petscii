#!/bin/sh

#
# .deb (and, via alien, .rpm) package creator
#
# usage: extras/package.sh <version> <deb_revision> [source_dir]
#
#   source_dir  an unpacked Linux export containing petscii, lib/ and data/
#               (default: build/linux-amd64, i.e. ./build.sh export linux-amd64)
#
# Packages land in dist/. Requires dpkg-deb, and alien for the .rpm step, so this
# only runs on Linux; see .github/workflows/release-packages.yaml, which builds
# them from the linux-amd64 archive attached to a release.
#
REL_DIR="/tmp/petscii$(date +"%s%N")temp"
PROJECT=petscii
TAG=${1}
REV=${2}

# Anchor everything at the repo root so the script works from any directory
EXTRAS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$EXTRAS_DIR/.." && pwd)

SRC=${3:-$ROOT_DIR/build/linux-amd64}
OUT_DIR=$ROOT_DIR/dist

if [ -z "${REV}" ]; then
    echo "usage: $0 version deb_revision [source_dir]"
    exit 1
fi

command -v dpkg-deb >/dev/null 2>&1 || { echo "$0: dpkg-deb not found (Linux only)" >&2; exit 1; }

[ -f "${SRC}/petscii" ] || { echo "$0: no petscii launcher in ${SRC}" >&2; exit 1; }

# alien needs root to keep file ownership; skip sudo when already root
SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"

create_release(){
    DEB_DIR=$REL_DIR/${PROJECT}_${TAG}-${REV}_${ARCH}
    rm -rf ${DEB_DIR}
    mkdir -p ${DEB_DIR}/DEBIAN
    CONTROL=${DEB_DIR}/DEBIAN/control
    echo "Package: petscii" > ${CONTROL}
    echo "Version: ${TAG}" >> ${CONTROL}
    echo "Architecture: ${ARCH}" >> ${CONTROL}
    echo "Maintainer: Teppo Keitaanniemi <tep-po@iki.fi>" >> ${CONTROL}
    # Processing's core.jar is built for Java 17, and the release binaries no
    # longer embed a runtime, so a JRE of at least 17 is a hard requirement.
    echo "Depends: default-jre (>= 2:1.17) | java17-runtime" >> ${CONTROL}
    echo "Recommends: xvfb, xdotool" >> ${CONTROL}
    echo "Homepage: https://github.com/ventti/petscii/" >> ${CONTROL}
    echo "Description: Marq's PETSCII editor (Vent's fork)." >> ${CONTROL}
    echo " Petscii is a crossplatform PETSCII editor. It lets you create character-based screens and animations for the Commodore 64, VIC-20, PET and Plus/4 computers." >> ${CONTROL}

    # app
    mkdir -p ${DEB_DIR}/usr/share/petscii/
    cp "${SRC}/petscii" ${DEB_DIR}/usr/share/petscii/
    cp -r "${SRC}/data" ${DEB_DIR}/usr/share/petscii/
    cp -r "${SRC}/lib" ${DEB_DIR}/usr/share/petscii/
    mkdir -p ${DEB_DIR}/usr/share/petscii/plugins/
    cp "${EXTRAS_DIR}"/plugins/* ${DEB_DIR}/usr/share/petscii/plugins/

    # icon
    mkdir -p ${DEB_DIR}/usr/share/pixmaps/
    cp "${EXTRAS_DIR}/petscii.xpm" ${DEB_DIR}/usr/share/pixmaps/

    # shortcut
    mkdir -p ${DEB_DIR}/usr/share/applications/
    cp "${EXTRAS_DIR}/petscii.desktop" ${DEB_DIR}/usr/share/applications

    # global prefs
    mkdir -p ${DEB_DIR}/etc/petscii/
    cp "${ROOT_DIR}/prefs.txt" ${DEB_DIR}/etc/petscii/prefs.txt

    mkdir -p ${DEB_DIR}/usr/bin/
    ln -fs ../share/petscii/petscii ${DEB_DIR}/usr/bin/petscii

    mkdir -p "${OUT_DIR}"
    dpkg-deb --build --root-owner-group ${DEB_DIR}
    mv ${REL_DIR}/${PROJECT}_${TAG}-${REV}_${ARCH}.deb "${OUT_DIR}/"

    # .rpm is converted from the .deb; -k keeps the original version number
    ( cd "${OUT_DIR}" && ${SUDO} alien -k --to-rpm ${PROJECT}_${TAG}-${REV}_${ARCH}.deb )

    # cleanup
    rm -rf ${REL_DIR}

    echo ">> Packages in ${OUT_DIR}:"
    ls -1 "${OUT_DIR}"/*.deb "${OUT_DIR}"/*.rpm 2>/dev/null
}

ARCH=amd64
create_release
