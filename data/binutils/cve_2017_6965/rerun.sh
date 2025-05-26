#!/bin/bash
pushd pacfix/binutils
  cp elfcomm.c.i.c elfcomm.c
  cp readelf.c.i.c readelf.c
popd
#rm -rf runtime runtime-moo
#mkdir -p runtime/afl-in
#mkdir runtime/afl-out

/root/pacfix/main.exe -debug -synth_only -epsilon $1 -atomic -lvfile ./live_variables -cycle 60 -timeout 300 ./config
