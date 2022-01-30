#!/bin/sh
set -e
cd ..
REPO_DIR=${PWD}
VERSION=$(git describe --tags --always --dirty)
VERSION_DATE=$(git show -s --format=%ci)

REL_DIR="/tmp/petscii_${VERSION}_temp"
ZIP_DIR=${REL_DIR}/petscii_release

if [[ "${VERSION}" == *"dirty"* ]]; then
    echo "ERROR: Refusing to make a dirty release"
    git status
#    exit 1
fi

rm -f *.c *.prg *.s *.bas *.o *.png *.gif
rm -rf application.*/source
rm -rf linux32 linux64 windows32 windows64 mac
mv application.linux32 linux32
mv application.linux64 linux64
mv application.windows32 windows32
mv application.windows64 windows64
mv application.macosx mac

rm -rf application.linux-arm*

cp prefs.txt linux32
cp prefs.txt linux64
cp prefs-msdos.txt windows32/prefs.txt
cp prefs-msdos.txt windows64/prefs.txt
cp prefs.txt mac

rm -rf ${REL_DIR}
mkdir -p ${ZIP_DIR}/src/petscii

cp -r ./*.pde ${ZIP_DIR}/src/petscii
cp -r ./data ${ZIP_DIR}/src/petscii
cp ./*.txt ${ZIP_DIR}
cp ./*.md ${ZIP_DIR}
cp -r ./examples ${ZIP_DIR}
cp -r ./linux32 ./linux64 ./mac ./windows32 \
 ./windows64 ${ZIP_DIR}

cp -r ./extras/plugins ${ZIP_DIR}/
cp -r ./extras/petscii_cli ${ZIP_DIR}/linux64/
cp -r ./extras/petscii_cli ${ZIP_DIR}/linux32/

rm ${ZIP_DIR}/prefs*

echo "Version: ${VERSION} (${VERSION_DATE})" >${ZIP_DIR}/VERSION.txt
echo "">>${ZIP_DIR}/VERSION.txt

cd ${REL_DIR}
zip -r petscii.zip petscii_release
# scp petscii.zip marq@kameli.net:public_html/kode

cd ${REPO_DIR}
rm -rf linux32 linux64 windows32 windows64 mac

mv ${REL_DIR}/petscii.zip ${PWD}
rm -rf ${REL_DIR}

echo "***********************************************"
ls -la ${PWD}/petscii.zip
echo "Version: ${VERSION} (${VERSION_DATE}) is ready!"
echo "***********************************************"
