#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

unzip source.zip
mv libming-cc6a386555a2fb13589f92473dd65b289a38d02d pacfix


pushd pacfix
  ./autogen.sh
  ./configure --disable-freetype
  make CFLAGS="-static -fcommon -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g"
  # cat make.log | grep jdmarker.c
  pushd util
    gcc -E -DHAVE_CONFIG_H -I. -I..-Wall -fsanitize=address -fsanitize=undefined -g -MT listmp3.lo -MD -MP -MF .deps/listmp3.Tpo -c listmp3.c > listmp3.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c listmp3.c.i
    mv tmp.c listmp3.c.i.c
    cp listmp3.c.i.c listmp3.c
  popd
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -debug -epsilon 0.0 -cycle 60 -timeout 300 -seed -nouniq ./config
