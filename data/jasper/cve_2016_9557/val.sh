#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

unzip source.zip -d evocatio-tmp
mv evocatio-tmp/source pacfix
rm -r evocatio-tmp

pushd pacfix
  autoreconf -i
popd

pushd pacfix
  ./configure 
  make CFLAGS="-static -g -fsanitize=address -fsanitize=undefined" CXXFLAGS="-static -g -fsanitize=address -fsanitize=undefined" LDFLAGS="-fsanitize=address -fsanitize=undefined" -j 10
  pushd src/libjasper/base
    gcc -E -DHAVE_CONFIG_H -I. -I../../../src/libjasper/include/jasper -I../../../src/libjasper/include -I../../../src/libjasper/include -g -fsanitize=address -fsanitize=undefined -MT jas_image.lo -MD -MP -MF .deps/jas_image.Tpo -c jas_image.c -lm -s > jas_image.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c jas_image.c.i
    mv tmp.c jas_image.c.i.c 
    cp jas_image.c.i.c jas_image.c
  popd
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -debug -cycle 60 -timeout 300 ./config
