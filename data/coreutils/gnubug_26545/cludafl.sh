#!/bin/bash
rm -rf source
git clone https://github.com/coreutils/coreutils.git source
pushd source
  git checkout 8d34b45
  # for AFL argv fuzz
  sed -i '1215i #include "argv_fuzzing/argv-fuzz-inl.h"' src/shred.c
  sed -i '1220i AFL_INIT_SET03("./shred", AFL_HOME "/vulnfix/data/coreutils/gnubug_26545/dummy");' src/shred.c
  # -u option can cause a lot of files to be writting to disk during fuzzing; disable that
  sed -i '1260i break;' src/shred.c
  # remove and recreate output so that it does not grow too big.
  sed -i '1320i FILE* file_ptr = fopen(file[i], "w"); fclose(file_ptr);' src/shred.c
  # not bulding man pages
  sed -i '217d' Makefile.am
  # change gnulib source
  sed -i "s|git://git.sv.gnu.org/gnulib.git|https://github.com/coreutils/gnulib.git|g" .gitmodules
  sed -i "s|git://git.sv.gnu.org/gnulib|https://github.com/coreutils/gnulib.git|g" bootstrap
  git clone https://github.com/coreutils/gnulib.git
  ./bootstrap
popd

cp ./shred.pacfix.c ./source/src/shred.c
cp ./source/src/shred.c ./shred.orig.c


# rm -rf pacfix
# cp -r source pacfix
# pushd pacfix
#   export FORCE_UNSAFE_CONFIGURE=1 && ./configure 
#   make CFLAGS="-Wno-error -fsanitize=address -ggdb -I${VULNFIX_HOME}/vulnfix/thirdparty/AFL/experimental -DAFL_HOME=\\\"${VULNFIX_HOME}\\\"" \
#   CXXFLAGS="-Wno-error -fsanitize=address -ggdb -I${VULNFIX_HOME}/vulnfix/thirdparty/AFL/experimental -DAFL_HOME=\\\"${VULNFIX_HOME}\\\"" LDFLAGS="-fsanitize=address" -j10
#   gcc  -E -I. -I./lib  -Ilib -I./lib -Isrc -I./src -I${VULNFIX_HOME}/vulnfix/thirdparty/AFL/experimental -DAFL_HOME=\"${VULNFIX_HOME}\" -Wno-error -fsanitize=address -ggdb -c src/shred.c -lm -s > src/shred.c.i
#   cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c ./src/shred.c.i
#   mv tmp.c ./src/shred.c.i.c 
#   cp ./src/shred.c.i.c src/shred.c
# popd
# $VULNFIX_HOME/pacfix/main.exe -lv_only 1 config

#cp ./shred.pacfix2.c ./source/src/shred.c 


rm -rf smake_source && mkdir smake_source
echo Running smake...
pushd smake_source
 export FORCE_UNSAFE_CONFIGURE=1 && CC=clang CXX=clang++ ../source/configure 
 CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake --init
 CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake CFLAGS="-Wno-error -fsanitize=address -ggdb -I${VULNFIX_HOME}/vulnfix/thirdparty/AFL/experimental -DAFL_HOME=\\\"${VULNFIX_HOME}\\\"" \
 CXXFLAGS="-Wno-error -fsanitize=address -ggdb -I${VULNFIX_HOME}/vulnfix/thirdparty/AFL/experimental -DAFL_HOME=\\\"${VULNFIX_HOME}\\\"" LDFLAGS="-fsanitize=address" -j10
popd

cp ./shred.orig.c ./source/src/shred.c 

echo smake finished!

rm -rf sparrow-out && mkdir sparrow-out
echo Running sparrow...
$VULNFIX_HOME/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=shred.c:294" \
./smake_source/sparrow/src/shred/*.i

echo sparrow finished!

rm -rf dafl_source && mkdir dafl_source
echo Building with DAFL...
pushd dafl_source
  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/coreutils/gnubug_26545/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/coreutils/gnubug_26545/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  ../source/configure

  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/coreutils/gnubug_26545/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/coreutils/gnubug_26545/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-Wno-error -fsanitize=address -ggdb -I${VULNFIX_HOME}/vulnfix/thirdparty/AFL/experimental -DAFL_HOME=\\\"${VULNFIX_HOME}\\\"" \
  CXXFLAGS="-Wno-error -fsanitize=address -ggdb -I${VULNFIX_HOME}/vulnfix/thirdparty/AFL/experimental -DAFL_HOME=\\\"${VULNFIX_HOME}\\\"" LDFLAGS="-fsanitize=address" -j10
popd

rm -rf cludafl-runtime && mkdir cludafl-runtime
cp dafl_source/src/shred cludafl-runtime/shred
