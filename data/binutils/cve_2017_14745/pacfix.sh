#!/bin/bash
rm -rf source
git clone https://github.com/bminor/binutils-gdb.git
mv binutils-gdb source
pushd source/
  git checkout 7a31b38ef87d133d8204cae67a97f1989d25fa18
popd

sed '6720s/.*/  if((dynsymcount * dynsymcount) < 0) exit(0);/' ./source/bfd/elf64-x86-64.c > temp && mv temp ./source/bfd/elf64-x86-64.c 
cp ./source/bfd/elf64-x86-64.c ./elf64-x86-64.orig.c
cp ./source/binutils/objdump.c objdump.orig.c 
cp ./source/bfd/elf-bfd.h elf-bfd.orig.h


rm -rf pacfix
cp -r source pacfix

pushd pacfix
  ASAN_OPTIONS=detect_leaks=0 CC=gcc CXX=g++ CFLAGS="-DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer -g -Wno-error" CXXFLAGS="$CFLAGS" ./configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g -Wno-error" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10
  pushd bfd
    gcc -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -DHAVE_CONFIG_H -I. -I. -I. -I./../include -DHAVE_x86_64_elf64_vec -DHAVE_i386_elf32_vec -DHAVE_iamcu_elf32_vec -DHAVE_x86_64_elf32_vec -DHAVE_i386_aout_linux_vec -DHAVE_i386_pei_vec -DHAVE_x86_64_pei_vec -DHAVE_l1om_elf64_vec -DHAVE_k1om_elf64_vec -DHAVE_elf64_le_vec -DHAVE_elf64_be_vec -DHAVE_elf32_le_vec -DHAVE_elf32_be_vec -DHAVE_plugin_vec -DBINDIR=\"/usr/local/bin\" -W -Wall -Wstrict-prototypes -Wmissing-prototypes -Wshadow -Wstack-usage=262144 -Werror -I./../zlib -ldl -lutil -fsanitize=address -fsanitize=undefined -g -Wno-error -MT elf64-x86-64.lo -MD -MP -MF .deps/elf64-x86-64.Tpo -c elf64-x86-64.c -lm -s > elf64-x86-64.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c elf64-x86-64.c.i
    mv tmp.c ./elf64-x86-64.c.i.c 
    cp elf64-x86-64.c.i.c elf64-x86-64.c
  popd
popd
/home/yuntong/pacfix/main.exe -lv_only 1 config

cp elf64-x86-64.pacfix.c source/bfd/elf64-x86-64.c
cp objdump.pacfix.c source/binutils/objdump.c
cp elf-bfd.pacfix.h ./source/bfd/elf-bfd.h

rm -rf smake_source
mkdir smake_source
pushd smake_source
  # Build with Smake
  ASAN_OPTIONS=detect_leaks=0 CC=gcc CXX=g++ CFLAGS="-DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer -g -Wno-error" CXXFLAGS="$CFLAGS" ../source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  /home/yuntong/vulnfix/thirdparty/smake/smake --init
  ASAN_OPTIONS=detect_leaks=0 /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10
popd

cp elf64-x86-64.orig.c source/bfd/elf64-x86-64.c
cp objdump.orig.c source/binutils/objdump.c
cp elf-bfd.orig.h ./source/bfd/elf-bfd.h

rm -rf sparrow-out
mkdir sparrow-out
# Run Sparrow
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=elf64-x86-64.c:6632" \
./smake_source/sparrow/binutils/objdump/000.objdump.o.i ./smake_source/sparrow/binutils/objdump/032.elf64-x86-64.o.i

rm -rf dafl_source
mkdir dafl_source
pushd dafl_source
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
popd

cp ./dafl_source/binutils/objdump ./objdump.instrumented