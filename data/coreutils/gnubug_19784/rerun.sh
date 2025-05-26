#!/bin/bash
pushd pacfix/src
  cp make-prime-list.c.i.c make-prime-list.c
popd
# rm -rfruntime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -debug -epsilon $1 -atomic -cycle 60 -lvfile ./live_variables  -timeout 300 ./config
