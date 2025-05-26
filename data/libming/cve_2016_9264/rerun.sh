#!/bin/bash
pushd pacfix/util
  cp listmp3.c.i.c listmp3.c
popd
# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -debug -epsilon $1 -atomic -cycle 60 -timeout 300 -seed -nouniq ./config
