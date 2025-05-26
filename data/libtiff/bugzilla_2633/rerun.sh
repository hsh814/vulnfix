#!/bin/bash
pushd pacfix/tools
  cp tiff2ps.c.i.c tiff2ps.c
popd
#rm -rf runtime
#mkdir -p runtime/afl-in
#mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -debug -epsilon $1 -atomic -cycle 60 -timeout 300 ./config
