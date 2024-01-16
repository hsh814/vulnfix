#!/bin/bash
rm -rf source
git clone https://github.com/vadz/libtiff.git
mv libtiff source
pushd source
  git checkout 9a72a69e035ee70ff5c41541c8c61cd97990d018
popd

rm -rf smake_source && mkdir smake_source
pushd smake_source
  OJPEG_SUPPORT=true JPEG_SUPPORT=true ../source/configure --enable-static --disable-shared --enable-old-jpeg
  /home/yuntong/vulnfix/thirdparty/smake/smake --init
  /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
popd

rm -rf sparrow-out && mkdir sparrow-out
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "cil" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=tif_ojpeg.c:816" \
./smake_source/sparrow/tools/tiffmedian/*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libtiff/bugzilla_2611/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libtiff/bugzilla_2611/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  CMAKE_EXPORT_COMPILE_COMMANDS=1 CFLAGS="-DFORTIFY_SOURCE=2 -fno-omit-frame-pointer -fsanitize=address -ggdb -Wno-error" \
  CXXFLAGS="$CFLAGS" ../source/configure

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libtiff/bugzilla_2611/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libtiff/bugzilla_2611/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-ldl -lutil -fsanitize=address -ggdb -Wno-error" CXXFLAGS="-fsanitize=address -ldl -lutil -ggdb -Wno-error" \
  LDFLAGS=" -ldl -lutil -fsanitize=address" -j 10
popd

rm -rf raw_build && mkdir raw_build
pushd raw_build
  ../source/configure
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
popd

cp raw_build/tools/tiffmedian ../tiffmedian
cp dafl_source/tools/tiffmedian ../tiffmedian.instrumented
