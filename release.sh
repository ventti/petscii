#!/bin/sh

rm *.c *.prg *.s *.bas *.o *.png *.gif
rm -r application.*/source
mv application.linux32 linux32
mv application.linux64 linux64
mv application.windows32 windows32
mv application.windows64 windows64
mv application.macosx mac

cp prefs.txt linux32
cp prefs.txt linux64
cp prefs-msdos.txt windows32/prefs.txt
cp prefs-msdos.txt windows64/prefs.txt
cp prefs.txt mac

cd ..
rm petscii.zip

rm -rf petscii_release
mkdir petscii_release
mkdir petscii_release/src
mkdir petscii_release/src/petscii

cp -r petscii/*.pde petscii_release/src/petscii
cp -r petscii/data petscii_release/src/petscii
cp petscii/*.txt petscii_release
cp -r petscii/examples petscii_release
cp -r petscii/linux32 petscii/linux64 petscii/mac petscii/windows32 \
 petscii/windows64 petscii_release

rm petscii_release/prefs*

echo "Version date:" >>petscii_release/README.txt
date >>petscii_release/README.txt
echo >>petscii_release/README.txt

zip -r petscii.zip petscii_release
scp petscii.zip marq@kameli.net:public_html/kode

cd petscii
rm -r linux32 linux64 windows32 windows64 mac
