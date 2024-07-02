#!/bin/bash
rm -rf source
git clone https://github.com/coreutils/coreutils.git source
pushd source
  git checkout ca99c52
  # for AFL argv fuzz
  sed -i '856i #include "/home/yuntong/vulnfix/thirdparty/AFL/experimental/argv_fuzzing/argv-fuzz-inl.h"' src/pr.c
  sed -i '860i AFL_INIT_SET0234("./pr", "/home/yuntong/vulnfix/data/coreutils/gnubug_25023/dummy", "-m", "/home/yuntong/vulnfix/data/coreutils/gnubug_25023/dummy");' src/pr.c
  # not bulding man pages
  sed -i '229d' Makefile.am
  # change gnulib source
  sed -i "s|git://git.sv.gnu.org/gnulib.git|https://github.com/coreutils/gnulib.git|g" .gitmodules
  sed -i "s|git://git.sv.gnu.org/gnulib|https://github.com/coreutils/gnulib.git|g" bootstrap
  ./bootstrap
popd

cp ./source/src/pr.c ./pr.orig.c

rm -rf pacfix
cp -r source pacfix
pushd pacfix
  export FORCE_UNSAFE_CONFIGURE=1 && ./configure CFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g"
  make CFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" -j10
  gcc  -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -I. -I./lib  -Ilib -I./lib -Isrc -I./src -Wno-error -fsanitize=address -fsanitize=undefined -g -c src/pr.c -lm -s > src/pr.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c ./src/pr.c.i
  mv tmp.c ./src/pr.c.i.c 
  cp ./src/pr.c.i.c src/pr.c
popd
/home/yuntong/pacfix/main.exe -lv_only 1 config

cp ./pr.pacfix.c ./source/src/pr.c 


rm -rf smake_source && mkdir smake_source
pushd smake_source
  export FORCE_UNSAFE_CONFIGURE=1 && CC=clang CXX=clang++ ../source/configure CFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g"
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake --init
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" -j10
popd

cp ./pr.orig.c ./source/src/pr.c 

rm -rf sparrow-out && mkdir sparrow-out
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=pr.c:2243" \
./smake_source/sparrow/src/pr/*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/coreutils/gnubug_25003/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/coreutils/gnubug_25003/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  ../source/configure

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/coreutils/gnubug_25003/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/coreutils/gnubug_25003/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" -j 10
popd

cp dafl_source/src/pr ./pr.instrumented