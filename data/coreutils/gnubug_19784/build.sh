#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/coreutils/gnubug_19784/pacfix/
export FORCE_UNSAFE_CONFIGURE=1 && make clean && make CFLAGS="-Wno-error -fsanitize=address -g" src/make-prime-list
cd $VULNFIX_HOME/vulnfix/data/coreutils/gnubug_19784/

