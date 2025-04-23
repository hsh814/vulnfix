#!/bin/bash
rm -rf source
unzip source
mv libxml2-db07dd61 source

export AFLRUN=$VULNFIX_HOME/vulnfix/thirdparty/AFLRun
rm -rf aflrun_build && mkdir aflrun_build
pushd aflrun_build
  mkdir temp
  TMP_DIR=$PWD/temp
  mkdir aflrun_tmp
  export AFLRUN_TMP=$PWD/aflrun_tmp
  echo "dict.c:284" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="xmllint"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  export FORCE_UNSAFE_CONFIGURE=1
  CC=$AFLRUN/afl-clang-lto CXX=$AFLRUN/afl-clang-lto++ ASAN_OPTIONS=detect_leaks=0 ../source/autogen.sh
  CC=$AFLRUN/afl-clang-lto CXX=$AFLRUN/afl-clang-lto++ ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
popd
cp aflrun_build/xmllint ./xmllint.aflrun

# AFL_NO_UI=1 timeout 12h $VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_5321/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcrop.instrumented @@ /tmp/out.tmp


