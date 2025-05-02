#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

unzip pacfix
mv libxml2-db07dd61 pacfix

cp HTMLparser.pacfix.c pacfix/HTMLparser.c
cp pacfix/dict.c dict.orig.c
cp pacfix/HTMLparser.c HTMLparser.orig.c


pushd pacfix
  ./autogen.sh
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
  # cat make.log | grep parser.c
  gcc -E -DHAVE_CONFIG_H -I. -I./include -I./include -D_REENTRANT -fsanitize=address -g -MT dict.lo -MD -MP -MF .deps/dict.Tpo -c dict.c > dict.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c dict.c.i
  mv tmp.c dict.c.i.c
  cp dict.c.i.c dict.c
  gcc -E -DHAVE_CONFIG_H -I. -I./include -I./include -D_REENTRANT -fsanitize=address -g -MT HTMLparser.lo -MD -MP -MF .deps/HTMLparser.Tpo -c HTMLparser.c > HTMLparser.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c HTMLparser.c.i
  mv tmp.c HTMLparser.c.i.c
  cp HTMLparser.c.i.c HTMLparser.c
popd
/home/yuntong/pacfix/main.exe -synth_only -debug -nouniq -seed -epsilon 0.0 -cycle 60 -timeout 300 ./config
