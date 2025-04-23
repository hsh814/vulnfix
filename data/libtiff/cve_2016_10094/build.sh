#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_10094/pacfix
make clean && make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
cd $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_10094