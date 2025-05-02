#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

git clone https://github.com/coreutils/coreutils.git pacfix
pushd pacfix
  git checkout 8d34b45
  # for AFL argv fuzz
  sed -i '1215i #include "/home/yuntong/vulnfix/thirdparty/AFL/experimental/argv_fuzzing/argv-fuzz-inl.h"' src/shred.c
  sed -i '1220i AFL_INIT_SET03("./shred", "/home/yuntong/vulnfix/data/coreutils/gnubug_26545/dummy");' src/shred.c
  # -u option can cause a lot of files to be writting to disk during fuzzing; disable that
  sed -i '1260i break;' src/shred.c
  # remove and recreate output so that it does not grow too big.
  sed -i '1320i FILE* file_ptr = fopen(file[i], "w"); fclose(file_ptr);' src/shred.c
  # not bulding man pages
  sed -i '217d' Makefile.am
  # change gnulib pacfix
  sed -i "s|git://git.sv.gnu.org/gnulib.git|https://github.com/coreutils/gnulib.git|g" .gitmodules
  sed -i "s|git://git.sv.gnu.org/gnulib|https://github.com/coreutils/gnulib.git|g" bootstrap
  ./bootstrap
popd

cp ./shred.pacfix.c ./pacfix/src/shred.c


pushd pacfix
  export FORCE_UNSAFE_CONFIGURE=1 && ./configure 
  make CFLAGS="-Wno-error -fsanitize=address -ggdb" CXXFLAGS="-Wno-error -fsanitize=address -ggdb" LDFLAGS="-fsanitize=address" -j10
  gcc  -E -I. -I./lib  -Ilib -I./lib -Isrc -I./src -Wno-error -fsanitize=address -ggdb -c src/shred.c -lm -s > src/shred.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c ./src/shred.c.i
  mv tmp.c ./src/shred.c.i.c 
  cp ./src/shred.c.i.c src/shred.c
popd
/home/yuntong/pacfix/main.exe -synth_only -debug -cycle 600 -timeout 21600 ./config 
