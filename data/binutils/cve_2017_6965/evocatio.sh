#!/bin/bash
rm -rf evocatio-source
git clone https://github.com/bminor/binutils-gdb.git
mv binutils-gdb evocatio-source
pushd evocatio-source/
  git checkout 53f7e8ea7fad1fcff1b58f4cbd74e192e0bcbc1d
  cp ../elfcomm.evocatio.c ./binutils/elfcomm.c
popd

rm -rf evocatio-build && mkdir evocatio-build
export EVOCATIO=/home/yuntong/vulnfix/thirdparty/Evocatio/bug-severity-AFLplusplus
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
pushd evocatio-build
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++  ../evocatio-source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g -Wno-error" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j 10

popd

rm -rf evocatio-runtime && mkdir evocatio-runtime
pushd evocatio-runtime
  mkdir in
  cp ../exploit ./in
  cp ../evocatio-build/binutils/readelf ./readelf
popd

