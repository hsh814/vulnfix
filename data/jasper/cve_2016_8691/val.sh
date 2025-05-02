#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

unzip source.zip -d evocatio-tmp
mv evocatio-tmp/source pacfix
rm -r evocatio-tmp

pushd pacfix
  autoreconf -i
popd

cp ./jpc_dec.pacfix2.c ./pacfix/src/libjasper/jpc/jpc_dec.c

pushd pacfix
  ./configure 
  make  CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j 10 > make.log
  cat make.log | grep jpc_dec.c
  pushd src/libjasper/jpc
    gcc -E -DHAVE_CONFIG_H -I. -I../../../src/libjasper/include/jasper -I../../../src/libjasper/include -fsanitize=address -g -MT jpc_dec.lo -MD -MP -MF .deps/jpc_dec.Tpo -c jpc_dec.c  -lm -s > jpc_dec.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c jpc_dec.c.i
    mv tmp.c jpc_dec.c.i.c 
    cp jpc_dec.c.i.c jpc_dec.c
  popd
popd
/home/yuntong/pacfix/main.exe -synth_only -debug -nouniq -seed -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 300 ./config
