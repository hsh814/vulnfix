#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

unzip source.zip
mv libjpeg-turbo-32120054c224d1911ebe33dc664c0f730a7782b2 pacfix 
pushd pacfix
  autoreconf -i
popd

cp jdpostct.pacfix.c  ./pacfix/jdpostct.c 

pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
  # cat make.log | grep jdpostct.c
  gcc -E -DHAVE_CONFIG_H -I. -Wall -fsanitize=address -fsanitize=undefined -g -MT jdpostct.lo -MD -MP -MF .deps/jdpostct.Tpo -c jdpostct.c > jdpostct.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c jdpostct.c.i
  mv tmp.c jdpostct.c.i.c
  cp jdpostct.c.i.c jdpostct.c
  gcc -E -DHAVE_CONFIG_H -I. -Wall -fsanitize=address -fsanitize=undefined -g -MT jquant1.lo -MD -MP -MF .deps/jquant1.Tpo -c jquant1.c > jquant1.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c jquant1.c.i
  mv tmp.c jquant1.c.i.c
  cp jquant1.c.i.c jquant1.c
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -debug -nouniq -seed -epsilon 0.0 -cycle 60 -timeout 300 ./config
