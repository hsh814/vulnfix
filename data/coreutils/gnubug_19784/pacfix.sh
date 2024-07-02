#!/bin/bash
rm -rf source
git clone https://github.com/coreutils/coreutils.git source
pushd source
  git checkout 658529a
  # for AFL argv fuzz
  sed -i '29i #include "/home/yuntong/vulnfix/thirdparty/AFL/experimental/argv_fuzzing/argv-fuzz-inl.h"' src/make-prime-list.c
  sed -i '175i AFL_INIT_SET0("./make-prime-list");' src/make-prime-list.c
  sed -i "s|git://git.sv.gnu.org/gnulib.git|https://github.com/coreutils/gnulib.git|g" .gitmodules
  sed -i "s|git://git.sv.gnu.org/gnulib|https://github.com/coreutils/gnulib.git|g" bootstrap
  ./bootstrap
popd

cp ./source/src/make-prime-list.c ../make-prime-list.orig.c

rm -rf pacfix
cp -r source pacfix
pushd pacfix
  export FORCE_UNSAFE_CONFIGURE=1 && ./configure
  make  CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list
  pushd src
    # gcc -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -DHAVE_CONFIG_H -I. -I. -I. -I./../include -DHAVE_x86_64_elf64_vec -DHAVE_i386_elf32_vec -DHAVE_iamcu_elf32_vec -DHAVE_x86_64_elf32_vec -DHAVE_i386_aout_linux_vec -DHAVE_i386_pei_vec -DHAVE_x86_64_pei_vec -DHAVE_l1om_elf64_vec -DHAVE_k1om_elf64_vec -DHAVE_elf64_le_vec -DHAVE_elf64_be_vec -DHAVE_elf32_le_vec -DHAVE_elf32_be_vec -DHAVE_plugin_vec -DBINDIR=\"/usr/local/bin\" -W -Wall -Wstrict-prototypes -Wmissing-prototypes -Wshadow -Wstack-usage=262144 -Werror -I./../zlib -ldl -lutil -fsanitize=address -ggdb -Wno-error -MT dwarf2.lo -MD -MP -MF .deps/dwarf2.Tpo -c -DDEBUGDIR=\"/usr/local/lib/debug\" ./dwarf2.c -lm -s > dwarf2.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c make-prime-list.c.i
    mv tmp.c ./make-prime-list.c.i.c 
    cp make-prime-list.c.i.c make-prime-list.c
  popd
popd
/home/yuntong/pacfix/main.exe -lv_only 1 config

cp make-prime-list.pacfix.c source/src/make-prime-list.c

rm -rf smake_source
mkdir smake_source
pushd smake_source
  # Build with Smake
  export FORCE_UNSAFE_CONFIGURE=1 && ../source/configure
  /home/yuntong/vulnfix/thirdparty/smake/smake --init
  /home/yuntong/vulnfix/thirdparty/smake/smake  CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list
popd

cp ./make-prime-list.orig.c ./source/src/make-prime-list.c 

rm -rf sparrow-out
mkdir sparrow-out
# Run Sparrow
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=make-prime-list.c:216" \
./smake_source/sparrow/src/*.i

rm -rf dafl_source
mkdir dafl_source
pushd dafl_source
  # Run DAFL Instrumentation
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/sparrow-out/bug/slice_dfg.txt" \
  CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  CMAKE_EXPORT_COMPILE_COMMANDS=1 ../source/configure

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/coreutils/gnubug_19784/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/coreutils/gnubug_19784/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list
popd

cp dafl_source/src/make-prime-list ./make-prime-list.instrumented