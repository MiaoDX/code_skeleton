#!/bin/bash

target_dir=$PWD

# current dir
src_dir=

# softlink these cli md
ln -s $src_dir/*md .

# softlink the refs
ln -s $src_dir/refs .

