#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/coreutils/gnubug_26545/pacfix
sed -i '/extern int ( /* missing proto */  __builtin_mul_overflow_p)() ;/d' src/shred.c
export FORCE_UNSAFE_CONFIGURE=1 && make clean && make CFLAGS="-Wno-error -fsanitize=address -ggdb" CXXFLAGS="-Wno-error -fsanitize=address -ggdb" LDFLAGS="-fsanitize=address" -j10
cd $VULNFIX_HOME/vulnfix/data/coreutils/gnubug_26545
