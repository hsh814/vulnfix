#!/bin/bash
pushd pacfix/bfd
  cp dwarf2.c.i.c dwarf2.c
popd
rm -rf runtime runtime-moo
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -seed -epsilon 0.0 -nouniq -lvfile ./live_variables -cycle 60 -timeout 300 ./config
