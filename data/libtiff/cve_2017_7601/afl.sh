#!/bin/bash
rm -rf afl-source
unzip source.zip 
mv libtiff-3144e57770c1e4d26520d8abee750f8ac8b75490 afl-source
cp tif_jpeg.evocatio.c ./afl-source/libtiff/tif_jpeg.c

export AFL_DIR=/home/yuntong/vulnfix/thirdparty/AFL
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
rm -rf afl-build && mkdir afl-build
pushd afl-build
  mkdir temp
  TMP_DIR=$PWD/temp
  mkdir aflrun_tmp
  export AFLRUN_TMP=$PWD/aflrun_tmp
  echo "tif_jpeg.c:1646" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="tiffcp"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  export FORCE_UNSAFE_CONFIGURE=1
  CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ ASAN_OPTIONS=detect_leaks=0 ../afl-source/configure
  CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
popd

rm -rf afl-runtime && mkdir -p afl-runtime/in
cp exploit ./afl-runtime/in
cp ./afl-build/tools/tiffcp afl-runtime/tiffcp


# AFL_NO_UI=1 timeout 12h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p /home/yuntong/vulnfix/data/libtiff/cve_2016_5321/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcrop.instrumented @@ /tmp/out.tmp


