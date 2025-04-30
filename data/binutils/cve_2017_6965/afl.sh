#!/bin/bash
rm -rf afl-source
git clone https://github.com/bminor/binutils-gdb.git
mv binutils-gdb afl-source
pushd afl-source/
  git checkout 53f7e8ea7fad1fcff1b58f4cbd74e192e0bcbc1d
  cp ../elfcomm.evocatio.c ./binutils/elfcomm.c
popd

rm -rf afl-build && mkdir afl-build
export AFL_DIR=/home/yuntong/vulnfix/thirdparty/AFL
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
pushd afl-build
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ CMAKE_EXPORT_COMPILE_COMMANDS=1 CFLAGS="-DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=undefined,address -fno-omit-frame-pointer -ggdb -Wno-error" ../afl-source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  make CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g -Wno-error" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j 10

popd

rm -rf afl-runtime && mkdir afl-runtime
pushd afl-runtime
  mkdir in
  cp ../exploit ./in
  cp ../afl-build/binutils/readelf ./readelf
popd

