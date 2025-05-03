#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

git clone https://github.com/coreutils/coreutils.git pacfix
pushd pacfix
  git checkout ca99c52
  # for AFL argv fuzz
  sed -i '856i #include "/home/yuntong/vulnfix/thirdparty/AFL/experimental/argv_fuzzing/argv-fuzz-inl.h"' src/pr.c
  sed -i '860i AFL_INIT_SET0234("./pr", "/home/yuntong/vulnfix/data/coreutils/gnubug_25023/dummy", "-m", "/home/yuntong/vulnfix/data/coreutils/gnubug_25023/dummy");' src/pr.c
  # not bulding man pages
  sed -i '229d' Makefile.am
  # change gnulib pacfix
  sed -i "s|git://git.sv.gnu.org/gnulib.git|https://github.com/coreutils/gnulib.git|g" .gitmodules
  sed -i "s|git://git.sv.gnu.org/gnulib|https://github.com/coreutils/gnulib.git|g" bootstrap
  ./bootstrap
popd


pushd pacfix
  export FORCE_UNSAFE_CONFIGURE=1 && ./configure CFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g"
  make CFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" -j10
  gcc  -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -I. -I./lib  -Ilib -I./lib -Isrc -I./src -Wno-error -fsanitize=address -fsanitize=undefined -g -c src/pr.c -lm -s > src/pr.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c ./src/pr.c.i
  mv tmp.c ./src/pr.c.i.c 
  cp ./src/pr.c.i.c src/pr.c
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -debug -epsilon 0.0 -cycle 60 -nouniq  -timeout 300 ./config 