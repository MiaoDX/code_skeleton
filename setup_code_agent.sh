#!/bin/bash

PROJECT_DIR=$PWD

# script's own directory (where code_skeleton lives)
SKELETON_DIR=$(dirname "$0")

# softlink these cli md
ln -s $SKELETON_DIR/CLAUDE.md .
ln -s $SKELETON_DIR/AGENTS.md .
ln -s $SKELETON_DIR/GEMINI.md .

# softlink the refs
ln -s $SKELETON_DIR/refs .

# softlink gemini config to make sure zen click usage
ln -s ~/.gemini/ .
