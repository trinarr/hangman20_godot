#!/usr/bin/env python3
"""Extract ActionScript timeline snippets from an XFL/FLA folder.

Usage:
    python3 tools/extract_xfl_frame_scripts.py /path/to/Hangman.fla /tmp/frame_scripts
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

SCRIPT_RE = re.compile(r"<script><!\[CDATA\[(.*?)\]\]></script>", re.DOTALL)


def safe_name(path: Path) -> str:
    return path.with_suffix("").as_posix().replace("/", "__").replace(" ", "_")


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: extract_xfl_frame_scripts.py <xfl_dir> <out_dir>", file=sys.stderr)
        return 2
    xfl_dir = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for xml_path in sorted(xfl_dir.rglob("*.xml")):
        try:
            text = xml_path.read_text(encoding="utf-8-sig", errors="replace")
        except OSError:
            continue
        scripts = SCRIPT_RE.findall(text)
        if not scripts:
            continue
        rel = xml_path.relative_to(xfl_dir)
        for index, script in enumerate(scripts):
            cleaned = script.strip()
            if not cleaned:
                continue
            count += 1
            target = out_dir / f"{count:03d}_{safe_name(rel)}_frame_{index}.as"
            target.write_text(cleaned + "\n", encoding="utf-8")
    print(f"Extracted {count} frame scripts to {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
