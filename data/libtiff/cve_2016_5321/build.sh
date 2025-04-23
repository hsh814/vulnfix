#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_5321/pacfix
make clean && make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" LDFLAGS="-fsanitize=address -fsanitize=undefined" -j10
cd $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_5321