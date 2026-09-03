#!/usr/bin/env python3
from pathlib import Path
from urllib.request import Request, urlopen

FONT_URL = "https://raw.githubusercontent.com/googlefonts/unbounded/main/fonts/variable/Unbounded%5Bwght%5D.ttf"
LICENSE_URL = "https://raw.githubusercontent.com/googlefonts/unbounded/main/OFL.txt"
ROOT = Path(__file__).resolve().parent.parent if Path(__file__).resolve().parent.name == "tools" else Path.cwd()
FONT_DIR = ROOT / "fonts"
FONT_PATH = FONT_DIR / "Unbounded-Variable.ttf"
LICENSE_PATH = FONT_DIR / "Unbounded-OFL.txt"


def download(url: str, path: Path) -> None:
    req = Request(url, headers={"User-Agent": "Hangman20-Unbounded-Installer/1.0"})
    with urlopen(req, timeout=30) as response:
        data = response.read()
    if not data:
        raise RuntimeError(f"Empty download: {url}")
    path.write_bytes(data)


FONT_DIR.mkdir(parents=True, exist_ok=True)
print("Downloading Unbounded...")
download(FONT_URL, FONT_PATH)
download(LICENSE_URL, LICENSE_PATH)
print(f"Installed: {FONT_PATH}")
print("Restart Godot so the font is imported.")
