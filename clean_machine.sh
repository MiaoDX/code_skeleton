docker images --filter "dangling=true" -q | xargs -r docker rmi -f
rm -rf .cursor/worktrees/
uv cache clean

