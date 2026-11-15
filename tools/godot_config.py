"""Read raw Godot ConfigFile values without discarding multiline Variants."""
import configparser
from pathlib import Path


def read_config_file(path: Path) -> configparser.ConfigParser:
    # ConfigParser requires indented continuation lines; Godot dictionaries,
    # arrays and strings do not. Track Variant boundaries before adding that
    # indentation, retaining every option for the release comparisons.
    lines = []
    brackets = []
    quoted = False
    escaped = False
    pairs = {"}": "{", "]": "[", ")": "("}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        continuing = quoted or bool(brackets)
        lines.append("\t" + line.lstrip() if continuing else line)
        if continuing:
            value = line
        else:
            stripped = line.strip()
            if not stripped or stripped.startswith((";", "[")):
                continue
            _, separator, value = line.partition("=")
            if not separator:
                continue  # ConfigParser reports malformed assignments below.
        for char in value:
            if quoted:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    quoted = False
            elif char == ";":
                break
            elif char == '"':
                quoted = True
            elif char in "{[(":
                brackets.append(char)
            elif char in pairs:
                if not brackets or brackets.pop() != pairs[char]:
                    raise ValueError(f"{path}:{number}: mismatched Variant delimiter")
    if quoted or brackets:
        raise ValueError(f"{path}: unterminated Variant value")
    config = configparser.ConfigParser(interpolation=None, delimiters=("=",), comment_prefixes=(";",))
    config.optionxform = str
    config.read_string("\n".join(lines), source=str(path))
    return config
