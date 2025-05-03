#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)
git clone https://gitlab.gnome.org/GNOME/libxml2.git
mv libxml2 pacfix
pushd pacfix
  git checkout 4ea74a44
popd

pushd pacfix
  ./autogen.sh --disable-silent-rules
  make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" LDFLAGS="-fsanitize=address" -j10 > make.log
  # cat make.log | grep parser.c
  gcc -E -DHAVE_CONFIG_H -I. -I. -I./include -I./include -D_REENTRANT -fsanitize=address -g -MT parser.lo -MD -MP -MF .deps/parser.Tpo -c parser.c > parser.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c parser.c.i
  mv tmp.c parser.c.i.c
  cp parser.c.i.c parser.c
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -debug -nouniq -seed -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 120 ./config
