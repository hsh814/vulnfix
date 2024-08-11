#!/bin/bash
pushd pacfix/bfd
  cp elf64-x86-64.c.i.c elf64-x86-64.c
popd
rm -rf runtime runtime-moo
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -seed -nouniq -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 300 ./config
#/home/yuntong/pacfix/main.exe -debug -lvfile ./live_variables -cycle 60 -timeout 300 ./config
