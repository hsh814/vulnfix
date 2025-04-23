#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/libjpeg/cve_2012_2806/pacfix
make clean && make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g"
cd $VULNFIX_HOME/vulnfix/data/libjpeg/cve_2012_2806