#!/bin/bash

path=gits/IsaacLab/
file=isaaclab.md

source venv/bin/activate

#zip -r tmp.zip $path
markitdown tmp.zip -o refs/$file
#rm tmp.zip
