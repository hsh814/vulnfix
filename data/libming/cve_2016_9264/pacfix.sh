#!/bin/bash
rm -rf source
unzip source.zip
mv libming-cc6a386555a2fb13589f92473dd65b289a38d02d source
cp ./source/util/listmp3.c listmp3.orig.c 

rm -rf pacfix
cp -r source pacfix
pushd pacfix
  ./autogen.sh
  ./configure --disable-freetype
  make CFLAGS="-static -fcommon -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g"
  # cat make.log | grep jdmarker.c
  pushd util
    gcc -E -DHAVE_CONFIG_H -I. -I..-Wall -fsanitize=address -fsanitize=undefined -g -MT listmp3.lo -MD -MP -MF .deps/listmp3.Tpo -c listmp3.c > listmp3.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c listmp3.c.i
    mv tmp.c listmp3.c.i.c
    cp listmp3.c.i.c listmp3.c
  popd
popd
$VULNFIX_HOME/pacfix/main.exe -lv_only 1 config

# manually fix the code
# python3 $VULNFIX_HOME/vulnfix/src/add_lv.py 327 repair-out/live_variables ./source/jdmarker.c 
#cp listmp3.pacfix.c ./source/listmp3.c

#rm -rf smake_source && cp -R source smake_source
#pushd smake_source
#  ./autogen.sh
#  CC=clang CXX=clang++ ./configure --disable-freetype
#  CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake --init
#  CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake CFLAGS="-static -fcommon -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g"
#popd

cp listmp3.orig.c ./source/listmp3.c

#rm -rf sparrow-out && mkdir sparrow-out
#$VULNFIX_HOME/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
#-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
#-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
#-entry_point "main" -max_pre_iter 10 -slice "bug=listmp3.c:128" \
#./smake_source/sparrow/util/listmp3/*.i

rm -rf dafl_source && cp -R source dafl_source
pushd dafl_source
  ./autogen.sh
  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=clang CXX=clang++ \
  ./configure --disable-freetype

  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=clang CXX=clang++ \
  make CFLAGS="-static -fcommon -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fcommon -fsanitize=address -fsanitize=undefined -g"

  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  ./configure --disable-freetype

  pushd util
    make clean    
    DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_func.txt" \
    DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_dfg.txt" \
    ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
    make listmp3 CFLAGS="-static -fcommon -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fcommon -fsanitize=address -fsanitize=undefined -g"
  popd
popd

cp dafl_source/util/listmp3 ./listmp3.instrumented

# AFL_NO_UI=1 timeout 12h $VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_5321/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcrop.instrumented @@ /tmp/out.tmp


