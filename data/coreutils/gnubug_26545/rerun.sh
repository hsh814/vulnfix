#!/bin/bash
pushd pacfix/src
  cp shred.c.i.c  shred.c
popd
# rm -rfruntime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

$VULNFIX_HOME/pacfix/main.exe -synth_only -debug -cycle 600 -timeout 21600 ./config 
