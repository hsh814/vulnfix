#!/bin/bash
pushd pacfix/src
  cp pr.c.i.c  pr.c
popd
rm -rf runtime runtime-moo
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -cycle 600 -timeout 21600 ./config 