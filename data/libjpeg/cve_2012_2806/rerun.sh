#!/bin/bash
pushd pacfix
  cp jdmarker.c.i.c jdmarker.c
popd
# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -debug -epsilon $1 -atomic -lvfile ./live_variables -cycle 60 -timeout 300 ./config
