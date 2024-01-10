#!/bin/bash
rm -rf source
git clone https://github.com/bminor/binutils-gdb.git
mv binutils-gdb source
cd source/
git checkout 515f23e63c0074ab531bc954f84ca40c6281a724

cd ..
rm -rf smake_source
mkdir smake_source
cd smake_source

# Build with Smake
ASAN_OPTIONS=detect_leaks=0 CC=clang CXX=clang++ CMAKE_EXPORT_COMPILE_COMMANDS=1 CFLAGS="-DFORTIFY_SOURCE=2 -fno-omit-frame-pointer -fsanitize=address -ggdb -Wno-error" CXXFLAGS="$CFLAGS" ../source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'

/home/yuntong/vulnfix/thirdparty/smake/smake --init

ASAN_OPTIONS=detect_leaks=0 /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-ldl -lutil -fsanitize=address -ggdb -Wno-error" CXXFLAGS="-fsanitize=address -ldl -lutil -ggdb -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address" -j 10

# Move smake result to sparrow
cd sparrow/binutils
cp -R ./nm-new ../../../nm-new-sparrow
cd ../../../
rm -rf sparrow-out
mkdir sparrow-out

# Run Sparrow
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "cil" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=dwarf2.c:2441" \
./nm-new-sparrow/*.i

rm -rf dafl_source
mkdir dafl_source
cd dafl_source

# Run DAFL Instrumentation
DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/sparrow-out/bug/slice_func.txt" \
DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/sparrow-out/bug/slice_dfg.txt" \
ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
CMAKE_EXPORT_COMPILE_COMMANDS=1 CFLAGS="-DFORTIFY_SOURCE=2 -fno-omit-frame-pointer -fsanitize=address -ggdb -Wno-error" \
CXXFLAGS="$CFLAGS" ../source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'

DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/sparrow-out/bug/slice_func.txt" \
DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/sparrow-out/bug/slice_dfg.txt" \
ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
make CFLAGS="-ldl -lutil -fsanitize=address -ggdb -Wno-error" CXXFLAGS="-fsanitize=address -ldl -lutil -ggdb -Wno-error" \
LDFLAGS=" -ldl -lutil -fsanitize=address" -j 10

cd ..
cp ./dafl_source/binutils/nm-new ./nm-new.instrumented

rm -rf raw_build
mkdir raw_build
cd raw_build
ASAN_OPTIONS=detect_leaks=0 CC=gcc CXX=g++ CFLAGS="-DFORTIFY_SOURCE=2 -fno-omit-frame-pointer -fsanitize=address -ggdb -Wno-error" CXXFLAGS="$CFLAGS" ../source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-ldl -lutil -fsanitize=address -ggdb -Wno-error" CXXFLAGS="-fsanitize=address -ldl -lutil -ggdb -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address" -j 10

cd ..
cp ./raw_build/binutils/nm-new ./nm-new