#!/bin/bash
rm -rf evocatio-source
git clone https://github.com/coreutils/coreutils.git evocatio-source
pushd evocatio-source
  git checkout ca99c52
  # for AFL argv fuzz
  sed -i '856i #include "/home/yuntong/vulnfix/thirdparty/AFL/experimental/argv_fuzzing/argv-fuzz-inl.h"' src/pr.c
  sed -i '860i AFL_INIT_SET0234("./pr", "/home/yuntong/vulnfix/data/coreutils/gnubug_25023/dummy", "-m", "/home/yuntong/vulnfix/data/coreutils/gnubug_25023/dummy");' src/pr.c
  # not bulding man pages
  sed -i '229d' Makefile.am
  # change gnulib evocatio-source
  git clone https://github.com/coreutils/gnulib.git
  ./bootstrap
  cp ../pr.evocatio.c ./src/pr.c
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
  echo "pr.c:2243" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="pr"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  export FORCE_UNSAFE_CONFIGURE=1
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 ../evocatio-source/configure
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g" -j 10
popd

rm -rf evocatio-runtime && mkdir -p evocatio-runtime/in
cp exploit ./evocatio-runtime/in
cp ./evocatio-build/src/pr evocatio-runtime/pr