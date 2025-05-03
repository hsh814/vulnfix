#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

git clone https://github.com/coreutils/coreutils.git pacfix
pushd pacfix
  git checkout 658529a
  # for AFL argv fuzz
  sed -i '29i #include "/home/yuntong/vulnfix/thirdparty/AFL/experimental/argv_fuzzing/argv-fuzz-inl.h"' src/make-prime-list.c
  sed -i '175i AFL_INIT_SET0("./make-prime-list");' src/make-prime-list.c
  git clone https://github.com/coreutils/gnulib.git
  ./bootstrap
popd

cp ./make-prime-list.pacfix2.c ./pacfix/src/make-prime-list.c


pushd pacfix
  export FORCE_UNSAFE_CONFIGURE=1 && ./configure
  make  CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list 
  pushd src
    gcc -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -DHAVE_CONFIG_H -I. -I../lib ./make-prime-list.c  -lm -s > make-prime-list.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c make-prime-list.c.i
    mv tmp.c ./make-prime-list.c.i.c 
    cp make-prime-list.c.i.c make-prime-list.c
  popd
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -debug -epsilon 0.0 -cycle 60 -lvfile ./live_variables  -timeout 300 ./config
