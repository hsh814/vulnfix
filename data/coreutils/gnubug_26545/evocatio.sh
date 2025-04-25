#!/bin/bash
rm -rf evocatio-source
git clone https://github.com/coreutils/coreutils.git evocatio-source
pushd evocatio-source
  git checkout 8d34b45
  # for AFL argv fuzz
  sed -i '1215i #include "/home/yuntong/vulnfix/thirdparty/AFL/experimental/argv_fuzzing/argv-fuzz-inl.h"' src/shred.c
  sed -i '1220i AFL_INIT_SET03("./shred", "/home/yuntong/vulnfix/data/coreutils/gnubug_26545/dummy");' src/shred.c
  # -u option can cause a lot of files to be writting to disk during fuzzing; disable that
  sed -i '1260i break;' src/shred.c
  # remove and recreate output so that it does not grow too big.
  sed -i '1320i FILE* file_ptr = fopen(file[i], "w"); fclose(file_ptr);' src/shred.c
  # not bulding man pages
  sed -i '217d' Makefile.am
  # change gnulib evocatio-source
  git clone https://github.com/coreutils/gnulib.git
  ./bootstrap
  cp ../shred.evocatio.c ./src/shred.c
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
  echo "shred.c:292" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="shred"
  export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  export FORCE_UNSAFE_CONFIGURE=1
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 ../evocatio-source/configure
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 make CFLAGS="$ADDITIONAL_FLAGS -Wno-error -fsanitize=address -ggdb" CXXFLAGS="$ADDITIONAL_FLAGS -Wno-error -fsanitize=address -ggdb" LDFLAGS="-fsanitize=address" -j10
popd

rm -rf evocatio-runtime && mkdir -p evocatio-runtime/in
cp exploit ./evocatio-runtime/in
cp ./evocatio-build/src/shred evocatio-runtime/shred
