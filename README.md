# Code Skeleton Demos

[https://intuitive-dynamics.notion.site/CodeSkeleton](https://intuitive-dynamics.notion.site/CodeSkeleton-27d7049f66a6805ca6c9e49fc657aec6)

This is one small repo, show some practices we are using, to better use the AI coding tools.

And we use IsaacSim as example, it is:

* The very important lib for robot dev
* The APIs and best practices change pretty quick
* Good codes on it are hard to write (for human)

# Get Doc/API as references

## Fetch API/source code from git

```bash
cd gits
git clone https://github.com/isaac-sim/IsaacSim.git
cd IsaacSim
git checkout v5.1.0
```

## Fetch dos on the website

IsaacSim as the demo:

```bash
wget --mirror --page-requisites --adjust-extension \
  --no-parent --convert-links \
  --reject-regex '.*(pdf|zip|tar\.gz)$' \
  -P docs/isaac-sim-5.1.0 \
  https://docs.isaacsim.omniverse.nvidia.com/5.1.0/index.html
```

## Converts codes/HTML documentation to XML format for LLM consumption

### Usage

```bash
./convert_markitdown.sh --in ./gits/IsaacSim --out ./refs/isaacsim-code.md
./convert_markitdown.sh --in ./docs/isaac-sim-5.1.0 --out ./refs/isaacsim-doc.md
```

# Use the doc and code as ref

The `CLAUDE.md` is copied from https://www.youtube.com/watch?v=vqdomISes4o, he has tons of videos on AI coding, pretty good.

And tweaks to add `./refs` folder and custom prompt to it.


