#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)
git clone https://gitlab.gnome.org/GNOME/libxml2.git pacfix
pushd pacfix
  git checkout 362b3229
popd

pushd pacfix
  ./autogen.sh --disable-silent-rules
  make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" LDFLAGS="-fsanitize=address" LDFLAGS="-fsanitize=address" -j10 > make.log
  # cat make.log | grep valid.c
  gcc -E -DHAVE_CONFIG_H -I. -I. -I./include -I./include -D_REENTRANT -fsanitize=address -g -MT valid.lo -MD -MP -MF .deps/valid.Tpo -c valid.c > valid.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c valid.c.i
  mv tmp.c valid.c.i.c
  cp valid.c.i.c valid.c
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -nouniq -seed -epsilon 0.0 -debug -lvfile ./live_variables -cycle 20 -timeout 30 ./config