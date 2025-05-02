#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git pacfix

pushd pacfix
  git checkout 4f24016
  autoreconf -fiv
popd

cp ./jdmarker.pacfix2.c ./pacfix/jdmarker.c

pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10 > make.log
  # cat make.log | grep jdmarker.c
  gcc -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -DHAVE_CONFIG_H -I. -Wall -fsanitize=address -fsanitize=undefined -g -MT libturbojpeg_la-jdmarker.lo -MD -MP -MF .deps/libturbojpeg_la-jdmarker.Tpo -c jdmarker.c -lm -s > jdmarker.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c jdmarker.c.i
  mv tmp.c jdmarker.c.i.c
  cp jdmarker.c.i.c jdmarker.c
popd
/home/yuntong/pacfix/main.exe -synth_only -debug -seed -nouniq -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 300 ./config
