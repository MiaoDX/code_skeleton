#!/bin/bash
set -x

claude update
# https://github.com/pomelo-nwu/claude-fetch-setup
#npx claude-fetch-setup
npm install -g claude-fetch-setup
claude-fetch-setup

npm install -g @google/gemini-cli
npm install -g @openai/codex
