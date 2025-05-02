#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

git clone https://github.com/bminor/binutils-gdb.git
mv binutils-gdb pacfix
pushd pacfix/
  git checkout 7a31b38ef87d133d8204cae67a97f1989d25fa18
popd

sed '6720s/.*/  if((dynsymcount * dynsymcount) < 0) exit(0);/' ./pacfix/bfd/elf64-x86-64.c > temp && mv temp ./pacfix/bfd/elf64-x86-64.c 


pushd pacfix
  ASAN_OPTIONS=detect_leaks=0 CC=gcc CXX=g++ CFLAGS="-DFORTIFY_pacfix=2 -fstack-protector-all -fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer -g -Wno-error" CXXFLAGS="$CFLAGS" ./configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g -Wno-error" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10
  pushd bfd
    gcc -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -DHAVE_CONFIG_H -I. -I. -I. -I./../include -DHAVE_x86_64_elf64_vec -DHAVE_i386_elf32_vec -DHAVE_iamcu_elf32_vec -DHAVE_x86_64_elf32_vec -DHAVE_i386_aout_linux_vec -DHAVE_i386_pei_vec -DHAVE_x86_64_pei_vec -DHAVE_l1om_elf64_vec -DHAVE_k1om_elf64_vec -DHAVE_elf64_le_vec -DHAVE_elf64_be_vec -DHAVE_elf32_le_vec -DHAVE_elf32_be_vec -DHAVE_plugin_vec -DBINDIR=\"/usr/local/bin\" -W -Wall -Wstrict-prototypes -Wmissing-prototypes -Wshadow -Wstack-usage=262144 -Werror -I./../zlib -ldl -lutil -fsanitize=address -fsanitize=undefined -g -Wno-error -MT elf64-x86-64.lo -MD -MP -MF .deps/elf64-x86-64.Tpo -c elf64-x86-64.c -lm -s > elf64-x86-64.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c elf64-x86-64.c.i
    mv tmp.c ./elf64-x86-64.c.i.c 
    cp elf64-x86-64.c.i.c elf64-x86-64.c
  popd
popd
/home/yuntong/pacfix/main.exe -synth_only -debug -seed -nouniq -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 300 ./config

