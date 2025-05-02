#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

unzip source.zip 
mv libtiff-3144e57770c1e4d26520d8abee750f8ac8b75490 pacfix

cp tif_jpeg.pacfix.c pacfix/libtiff/tif_jpeg.c
cp pacfix/libtiff/tif_jpeg.c tif_jpeg.orig.c
cp pacfix/libtiff/tif_write.c tif_write.orig.c
cp pacfix/libtiff/tiffiop.h tiffiop.orig.h


pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
  pushd libtiff
    gcc -E -DHAVE_CONFIG_H -I. -fsanitize=address -fsanitize=undefined -g -MT tif_jpeg.lo -MD -MP -MF .deps/tif_jpeg.Tpo -c tif_jpeg.c > tif_jpeg.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c tif_jpeg.c.i
    mv tmp.c tif_jpeg.c.i.c
    cp tif_jpeg.c.i.c tif_jpeg.c
  popd
popd
/home/yuntong/pacfix/main.exe -synth_only -debug -nouniq -seed -epsilon 0.0 -cycle 60 -timeout 300 ./config
