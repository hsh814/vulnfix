#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

git clone https://github.com/gdraheim/zziplib.git pacfix
pushd pacfix
  git checkout 3a4ffcd
  pushd docs
    wget https://github.com/LuaDist/libzzip/raw/master/docs/zziplib-manpages.tar
  popd
popd

pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j10 > make.log
  # cat make.log | grep memdisk.c
  pushd zzip
    gcc -E -DHAVE_CONFIG_H -I.. -I../. -static -fsanitize=address -g -MT memdisk.lo -MD -MP -MF .deps/memdisk.Tpo -c memdisk.c > memdisk.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c memdisk.c.i
    mv tmp.c memdisk.c.i.c
    cp memdisk.c.i.c memdisk.c
  popd
popd
/home/yuntong/pacfix/main.exe -synth_only -debug -cycle 60 -timeout 200 ./config 