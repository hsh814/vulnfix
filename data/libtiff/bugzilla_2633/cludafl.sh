#!/bin/bash
rm -rf source
unzip source.zip
mv libtiff-f3069a5adc65b67b90222441e3711b236a16e624 source
cp ./source/tools/tiff2ps.c tiff2ps.orig.c 

eval $(opam env --switch=default)
# rm -rf pacfix
# cp -r source pacfix
# pushd pacfix
#   ./configure
#   make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
#   pushd tools
#     gcc -E -DHAVE_CONFIG_H -I. -I../libtiff  -I../libtiff   -static -fsanitize=address -fsanitize=undefined -g -MT tiff2ps.o -MD -MP -MF .deps/tiff2ps.Tpo -c tiff2ps.c > tiff2ps.c.i
#     cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c tiff2ps.c.i
#     mv tmp.c tiff2ps.c.i.c
#     cp tiff2ps.c.i.c tiff2ps.c
#   popd
# popd
# $VULNFIX_HOME/pacfix/main.exe -lv_only 1 config

cp tiff2ps.pacfix.c ./source/tools/tiff2ps.c

rm -rf smake_source && mkdir smake_source
echo Running smake...
pushd smake_source
 CC=clang CXX=clang++ ../source/configure
 CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake --init
 CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
popd

cp tiff2ps.orig.c ./source/tools/tiff2ps.c

echo smake finished!

rm -rf sparrow-out && mkdir sparrow-out
echo Running sparrow...
$VULNFIX_HOME/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=tiff2ps.c:2470" \
./smake_source/sparrow/tools/tiff2ps/*.i

echo sparrow finished!

rm -rf dafl_source && mkdir dafl_source
echo Building with DAFL...
pushd dafl_source
  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/libtiff/bugzilla_2633/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/libtiff/bugzilla_2633/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-clang-fast++ \
  ../source/configure 
  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/libtiff/bugzilla_2633/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/libtiff/bugzilla_2633/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-clang-fast++ \
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
popd

rm -rf cludafl-runtime && mkdir cludafl-runtime
cp dafl_source/tools/tiff2ps cludafl-runtime/tiff2ps

# AFL_NO_UI=1 timeout 12h $VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_5321/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcrop.instrumented @@ /tmp/out.tmp


