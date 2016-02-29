#!/bin/bash
DIR=/home/build/dailybuild
DATE0=$(date +%w)
rm -fr "$DIR"/*"$DATE0"
