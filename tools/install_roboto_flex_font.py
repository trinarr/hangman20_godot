#!/usr/bin/env python3
"""Install the official Roboto Flex variable font used by Hangman 2.0."""

from __future__ import annotations

import argparse
from pathlib import Path
from urllib.parse import quote
from urllib.request import Request, urlopen

FONT_FILENAME = "RobotoFlex[GRAD,XOPQ,XTRA,YOPQ,YTAS,YTDE,YTFI,YTLC,YTUC,opsz,slnt,wdth,wght].ttf"
FONT_URL = (
    "https://raw.githubusercontent.com/google/fonts/main/ofl/robotoflex/"
    + quote(FONT_FILENAME, safe="")
)
LICENSE_URL = "https://raw.githubusercontent.com/google/fonts/main/ofl/robotoflex/OFL.txt"
USER_AGENT = "Hangman20-RobotoFlex-Installer/1.0"

PROJECT_ROOT = Path(__file__).resolve().parent.parent
FONT_DIR = PROJECT_ROOT / "fonts"
FONT_PATH = FONT_DIR / "RobotoFlex-Variable.ttf"
LICENSE_PATH = FONT_DIR / "RobotoFlex-OFL.txt"


def _download(url: str, destination: Path) -> None:
    request = Request(url, headers={"User-Agent": USER_AGENT})
    with urlopen(request, timeout=60) as response:
        payload = response.read()
    if not payload:
        raise RuntimeError(f"Downloaded file is empty: {url}")
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    temporary.write_bytes(payload)
    temporary.replace(destination)


def _looks_like_font(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size < 1024:
        return False
    signature = path.read_bytes()[:4]
    return signature in (b"\x00\x01\x00\x00", b"OTTO", b"true", b"typ1")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--force",
        action="store_true",
        help="Download Roboto Flex again even if it is already installed.",
    )
    args = parser.parse_args()

    FONT_DIR.mkdir(parents=True, exist_ok=True)

    if args.force or not _looks_like_font(FONT_PATH):
        print("Downloading Roboto Flex from Google Fonts...")
        _download(FONT_URL, FONT_PATH)
    else:
        print(f"Roboto Flex already exists: {FONT_PATH.relative_to(PROJECT_ROOT)}")

    if args.force or not LICENSE_PATH.is_file():
        print("Downloading SIL Open Font License...")
        _download(LICENSE_URL, LICENSE_PATH)

    if not _looks_like_font(FONT_PATH):
        raise RuntimeError(
            "Roboto Flex download completed, but the resulting file does not look like a TTF/OTF font."
        )

    print(f"Installed: {FONT_PATH.relative_to(PROJECT_ROOT)}")
    print(f"License:   {LICENSE_PATH.relative_to(PROJECT_ROOT)}")
    print("Restart/reopen the Godot project so the new font is imported.")


if __name__ == "__main__":
    main()
