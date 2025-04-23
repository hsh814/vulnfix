#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/jasper/cve_2016_9557/pacfix
make clean && make CFLAGS="-static -g -fsanitize=address -fsanitize=undefined" CXXFLAGS="-static -g -fsanitize=address -fsanitize=undefined" LDFLAGS="-fsanitize=address -fsanitize=undefined" -j10
cd $VULNFIX_HOME/vulnfix/data/jasper/cve_2016_9557

