#!/bin/bash
rm -rf source
git clone https://github.com/coreutils/coreutils.git source
pushd source
  git checkout 658529a
  # for AFL argv fuzz
  sed -i '29i #include "$VULNFIX_HOME/vulnfix/thirdparty/AFL/experimental/argv_fuzzing/argv-fuzz-inl.h"' src/make-prime-list.c
  sed -i '175i AFL_INIT_SET0("./make-prime-list");' src/make-prime-list.c
  git clone https://github.com/coreutils/gnulib.git
  ./bootstrap
popd

cp ./make-prime-list.pacfix2.c ./source/src/make-prime-list.c
cp ./source/src/make-prime-list.c ./make-prime-list.orig.c

rm -rf pacfix
cp -r source pacfix
pushd pacfix
  export FORCE_UNSAFE_CONFIGURE=1 && ./configure
  make  CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list 
  pushd src
    gcc -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -DHAVE_CONFIG_H -I. -I../lib ./make-prime-list.c  -lm -s > make-prime-list.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c make-prime-list.c.i
    mv tmp.c ./make-prime-list.c.i.c 
    cp make-prime-list.c.i.c make-prime-list.c
  popd
popd
# $VULNFIX_HOME/pacfix/main.exe -lv_only 1 config

cp make-prime-list.pacfix.c source/src/make-prime-list.c

rm -rf smake_source
mkdir smake_source
pushd smake_source
  # Build with Smake
  export FORCE_UNSAFE_CONFIGURE=1 && ../source/configure
  $VULNFIX_HOME/vulnfix/thirdparty/smake/smake --init
  $VULNFIX_HOME/vulnfix/thirdparty/smake/smake  CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list
popd

cp ./make-prime-list.orig.c ./source/src/make-prime-list.c 

rm -rf sparrow-out
mkdir sparrow-out
# Run Sparrow
$VULNFIX_HOME/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=make-prime-list.c:218" \
./smake_source/sparrow/src/*.i

rm -rf dafl_source
mkdir dafl_source
pushd dafl_source
  # Run DAFL Instrumentation
  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_15025/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_15025/sparrow-out/bug/slice_dfg.txt" \
  CC=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  CMAKE_EXPORT_COMPILE_COMMANDS=1 ../source/configure

  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/coreutils/gnubug_19784/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/coreutils/gnubug_19784/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list
popd

cp dafl_source/src/make-prime-list ./make-prime-list.instrumented
