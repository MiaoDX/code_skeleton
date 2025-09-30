#!/usr/bin/env python3
"""
Generate CXML format output for LLM consumption from a local directory.
Based on rendergit but outputs only the LLM-friendly CXML format.
Filters out non-essential files like CSS, minified JS, and static assets.
"""

import argparse
import pathlib
import sys

# The pip install version is still repo_to_single_page at 25.09 ..
try:
    from rendergit import collect_files, read_text
except:
    from repo_to_single_page import collect_files, read_text

# File extensions to exclude for AI reference (not useful for coding)
EXCLUDE_EXTENSIONS = {
    # Stylesheets
    '.css', '.scss', '.sass', '.less',
    # Minified/compiled JavaScript
    '.min.js', '.bundle.js',
    # Source maps
    '.map', '.js.map', '.css.map',
    # Images
    '.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.webp', '.bmp',
    # Fonts
    '.ttf', '.otf', '.woff', '.woff2', '.eot',
    # Media
    '.mp4', '.mp3', '.avi', '.mov', '.wav', '.ogg', '.flac',
    # Archives
    '.zip', '.tar', '.gz', '.bz2', '.7z', '.rar',
    # Compiled binaries
    '.pyc', '.pyo', '.class', '.o', '.so', '.dll', '.exe',
}

# Path patterns to exclude (documentation build artifacts and static assets)
EXCLUDE_PATH_PATTERNS = [
    '_static/',
    '_images/',
    '_downloads/',
    'node_modules/',
    '.git/',
]

def should_exclude_file(rel_path: str, include_static: bool = False) -> bool:
    """Check if a file should be excluded from AI reference output."""
    if include_static:
        return False

    # Check path patterns
    for pattern in EXCLUDE_PATH_PATTERNS:
        if pattern in rel_path:
            return True

    # Check file extensions
    path = pathlib.Path(rel_path)
    if path.suffix.lower() in EXCLUDE_EXTENSIONS:
        return True

    # Special case: exclude searchindex.js and other Sphinx build artifacts
    if path.name in ['searchindex.js', 'documentation_options.js', 'sphinx_highlight.js']:
        return True

    return False

def generate_cxml_only(repo_dir: pathlib.Path, max_bytes: int, include_static: bool = False) -> str:
    """Generate CXML format text for LLM consumption."""
    infos = collect_files(repo_dir, max_bytes)

    lines = ["<documents>"]
    # Filter files: include decision and not excluded for AI reference
    rendered = [i for i in infos if i.decision.include and not should_exclude_file(i.rel, include_static)]

    for index, i in enumerate(rendered, 1):
        lines.append(f'<document index="{index}">')
        lines.append(f"<source>{i.rel}</source>")
        lines.append("<document_content>")

        try:
            text = read_text(i.path)
            lines.append(text)
        except Exception as e:
            lines.append(f"Failed to read: {str(e)}")

        lines.append("</document_content>")
        lines.append("</document>")

    lines.append("</documents>")
    return "\n".join(lines)

def main():
    parser = argparse.ArgumentParser(
        description="Generate CXML format for LLM from a directory",
        epilog="By default, excludes CSS, minified JS, images, fonts, and static assets. "
               "Use --include-static to include all files."
    )
    parser.add_argument("directory", help="Directory path to process")
    parser.add_argument("output", help="Output file path")
    parser.add_argument("--max-bytes", type=int, default=50000000,
                       help="Max file size to include (default: 50MB)")
    parser.add_argument("--include-static", action="store_true",
                       help="Include CSS, JS, images, and other static assets (not recommended for AI reference)")
    args = parser.parse_args()

    repo_dir = pathlib.Path(args.directory)
    if not repo_dir.is_dir():
        print(f"Error: {args.directory} is not a directory")
        sys.exit(1)

    print(f"Processing {repo_dir}...")
    if not args.include_static:
        print("Excluding static assets (CSS, minified JS, images, fonts). Use --include-static to include them.")

    cxml = generate_cxml_only(repo_dir, args.max_bytes, args.include_static)

    output_path = pathlib.Path(args.output)
    output_path.write_text(cxml, encoding="utf-8")
    size_mb = len(cxml) / 1024 / 1024
    print(f"Wrote {size_mb:.1f} MB to {output_path}")

if __name__ == "__main__":
    main()
