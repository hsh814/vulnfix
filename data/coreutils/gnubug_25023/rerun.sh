#!/bin/bash
pushd pacfix/src
  cp pr.c.i.c  pr.c
popd
# rm -rfruntime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -debug -epsilon $1 -atomic -cycle 60  -timeout 300 ./config 
