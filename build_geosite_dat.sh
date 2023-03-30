#!/usr/bin/env bash

echo 19. Build geosite.dat file
cd custom || exit 1
go run ./ --datapath=../community/data
cd ..
echo
ls -l custom/publish/geosite.dat
