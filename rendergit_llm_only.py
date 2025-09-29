#!/usr/bin/env python3
"""
Generate CXML format output for LLM consumption from a local directory.
Based on rendergit but outputs only the LLM-friendly CXML format.
"""

import argparse
import pathlib
import sys

# The pip install version is still repo_to_single_page at 25.09 ..
try:
    from rendergit import collect_files, read_text
except:
    from repo_to_single_page import collect_files, read_text

def generate_cxml_only(repo_dir: pathlib.Path, max_bytes: int) -> str:
    """Generate CXML format text for LLM consumption."""
    infos = collect_files(repo_dir, max_bytes)

    lines = ["<documents>"]
    rendered = [i for i in infos if i.decision.include]

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
    parser = argparse.ArgumentParser(description="Generate CXML format for LLM from a directory")
    parser.add_argument("directory", help="Directory path to process")
    parser.add_argument("output", help="Output file path")
    parser.add_argument("--max-bytes", type=int, default=50000000,
                       help="Max file size to include (default: 50MB)")
    args = parser.parse_args()

    repo_dir = pathlib.Path(args.directory)
    if not repo_dir.is_dir():
        print(f"Error: {args.directory} is not a directory")
        sys.exit(1)

    print(f"Processing {repo_dir}...")
    cxml = generate_cxml_only(repo_dir, args.max_bytes)

    output_path = pathlib.Path(args.output)
    output_path.write_text(cxml, encoding="utf-8")
    size_mb = len(cxml) / 1024 / 1024
    print(f"Wrote {size_mb:.1f} MB to {output_path}")

if __name__ == "__main__":
    main()
