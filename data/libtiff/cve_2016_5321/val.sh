#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)
git clone https://github.com/vadz/libtiff.git pacfix
pushd pacfix
  git checkout 0ba5d88
popd

pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
  pushd tools
    gcc -E -DHAVE_CONFIG_H -I. -I../libtiff  -I../libtiff   -static -fsanitize=address -fsanitize=undefined -g -MT tiffcrop.o -MD -MP -MF .deps/tiffcrop.Tpo -c tiffcrop.c > tiffcrop.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c tiffcrop.c.i
    mv tmp.c tiffcrop.c.i.c
    cp tiffcrop.c.i.c tiffcrop.c
  popd
popd
/home/yuntong/pacfix/main.exe -synth_only -nouniq -seed -epsilon 0.0 -debug -cycle 60 -timeout 300 ./config
