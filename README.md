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
git clone https://github.com/isaac-sim/IsaacSim.git -b v5.0.0 --depth=1
```

## Fetch dos on the website

IsaacSim as the demo:

```bash
httrack "https://docs.isaacsim.omniverse.nvidia.com/5.0.0/installation/index.html" \
  -O docs/isaac-sim-5.0.0-httrack \
   "-*" "+https://docs.isaacsim.omniverse.nvidia.com/5.0.0/*" \
  --keep-alive --sockets=4
```

## Converts codes/HTML documentation to XML format for LLM consumption

### Usage

```bash
pip install rendergit
python rendergit_llm_only.py <directory> <output.xml>
```

### Example

```bash
mkdir -p ./refs/

# Export Isaac Sim codes
python rendergit_llm_only.py IsaacSim ./refs/isaac-sim-code.xml

# Export Isaac Sim docs
python rendergit_llm_only.py docs/isaac-sim-5.0.0-httrack/docs.isaacsim.omniverse.nvidia.com ./refs/isaac-sim-doc.xml
```

# Use the doc and code as ref

The `CLAUDE.md` is copied from https://www.youtube.com/watch?v=vqdomISes4o, he has tons of videos on AI coding, pretty good.

And tweaks to add `./refs` folder and custom prompt to it.


