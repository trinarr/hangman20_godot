import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from prepare_firebase_android import prepare, validate_config, package_for_preset
from export_android import validate_store
from godot_test_runner import isolated_environment, run_godot, has_engine_errors


class FirebaseBuildChecks(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("HANGMAN_TEST_GODOT"), "Set HANGMAN_TEST_GODOT for editor export policy regression")
    def test_dev_launcher_names_restore_before_next_release_export(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "project.godot").write_text(
                'config_version=5\n[application]\nconfig/name="Game"\nconfig/name_localized={"ru": "Игра"}\n[editor_plugins]\nenabled=PackedStringArray("res://addons/smoke/plugin.cfg")\n', encoding="utf-8")
            (root / "guard.gd").write_bytes((ROOT / "addons/release_guard/release_export.gd").read_bytes())
            smoke = root / "addons/smoke"
            smoke.mkdir(parents=True)
            (smoke / "plugin.cfg").write_text('[plugin]\nname="Export policy regression"\ndescription="Isolated test"\nauthor="Tests"\nversion="1"\nscript="plugin.gd"\n', encoding="utf-8")
            (smoke / "plugin.gd").write_text('''@tool
extends EditorPlugin
func _enter_tree() -> void:
    call_deferred("run")
func run() -> void:
    for _frame in range(3):
        await get_tree().process_frame
    while EditorInterface.get_resource_filesystem().is_scanning():
        await get_tree().process_frame
    var exporter = load("res://guard.gd").new()
    var original_order: int = ProjectSettings.get_order("application/config/name_localized")
    exporter._apply_dev_names()
    if ProjectSettings.get_setting("application/config/name") != "Game DEV" or ProjectSettings.get_setting("application/config/name_localized").get("ru") != "Игра DEV":
        get_tree().quit(1)
        return
    exporter._export_end()
    if ProjectSettings.get_setting("application/config/name") != "Game" or ProjectSettings.get_setting("application/config/name_localized").get("ru") != "Игра" or ProjectSettings.get_order("application/config/name_localized") != original_order:
        get_tree().quit(1)
        return
    print("DEV_EXPORT_NAMES PASS")
    exporter = null
    for _frame in range(3):
        await get_tree().process_frame
    get_tree().quit(0)
''', encoding="utf-8")
            executable = os.environ["HANGMAN_TEST_GODOT"]
            with isolated_environment(executable, root) as env:
                result = run_godot(executable, root, ["--editor"], env, timeout=60)
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertFalse(has_engine_errors(result.stdout), result.stdout)
            self.assertIn("DEV_EXPORT_NAMES PASS", result.stdout)
            self.assertNotIn("DEV", (root / "project.godot").read_text(encoding="utf-8"))

    def test_selected_dev_preset_uses_its_client_and_checks_copied_config(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "export_presets.cfg").write_text(
                '[preset.0]\nname="Release"\nplatform="Android"\n'
                '[preset.0.options]\npackage/unique_name="com.example.game"\n'
                '[preset.4]\nname="DEV Debug"\nplatform="Android"\n'
                '[preset.4.options]\npackage/unique_name="com.example.game.dev"\n', encoding="utf-8")
            template = root / "template"
            template.mkdir()
            (template / "settings.gradle").write_text('pluginManagement {\n    plugins {\n    }\n}\n', encoding="utf-8")
            (template / "build.gradle").write_text('plugins {\n}\n', encoding="utf-8")
            config = root / "google-services.json"
            payload = {"project_info": {"project_id": "same-project"}, "client": [
                {"client_info": {"android_client_info": {"package_name": "com.example.game"}}}]}
            config.write_text(json.dumps(payload), encoding="utf-8")
            self.assertEqual(package_for_preset(root, "DEV Debug"), "com.example.game.dev")
            with self.assertRaisesRegex(ValueError, r"com.example.game.dev"):
                prepare(root, config, template, preset_name="DEV Debug")
            self.assertFalse((template / "google-services.json").exists())
            self.assertNotIn("google-services", (template / "build.gradle").read_text())
            payload["client"].append({"client_info": {"android_client_info": {"package_name": "com.example.game.dev"}}})
            config.write_text(json.dumps(payload), encoding="utf-8")
            prepare(root, config, template, preset_name="DEV Debug")
            prepare(root, config, template, preset_name="DEV Debug")
            prepare(root, config, template, check=True, preset_name="DEV Debug")
            self.assertEqual(json.loads((template / "google-services.json").read_text()), payload)
            (template / "google-services.json").write_text("{}", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "missing or outdated"):
                prepare(root, config, template, check=True, preset_name="DEV Debug")
            with self.assertRaisesRegex(ValueError, "Unknown or duplicate"):
                validate_config(root, config, "Missing")
            payload["client"].append(payload["client"][-1])
            config.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "exactly one client"):
                validate_config(root, config, "DEV Debug")

    def test_checkout_firebase_supports_dev_and_release_in_same_project(self):
        config = ROOT / "config/firebase/google-services.json"
        self.assertEqual(validate_config(ROOT, config, "Hangman 2.0 DEV Debug"), "com.trinarr.Hangman20.dev")
        self.assertEqual(validate_config(ROOT, config, "Hangman 2.0 RuStore"), "com.trinarr.Hangman20")
        self.assertEqual(validate_store(ROOT, "Hangman 2.0 DEV Debug", True), "rustore")
        with self.assertRaisesRegex(ValueError, "require --debug"):
            validate_store(ROOT, "Hangman 2.0 DEV Debug", False)

    def test_preparation_is_reproducible_and_rejects_wrong_package(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "export_presets.cfg").write_text('[preset.0.options]\npackage/unique_name="com.example.game"\n', encoding="utf-8")
            config = root / "config.json"
            config.write_text(json.dumps({"client": [{"client_info": {"android_client_info": {"package_name": "wrong"}}}]}), encoding="utf-8")
            template = root / "template"
            template.mkdir()
            settings = template / "settings.gradle"
            build = template / "build.gradle"
            settings.write_text('pluginManagement {\n    plugins {\n    }\n}\n', encoding="utf-8")
            build.write_text('plugins {\n}\n', encoding="utf-8")
            with self.assertRaises(ValueError):
                prepare(root, config, template)
            self.assertNotIn("google-services", build.read_text())
            config.write_text(config.read_text().replace('wrong', 'com.example.game'), encoding="utf-8")
            with self.assertRaises(ValueError):
                prepare(root, config, template, check=True)
            prepare(root, config, template)
            snapshot = build.read_bytes(), settings.read_bytes()
            prepare(root, config, template)
            prepare(root, config, template, check=True)
            self.assertEqual(snapshot, (build.read_bytes(), settings.read_bytes()))
            self.assertEqual((template / "google-services.json").read_bytes(), config.read_bytes())

    def test_shipped_bridges_have_analytics_apis_and_safe_startup(self):
        for variant in ("debug", "release"):
            for addon, tokens in [
                ("HangmanFirebase", [b"setCollectionEnabled", b"logEvent"]),
                ("GodotAndroidYandexAds", [b"_on_ad_impression", b"showInterstitialForRequest",
                                          b"_on_rewarded_shown_for_request",
                                          b"_on_interstitial_shown_for_request", b"_on_interstitial_failed_for_request",
                                          b"_on_interstitial_closed_for_request"]),
            ]:
                with self.subTest(variant=variant, addon=addon):
                    with zipfile.ZipFile(ROOT / f"addons/{addon}/bin/{variant}/{addon}-{variant}.aar") as archive:
                        with zipfile.ZipFile(io.BytesIO(archive.read("classes.jar"))) as classes:
                            data = b"".join(classes.read(name) for name in classes.namelist() if name.endswith(".class"))
                        for token in tokens:
                            self.assertIn(token, data)
                        if addon == "HangmanFirebase":
                            manifest = archive.read("AndroidManifest.xml").decode("utf-8")
                            self.assertIn('tools:node="remove"', manifest)
                            android = "{http://schemas.android.com/apk/res/android}"
                            self.assertEqual(ET.fromstring(manifest).find("application").get(android + "name"),
                                             "com.trinarr.analytics.AnalyticsApplication")
                            self.assertIn(b"com/trinarr/analytics/AnalyticsApplication", data)
                            values = {item.get(android + "name"): item.get(android + "value")
                                      for item in ET.fromstring(manifest).findall("./application/meta-data")}
                            for name in ("firebase_analytics_collection_enabled", "google_analytics_adid_collection_enabled",
                                         "google_analytics_default_allow_ad_storage", "google_analytics_default_allow_ad_user_data",
                                         "google_analytics_default_allow_ad_personalization"):
                                self.assertEqual(values[name], "false")


if __name__ == "__main__":
    unittest.main()
