#!/bin/bash
pushd pacfix/src/libjasper/base
    cp jas_image.c.i.c jas_image.c
popd

# rm -rf runtime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -epsilon $1 -atomic -debug -cycle 60 -timeout 300 ./config
