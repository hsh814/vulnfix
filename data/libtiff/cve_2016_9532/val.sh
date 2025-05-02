#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

unzip source.zip
mv libtiff-d651abc097d91fac57f33b5f9447d0a9183f58e7 pacfix
cp tiffcrop.pacfix2.c ./pacfix/tools/tiffcrop.c


pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j10
  pushd tools
    gcc -E -DHAVE_CONFIG_H -I. -I../libtiff  -I../libtiff   -static -fsanitize=address -g -MT tiffcrop.o -MD -MP -MF .deps/tiffcrop.Tpo -c tiffcrop.c > tiffcrop.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c tiffcrop.c.i
    mv tmp.c tiffcrop.c.i.c
    cp tiffcrop.c.i.c tiffcrop.c
  popd
popd
/home/yuntong/pacfix/main.exe -synth_only -debug -nouniq -cycle 60 -timeout 300 ./config
