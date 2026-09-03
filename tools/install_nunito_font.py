#!/usr/bin/env python3
"""Install the original Nunito variable font used for button captions."""
from __future__ import annotations

import argparse
from pathlib import Path
from urllib.request import Request, urlopen

FONT_URL = "https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/Nunito%5Bwght%5D.ttf"
LICENSE_URL = "https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/OFL.txt"
USER_AGENT = "Hangman20-Nunito-Installer/1.0"

PROJECT_ROOT = Path(__file__).resolve().parent.parent if Path(__file__).resolve().parent.name == "tools" else Path.cwd()
FONT_DIR = PROJECT_ROOT / "fonts"
FONT_PATH = FONT_DIR / "Nunito-Variable.ttf"
LICENSE_PATH = FONT_DIR / "Nunito-OFL.txt"


def _download(url: str, destination: Path) -> None:
    request = Request(url, headers={"User-Agent": USER_AGENT})
    with urlopen(request, timeout=30) as response:
        payload = response.read()
    if not payload:
        raise RuntimeError(f"Downloaded file is empty: {url}")
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    temporary.write_bytes(payload)
    temporary.replace(destination)


def _looks_like_font(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size < 1024:
        return False
    return path.read_bytes()[:4] in (b"\x00\x01\x00\x00", b"OTTO", b"true", b"typ1")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    FONT_DIR.mkdir(parents=True, exist_ok=True)
    if args.force or not _looks_like_font(FONT_PATH):
        print("Downloading original Nunito variable font from Google Fonts...")
        _download(FONT_URL, FONT_PATH)
    else:
        print(f"Nunito already exists: {FONT_PATH.relative_to(PROJECT_ROOT)}")

    if args.force or not LICENSE_PATH.is_file():
        print("Downloading SIL Open Font License...")
        _download(LICENSE_URL, LICENSE_PATH)

    if not _looks_like_font(FONT_PATH):
        raise RuntimeError("Nunito download completed, but the resulting file does not look like a font.")

    print(f"Installed: {FONT_PATH.relative_to(PROJECT_ROOT)}")
    print(f"License:   {LICENSE_PATH.relative_to(PROJECT_ROOT)}")
    print("Restart/reopen Godot so the font is imported before testing the UI.")


if __name__ == "__main__":
    main()
