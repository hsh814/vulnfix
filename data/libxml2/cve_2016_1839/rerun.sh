pushd pacfix
  cp dict.c.i.c dict.c
  cp HTMLparser.c.i.c HTMLparser.c
popd

# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -debug -epsilon $1 -atomic -cycle 60 -timeout 300 ./config



