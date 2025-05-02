#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

unzip pacfix
mv libxml2-cbb271655cadeb8dbb258a64701d9a3a0c4835b4 pacfix

cp parser.pacfix2.c ./pacfix/parser.c
cp pacfix/parser.c parser.orig.c


pushd pacfix
  ./autogen.sh --disable-silent-rules
  make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" LDFLAGS="-fsanitize=address" -j10
  # cat make.log | grep parser.c
  gcc -E -DHAVE_CONFIG_H -I. -I./include -I./include -D_REENTRANT -fsanitize=address -g -MT parser.lo -MD -MP -MF .deps/parser.Tpo -c parser.c > parser.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c parser.c.i
  mv tmp.c parser.c.i.c
  cp parser.c.i.c parser.c
popd
/home/yuntong/pacfix/main.exe -synth_only -debug -nouniq -seed -epsilon 0.0 -cycle 60 -timeout 300 ./config
