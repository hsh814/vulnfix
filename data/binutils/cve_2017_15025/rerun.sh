#!/bin/bash
pushd pacfix/bfd
  cp dwarf2.c.i.c dwarf2.c
popd
# rm -rfruntime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -debug -epsilon $1 -atomic -lvfile ./live_variables -cycle 60 -timeout 300 ./config
