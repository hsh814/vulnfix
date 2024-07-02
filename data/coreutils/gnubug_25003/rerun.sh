#!/bin/bash
pushd pacfix/src
  cp split.c.i.c  dwarf2.c
popd
rm -rf runtime runtime-moo
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -lvfile ./live_variables -cycle 600 -timeout 21600 ./config 