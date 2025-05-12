#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)
git clone https://github.com/gdraheim/zziplib.git pacfix
pushd pacfix
  git checkout 33d6e9c
  pushd docs
    wget https://github.com/LuaDist/libzzip/raw/master/docs/zziplib-manpages.tar
  popd
popd

pushd pacfix
  ../source/configure
  make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j10 > make.log
  # cat make.log | grep memdisk.c
  pushd zzip
    gcc -E -DHAVE_CONFIG_H -I.. -I../../source -static -fsanitize=address -g -MT memdisk.lo -MD -MP -MF .deps/memdisk.Tpo -c memdisk.c > memdisk.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c memdisk.c.i
    mv tmp.c memdisk.c.i.c
    cp memdisk.c.i.c memdisk.c
  popd
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -nouniq -seed -epsilon 0.0 -debug -cycle 600 -timeout 1800 ./config 
