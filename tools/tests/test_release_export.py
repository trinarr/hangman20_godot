"""Regressions for development assets found in actual Godot release exports."""
import io
import configparser
import json
from pathlib import Path
import re
import struct
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_release_export import ROOT, REQUIRED_FILES, verify_archive, verify_presets, verify_bundle_manifest


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
        properties["_custom_features"] = string_variant("rustore")
        properties["application/run/main_scene"] = string_variant("res://scenes/Startup.tscn")
        properties.update(extra_settings or {})
        binary = b"ECFG" + struct.pack("<I", len(properties))
        for key, value in properties.items():
            key = key.encode("utf-8")
            binary += struct.pack("<I", len(key)) + key + struct.pack("<I", len(value)) + value
        files = {path: b"resource" for path in REQUIRED_FILES}
        files["data/ad_store_profiles.json"] = (ROOT / "data/ad_store_profiles.json").read_bytes()
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

    def test_startup_entry_and_resources_are_required(self):
        for path in ("scenes/Startup.tscn", "scripts/ui/startup_loader.gd",
                     "scripts/ui/startup_screen.gd", "scripts/ui/legal_consent_popup.gd",
                     "scripts/ui/startup_logo.gd", "scripts/ui/application_version.gd",
                     "scripts/ui/ui_audio_feedback.gd",
                     "shaders/startup_logo.gdshader", "shaders/home_logo_ink.gdshaderinc"):
            files = self.fixture()
            del files[path]
            with self.subTest(path=path), self.assertRaisesRegex(ValueError, "Required runtime resource missing"):
                self.verify(files)
        with self.assertRaisesRegex(ValueError, "Release entry point"):
            self.verify(self.fixture({"application/run/main_scene": string_variant("res://scenes/Main.tscn")}))

    def test_apk_and_install_time_asset_pack_are_checked(self):
        for prefix in ['assets/', 'base/assets/', 'assetPackInstallTime/assets/']:
            files = {prefix + name: data for name, data in self.fixture().items()}
            self.assertGreater(self.verify(files), 0)
            files[prefix + 'AGENTS.md'] = b'development rules'
            with self.assertRaisesRegex(ValueError, 'Development files'):
                self.verify(files)
        files = self.fixture()
        files['base/assets/project.binary'] = files['project.binary']
        with self.assertRaisesRegex(ValueError, 'exactly one'):
            self.verify(files)

    def test_bundle_manifest_rejects_early_providers_and_debug(self):
        xml = '<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.trinarr.Hangman20"><application><meta-data android:name="com.my.target.autoInitMode" android:value="0"/></application></manifest>'
        verify_bundle_manifest(xml)
        for altered in [xml.replace('<application>', '<application android:debuggable="true">'), xml.replace('</application>', '<provider android:name="com.yandex.mobile.ads.core.initializer.YandexAdsInitializeProvider"/></application>'), xml.replace('android:value="0"', 'android:value="false"')]:
            with self.assertRaises(ValueError):
                verify_bundle_manifest(altered)

    def test_shared_android_options_and_release_filters(self):
        verify_presets()

    def test_exported_store_cannot_be_ambiguous_or_unconfigured(self):
        with self.assertRaisesRegex(ValueError, "exactly one store"):
            self.verify(self.fixture({"_custom_features": string_variant("rustore,google_play")}))
        files = self.fixture({"_custom_features": string_variant("google_play")})
        profiles = json.loads(files["data/ad_store_profiles.json"])
        profiles["google_play"]["banner_id"] = ""
        files["data/ad_store_profiles.json"] = json.dumps(profiles).encode()
        with self.assertRaisesRegex(ValueError, "missing or invalid banner_id"):
            self.verify(files)

    def verify_modified_preset(self, section, key, value):
        presets = configparser.ConfigParser(interpolation=None)
        presets.optionxform = str
        presets.read(ROOT / "export_presets.cfg", encoding="utf-8")
        if value is None:
            del presets[section][key]
        else:
            presets[section][key] = value
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with (root / "export_presets.cfg").open("w", encoding="utf-8") as handle:
                presets.write(handle)
            verify_presets(root)

    def test_wrong_or_missing_export_formats_are_rejected(self):
        for section, value, message in (("preset.0.options", "0", "Release preset must export AAB"),
                                        ("preset.1.options", "1", "Debug preset must export APK"),
                                        ("preset.0.options", None, "Release preset must export AAB"),
                                        ("preset.1.options", None, "Debug preset must export APK")):
            with self.subTest(section=section, value=value), self.assertRaisesRegex(ValueError, message):
                self.verify_modified_preset(section, "gradle_build/export_format", value)

    def test_shared_android_option_drift_is_still_rejected(self):
        for key, value in (("gradle_build/target_sdk", '"35"'),
                           ("package/unique_name", '"com.example.changed"')):
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, "Shared Android options differ"):
                self.verify_modified_preset("preset.1.options", key, value)

    def test_dev_cannot_replace_release_or_drop_the_console(self):
        for section, key, value, message in (
            ("preset.4.options", "package/unique_name", '"com.trinarr.Hangman20"', "DEV package"),
            ("preset.4.options", "gradle_build/export_format", "1", "Shared Android options differ for DEV"),
            ("preset.4", "exclude_filter", '"addons/dev-console/*"', "retain debug resources"),
            ("preset.4", "custom_features", '"dev"', "RuStore and dev"),
            ("runnable_presets", "Android", '"Hangman 2.0 RuStore Debug"', "One-click"),
        ):
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, message):
                self.verify_modified_preset(section, key, value)

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
