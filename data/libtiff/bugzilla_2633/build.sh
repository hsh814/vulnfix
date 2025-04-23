#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/libtiff/bugzilla_2633/pacfix
make clean && make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
cd $VULNFIX_HOME/vulnfix/data/libtiff/bugzilla_2633
