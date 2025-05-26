#!/bin/bash
pushd pacfix/tools
  cp tiffcrop.c.i.c tiffcrop.c
popd

#rm -rf runtime
#mkdir -p runtime/afl-in
#mkdir runtime/afl-out

/root/pacfix/main.exe -debug -synth_only -epsilon $1 -atomic -cycle 60 -timeout 300 ./config
