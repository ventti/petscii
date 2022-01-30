#!/bin/sh

#
# deb package creator
#
REL_DIR="/tmp/petscii$(date +"%s%N")temp"
PROJECT=petscii
TAG=${1}
REV=${2}
CWD=$PWD

if [ -z "${REV}" ]; then
    echo "usage: $0 version deb_revision"
    exit 1
fi

create_release(){
    DEB_DIR=$REL_DIR/${PROJECT}_${TAG}-${REV}_${ARCH}
    rm -rf ${DEB_DIR}
    mkdir -p ${DEB_DIR}/DEBIAN
    CONTROL=${DEB_DIR}/DEBIAN/control
    echo "Package: petscii" > ${CONTROL}
    echo "Version: ${TAG}" >> ${CONTROL}
    echo "Architecture: ${ARCH}" >> ${CONTROL}
    echo "Maintainer: Teppo Keitaanniemi <tep-po@iki.fi>" >> ${CONTROL}
    echo "Depends: openjdk-8-jre|openjdk-8-jdk, xvfb, xdotool" >> ${CONTROL}
    echo "Homepage: https://github.com/ventti/petscii/" >> ${CONTROL}
    echo "Description: Marq's PETSCII editor (Vent's fork)." >> ${CONTROL}
    echo " Petscii is a crossplatform PETSCII editor. It lets you create character-based screens and animations for the Commodore 64, VIC-20, PET and Plus/4 computers." >> ${CONTROL}

    # app
    mkdir -p ${DEB_DIR}/usr/share/petscii/
    cp ../application.${ARCH_VER}/petscii ${DEB_DIR}/usr/share/petscii/
    cp -r ../application.${ARCH_VER}/data ${DEB_DIR}/usr/share/petscii/
    cp -r ../application.${ARCH_VER}/lib ${DEB_DIR}/usr/share/petscii/
    mkdir -p ${DEB_DIR}/usr/share/petscii/plugins/
    cp ./plugins/* ${DEB_DIR}/usr/share/petscii/plugins/

    # icon
    mkdir -p ${DEB_DIR}/usr/share/pixmaps/
    cp petscii.xpm ${DEB_DIR}/usr/share/pixmaps/

    # shortcut
    mkdir -p ${DEB_DIR}/usr/share/applications/
    cp petscii.desktop ${DEB_DIR}/usr/share/applications

    # global prefs
    mkdir -p ${DEB_DIR}/etc/petscii/
    cp ../prefs.txt ${DEB_DIR}/etc/petscii/prefs.txt

    mkdir -p ${DEB_DIR}/usr/bin/
    cd ${DEB_DIR}/usr/bin
    ln -fs ../share/petscii/petscii ./petscii

    cd ${CWD}

    dpkg-deb --build --root-owner-group ${DEB_DIR}
    mv ${REL_DIR}/${PROJECT}_${TAG}-${REV}_${ARCH}.deb ./
    sudo alien -k --to-rpm ${PROJECT}_${TAG}-${REV}_${ARCH}.deb

    # cleanup
    rm -rf ${REL_DIR}
}

ARCH=amd64
ARCH_VER=linux64
create_release
