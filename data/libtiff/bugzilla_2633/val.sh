#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

unzip source.zip
mv libtiff-f3069a5adc65b67b90222441e3711b236a16e624 pacfix


pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
  pushd tools
    gcc -E -DHAVE_CONFIG_H -I. -I../libtiff  -I../libtiff   -static -fsanitize=address -fsanitize=undefined -g -MT tiff2ps.o -MD -MP -MF .deps/tiff2ps.Tpo -c tiff2ps.c > tiff2ps.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c tiff2ps.c.i
    mv tmp.c tiff2ps.c.i.c
    cp tiff2ps.c.i.c tiff2ps.c
  popd
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -debug -nouniq -seed -epsilon 0.0 -cycle 60 -timeout 300 ./config

