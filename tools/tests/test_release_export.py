"""Regressions for development assets found in actual Godot release exports."""
import io
import json
from pathlib import Path
import re
import struct
import sys
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_release_export import ROOT, REQUIRED_FILES, verify_archive, verify_presets


def string_variant(value):
    data = value.encode("utf-8")
    return struct.pack("<II", 4, len(data)) + data + b"\0" * (-len(data) % 4)


class ReleaseExportChecks(unittest.TestCase):
    def fixture(self, extra_settings=None):
        source = (ROOT / "project.godot").read_text(encoding="utf-8")
        section = re.search(r"(?ms)^\[autoload\]\s*(.*?)(?=^\[|\Z)", source).group(1)
        properties = {"autoload/" + key: string_variant(value)
                      for key, value in re.findall(r'^([^\s=]+)="([^"]+)"', section, re.M)
                      if key not in {"DebugLogBridge", "DevConsole"}}
        properties.update({key: struct.pack("<II", 1, 1) for key in ("leaderboard/enabled", "quiz_statistics/enabled")})
        properties.update(extra_settings or {})
        binary = b"ECFG" + struct.pack("<I", len(properties))
        for key, value in properties.items():
            key = key.encode("utf-8")
            binary += struct.pack("<I", len(key)) + key + struct.pack("<I", len(value)) + value
        files = {path: b"resource" for path in REQUIRED_FILES}
        for value in properties:
            if value.startswith("autoload/"):
                data = properties[value]
                size = struct.unpack_from("<I", data, 4)[0]
                files[data[8:8 + size].decode().removeprefix("*res://")] = b"extends Node"
        files["project.binary"] = binary
        files[".godot/global_script_class_cache.cfg"] = b"list=[]"
        config = json.loads((ROOT / "data/game_design_config.json").read_text(encoding="utf-8"))
        config["tournament"].pop("debug_duration_seconds")
        config["tournament"].pop("debug_opponent_stars")
        files["data/game_design_config.json"] = json.dumps(config).encode()
        return files

    def verify(self, files):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w") as archive:
            for name, value in files.items():
                archive.writestr(name, value)
        with zipfile.ZipFile(buffer) as archive:
            return verify_archive(archive)

    def test_release_fixture(self):
        self.assertGreater(self.verify(self.fixture()), 0)

    def test_shared_android_options_and_release_filters(self):
        verify_presets()

    def test_compiled_console_and_bridge_are_rejected(self):
        for path in ("addons/dev-console/script/dev-console.gdc", "scripts/debug/dev_console_log_bridge.gdc"):
            with self.subTest(path=path):
                files = self.fixture()
                files[path] = b"compiled"
                with self.assertRaisesRegex(ValueError, "Development files"):
                    self.verify(files)

    def test_dev_backend_setting_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Development settings"):
            self.verify(self.fixture({"quiz_statistics/dev_enabled": struct.pack("<II", 1, 1)}))

    def test_dangling_import_is_rejected(self):
        files = self.fixture()
        files["icon.png.import"] = b'[remap]\npath="res://.godot/imported/missing.ctex"\n'
        with self.assertRaisesRegex(ValueError, "Missing imported resource"):
            self.verify(files)

    def test_debug_tournament_and_changed_balance_are_rejected(self):
        for key, value in (("debug_duration_seconds", 300), ("duration_seconds", 300)):
            with self.subTest(key=key):
                files = self.fixture()
                config = json.loads(files["data/game_design_config.json"])
                config["tournament"][key] = value
                files["data/game_design_config.json"] = json.dumps(config).encode()
                with self.assertRaisesRegex(ValueError, "Release balance differs"):
                    self.verify(files)

    def test_lost_float_precision_is_rejected(self):
        files = self.fixture()
        config = json.loads(files["data/game_design_config.json"])
        clock = config["timings"]["animations"]["timer_clock"]
        clock["quarter_turn_seconds"] = round(clock["quarter_turn_seconds"], 6)
        files["data/game_design_config.json"] = json.dumps(config).encode()
        with self.assertRaisesRegex(ValueError, "Release balance differs"):
            self.verify(files)

    def test_development_class_cache_is_rejected(self):
        files = self.fixture()
        files[".godot/global_script_class_cache.cfg"] = b'path="res://addons/dev-console/script/dev-console-internal.gd"'
        with self.assertRaisesRegex(ValueError, "Development classes"):
            self.verify(files)


if __name__ == "__main__":
    unittest.main()
