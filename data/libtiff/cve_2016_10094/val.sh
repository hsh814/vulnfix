#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

git clone https://github.com/vadz/libtiff.git pacfix
pushd pacfix
  git checkout b28076b
popd

pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10 > make.log
  # cat make.log | grep tiff2pdf.c
  pushd tools
    gcc -E -DHAVE_CONFIG_H -I. -I../libtiff  -I../libtiff   -static -fsanitize=address -fsanitize=undefined -g -MT tiff2pdf.o -MD -MP -MF .deps/tiff2pdf.Tpo -c tiff2pdf.c > tiff2pdf.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c tiff2pdf.c.i
    mv tmp.c tiff2pdf.c.i.c
    cp tiff2pdf.c.i.c tiff2pdf.c
  popd
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -debug -lvfile ./live_variables -cycle 60 -timeout 300 ./config 