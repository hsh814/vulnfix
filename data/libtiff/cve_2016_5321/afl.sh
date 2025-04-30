#!/bin/bash
rm -rf afl-source
git clone https://github.com/vadz/libtiff.git
mv libtiff afl-source
pushd afl-source
  git checkout 0ba5d88
  cp ../tiffcrop.evocatio.c ./tools/tiffcrop.c
popd

export AFL_DIR=/home/yuntong/vulnfix/thirdparty/AFL
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
rm -rf afl-build && mkdir afl-build
pushd afl-build
  mkdir temp
  TMP_DIR=$PWD/temp
  mkdir aflrun_tmp
  export AFLRUN_TMP=$PWD/aflrun_tmp
  echo "tiffcrop.c:994" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="tiffcrop"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  LD=ld CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ ../afl-source/configure --enable-static --disable-shared
  CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ make CFLAGS="$ADDITIONAL_FLAGS -static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="$ADDITIONAL_FLAGS -static -fsanitize=address -fsanitize=undefined -g" -j10
popd

rm -rf afl-runtime && mkdir -p afl-runtime/in
cp exploit ./afl-runtime/in
cp ./afl-build/tools/tiffcrop afl-runtime/tiffcrop

# $AFLRUN/afl-fuzz -C -i runtime/afl-in -o runtime/afl-run-out -t 2000 -m none -- afl-build/tools/tiffcrop @@ /tmp/out.tiff