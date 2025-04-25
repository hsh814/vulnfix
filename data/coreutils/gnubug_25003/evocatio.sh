#!/bin/bash
rm -rf evocatio-source
git clone https://github.com/coreutils/coreutils.git evocatio-source
pushd evocatio-source
  git checkout 68c5eec
  # for AFL argv fuzz
  sed -i '1283i #include "/home/yuntong/vulnfix/thirdparty/AFL/experimental/argv_fuzzing/argv-fuzz-inl.h"' src/split.c
  sed -i '1288i AFL_INIT_SET02("./split", "/home/yuntong/vulnfix/data/coreutils/gnubug_25003/dummy");' src/split.c
  # avoid writing out a lot of files during fuzzing
  sed -i '595i return false;' src/split.c
  # not bulding man pages
  sed -i '229d' Makefile.am
  # change gnulib evocatio-source
  git clone https://github.com/coreutils/gnulib.git
  ./bootstrap
  cp ../split.evocatio.c ./src/split.c
popd

export EVOCATIO=/home/yuntong/vulnfix/thirdparty/Evocatio/bug-severity-AFLplusplus
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
rm -rf evocatio-build && mkdir evocatio-build
pushd evocatio-build
  mkdir temp
  TMP_DIR=$PWD/temp
  mkdir aflrun_tmp
  export AFLRUN_TMP=$PWD/aflrun_tmp
  echo "split.c:988" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="split"
  export FORCE_UNSAFE_CONFIGURE=1
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 ../evocatio-source/configure
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" -j 10
popd

rm -rf evocatio-runtime && mkdir -p evocatio-runtime/in
cp exploit ./evocatio-runtime/in
cp ./evocatio-build/src/split evocatio-runtime/split