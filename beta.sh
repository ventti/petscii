#!/bin/sh

rm -r application.* *.c *.bas *.prg *.s *.o *.png *.gif *.d64
cd ..
rm petscii-beta.zip

zip -r petscii-beta.zip petscii
scp petscii-beta.zip kameli.net:public_html/kode
