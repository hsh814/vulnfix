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

rm -rf smake_source && mkdir smake_source
pushd smake_source
  export FORCE_UNSAFE_CONFIGURE=1 && ../source/configure
  /home/yuntong/vulnfix/thirdparty/smake/smake --init
  /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list
popd

rm -rf sparrow-out && mkdir sparrow-out
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "cil" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=make-prime-list.c:216" \
./smake_source/sparrow/src/*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/coreutils/gnubug_19784/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/coreutils/gnubug_19784/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  ../source/configure

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/coreutils/gnubug_19784/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/coreutils/gnubug_19784/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list
popd

rm -rf raw_build && mkdir raw_build
pushd raw_build
  ../source/configure 
  make  CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list
popd

# aflgo
export AFLGO=/home/yuntong/vulnfix/thirdparty/aflgo
rm -rf aflgo_build && mkdir aflgo_build
pushd aflgo_build
  # first build
  mkdir temp
  TMP_DIR=$PWD/temp
  echo "make-prime-list.c:216" > $TMP_DIR/BBtargets.txt
  ADDITIONAL_FLAGS="-targets=$TMP_DIR/BBtargets.txt -outdir=$TMP_DIR -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  FORCE_UNSAFE_CONFIGURE=1 AFL_PATH=$AFLGO CC=$AFLGO/afl-clang-fast CXX=$AFLGO/afl-clang-fast++ ../source/configure
  AFL_PATH=$AFLGO CC=$AFLGO/afl-clang-fast CXX=$AFLGO/afl-clang-fast++ make CFLAGS="$ADDITIONAL_FLAGS -Wno-error -fsanitize=address -g" CXXFLAGS="$ADDITIONAL_FLAGS -Wno-error -fsanitize=address -g" src/make-prime-list -j10
  # generate distance
  cat $TMP_DIR/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > $TMP_DIR/BBnames2.txt \
            && mv $TMP_DIR/BBnames2.txt $TMP_DIR/BBnames.txt
  cat $TMP_DIR/BBcalls.txt | sort | uniq > $TMP_DIR/BBcalls2.txt \
            && mv $TMP_DIR/BBcalls2.txt $TMP_DIR/BBcalls.txt
  $AFLGO/scripts/genDistance.sh $PWD $TMP_DIR make-prime-list
  # second build
  make clean
  ADDITIONAL_FLAGS="-distance=$TMP_DIR/distance.cfg.txt"
  AFL_PATH=$AFLGO CC=$AFLGO/afl-clang-fast CXX=$AFLGO/afl-clang-fast++ make CFLAGS="$ADDITIONAL_FLAGS -Wno-error -fsanitize=address -g" CXXFLAGS="$ADDITIONAL_FLAGS -Wno-error -fsanitize=address -g" src/make-prime-list -j10
popd

cp raw_build/src/make-prime-list ./make-prime-list
cp dafl_source/src/make-prime-list ./make-prime-list.instrumented
cp aflgo_build/src/make-prime-list ./make-prime-list.aflgo
