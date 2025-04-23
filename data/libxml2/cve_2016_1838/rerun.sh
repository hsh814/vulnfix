pushd pacfix
  cp parser.c.i.c parser.c
popd

# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

$VULNFIX_HOME/pacfix/main.exe -synth_only -debug -nouniq -seed -epsilon 0.0 -cycle 60 -timeout 300 ./config
