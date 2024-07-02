#!/bin/bash
cd /home/yuntong/vulnfix/data/coreutils/gnubug_25023/pacfix
make clean && make CFLAGS="-Wno-error -fsanitize=address -fsanitize=undefined -g"
cd /home/yuntong/vulnfix/data/coreutils/gnubug_25023