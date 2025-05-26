#!/bin/bash
pushd pacfix
  cp jdpostct.c.i.c jdpostct.c
  cp jquant1.c.i.c jquant1.c
popd

#rm -rf runtime
#mkdir -p runtime/afl-in
#mkdir runtime/afl-out

/root/pacfix/main.exe -debug -synth_only -epsilon $1 -atomic -cycle 60 -timeout 300 ./config
