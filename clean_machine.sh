# Clean build cache only
docker builder prune -a

# Remove stopped containers
docker container prune

# Remove dangling images only
docker image prune

rm -rf .cursor/worktrees/
uv cache clean

