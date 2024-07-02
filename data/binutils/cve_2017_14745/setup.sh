#!/bin/bash
rm -rf source
git clone https://github.com/bminor/binutils-gdb.git
mv binutils-gdb source
cd source/
git checkout 7a31b38ef87d133d8204cae67a97f1989d25fa18

cd ..
rm -rf smake_source
mkdir smake_source
cd smake_source

# Build with Smake
ASAN_OPTIONS=detect_leaks=0 CC=gcc CXX=g++ CFLAGS="-DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer -g -Wno-error" CXXFLAGS="$CFLAGS" ../source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
/home/yuntong/vulnfix/thirdparty/smake/smake --init
ASAN_OPTIONS=detect_leaks=0 /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10


# Run Sparrow
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "cil" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=elf64-x86-64.c:6632" \
./smake_source/sparrow/objdump/*.i

rm -rf dafl_source
mkdir dafl_source
cd dafl_source

# Run DAFL Instrumentation
DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/binutils/cve_2017_14745/sparrow-out/bug/slice_func.txt" \
DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/binutils/cve_2017_14745/sparrow-out/bug/slice_dfg.txt" \
ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
CMAKE_EXPORT_COMPILE_COMMANDS=1 CFLAGS="-DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer -g -Wno-error"  \
CXXFLAGS="$CFLAGS" ../source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'

DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/binutils/cve_2017_14745/sparrow-out/bug/slice_func.txt" \
DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/binutils/cve_2017_14745/sparrow-out/bug/slice_dfg.txt" \
ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g -Wno-error" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g -Wno-error" \ 
LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j 10


cd ..
cp ./dafl_source/binutils/objdump ./objdump.instrumented

rm -rf raw_build
mkdir raw_build
cd raw_build
ASAN_OPTIONS=detect_leaks=0 CC=gcc CXX=g++ CFLAGS="-DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer -g -Wno-error" CXXFLAGS="$CFLAGS" ../source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10

cd ..
cp ./raw_build/binutils/objdump ./objdump
