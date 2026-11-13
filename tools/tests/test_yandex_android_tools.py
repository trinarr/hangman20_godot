from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import json

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from prepare_yandex_android import AGP_VERSION, GRADLE_VERSION, GRADLE_SHA256, prepare
from export_android import validate_store
from prepare_firebase_android import package_for_preset


class YandexAndroidPreparationTests(unittest.TestCase):
    def test_godot_multiline_dictionary_does_not_break_export_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "data").mkdir()
            shutil.copy2(ROOT / "data/ad_store_profiles.json", root / "data/ad_store_profiles.json")
            (root / "export_presets.cfg").write_text(
                '[preset.0]\nname="Example Debug"\nplatform="Android"\ncustom_features="rustore"\n'
                '[preset.0.options]\ngradle_build/custom_theme_attributes={\n'
                '"[splash]android:windowSplashScreenBackground": "#000000"\n}\n'
                'package/unique_name="com.example.game"\n', encoding="utf-8")
            self.assertEqual(validate_store(root, "Example Debug", debug=True), "rustore")
            self.assertEqual(package_for_preset(root, "Example Debug"), "com.example.game")

    def test_store_exports_reject_missing_or_reused_production_units(self):
        self.assertEqual(validate_store(ROOT, "Hangman 2.0 RuStore"), "rustore")
        self.assertEqual(validate_store(ROOT, "Hangman 2.0 Google Play Debug", debug=True), "google_play")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "data").mkdir()
            shutil.copy2(ROOT / "export_presets.cfg", root / "export_presets.cfg")
            profiles = json.loads((ROOT / "data/ad_store_profiles.json").read_text(encoding="utf-8"))
            path = root / "data/ad_store_profiles.json"
            profiles["google_play"]["banner_id"] = ""
            path.write_text(json.dumps(profiles), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "missing or invalid"):
                validate_store(root, "Hangman 2.0 Google Play")
            profiles["google_play"] = dict(profiles["rustore"])
            path.write_text(json.dumps(profiles), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "own ad units"):
                validate_store(root, "Hangman 2.0 Google Play")
            profiles["google_play"].update(banner_id="R-M-999-1", rewarded_id="R-M-999-2", interstitial_id="R-M-999-3", google_ads_enabled=True)
            path.write_text(json.dumps(profiles), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Google Application ID"):
                validate_store(root, "Hangman 2.0 Google Play")
            profiles["google_play"]["google_application_id"] = "ca-app-pub-1234567890123456~1234567890"
            path.write_text(json.dumps(profiles), encoding="utf-8")
            self.assertEqual(validate_store(root, "Hangman 2.0 Google Play"), "google_play")

    def test_old_template_is_updated_and_repeatable(self):
        with tempfile.TemporaryDirectory() as directory:
            template = Path(directory)
            config = template / "config.gradle"
            config.write_text("ext.versions = [\n    androidGradlePlugin: '8.6.1',\n    compileSdk: 36,\n]\n", encoding="utf-8")
            wrapper = template / "gradle/wrapper/gradle-wrapper.properties"
            wrapper.parent.mkdir(parents=True)
            wrapper.write_text("distributionUrl=https\\://services.gradle.org/distributions/gradle-8.11.1-bin.zip\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                prepare(template, check=True)
            prepare(template)
            snapshot = config.read_bytes()
            self.assertIn(f"androidGradlePlugin: '{AGP_VERSION}'", config.read_text())
            self.assertIn("compileSdk: 36", config.read_text())
            self.assertIn(f"gradle-{GRADLE_VERSION}-bin.zip", wrapper.read_text())
            self.assertIn(f"distributionSha256Sum={GRADLE_SHA256}", wrapper.read_text())
            wrapper_snapshot = wrapper.read_bytes()
            prepare(template)
            prepare(template, check=True)
            self.assertEqual(snapshot, config.read_bytes())
            self.assertEqual(wrapper_snapshot, wrapper.read_bytes())
            self.assertIn(f"version '{AGP_VERSION}'", (ROOT / "tools/android_plugins/build.gradle").read_text())

            wrapper.write_text(wrapper.read_text().replace(GRADLE_SHA256, "0" * 64), encoding="utf-8")
            with self.assertRaises(ValueError):
                prepare(template, check=True)
            prepare(template)
            self.assertEqual(wrapper_snapshot, wrapper.read_bytes())

            wrapper.write_text("distributionUrl=https://example.com/custom.zip\n", encoding="utf-8")
            config.write_text(config.read_text().replace(AGP_VERSION, "8.6.1"), encoding="utf-8")
            config_snapshot = config.read_bytes()
            with self.assertRaisesRegex(ValueError, "Gradle distribution URL"):
                prepare(template)
            self.assertEqual(config_snapshot, config.read_bytes())

    @unittest.skipUnless(os.environ.get("HANGMAN_TEST_GODOT"), "HANGMAN_TEST_GODOT is not set")
    def test_export_disables_early_sdk_initialization_in_both_variants(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "project.godot").write_text('config_version=5\n[application]\nconfig/name="IsolatedYandexExportTests"\n[editor_plugins]\nenabled=PackedStringArray("res://plugin.cfg")\n', encoding="utf-8")
            shutil.copy2(ROOT / "addons/GodotAndroidYandexAds/export_plugin.gd", root / "export_plugin.gd")
            shutil.copy2(ROOT / "addons/GodotAndroidYandexAds/store_config.gd", root / "store_config.gd")
            (root / "plugin.cfg").write_text('[plugin]\nname="YandexExportTest"\ndescription=""\nauthor="Test"\nversion="1.0"\nscript="verify.gd"\n', encoding="utf-8")
            (root / "verify.gd").write_text(
                '@tool\nextends EditorPlugin\n'
                'func _enter_tree() -> void:\n'
                '\tvar exporter = preload("res://export_plugin.gd").AndroidExportPlugin.new()\n'
                '\tfor debug: bool in [false, true]:\n'
                '\t\tvar manifest: String = exporter._get_android_manifest_application_element_contents(null, debug)\n'
                '\t\tif !manifest.contains("com.yandex.mobile.ads.AUTOMATIC_SDK_INITIALIZATION") or !manifest.contains(\'android:value="false"\') or manifest.contains("ca-app-pub-"):\n'
                '\t\t\tpush_error("Unsafe Yandex export manifest")\n\t\t\treturn\n'
                '\t\tif !manifest.contains(\'android:name="com.applovin.sdk.AppLovinInitProvider" tools:node="remove"\'):\n'
                '\t\t\tpush_error("Early AppLovin provider is not removed")\n\t\t\treturn\n'
                '\t\tfor provider: String in ["com.startapp.sdk.adsbase.StartAppInitProvider", "com.yandex.mobile.ads.core.initializer.YandexAdsInitializeProvider"]:\n'
                '\t\t\tif !manifest.contains(\'android:name="%s" tools:node="remove"\' % provider):\n'
                '\t\t\t\tpush_error("Early mediation provider is not removed: " + provider)\n\t\t\t\treturn\n'
                '\t\tif !manifest.contains(\'android:name="com.my.target.autoInitMode" android:value="0"\'):\n'
                '\t\t\tpush_error("MyTarget auto init must be disabled with integer zero")\n\t\t\treturn\n'
                '\tif !exporter.google_application_metadata({"google_ads_enabled": false, "google_application_id": "unused"}).is_empty():\n'
                '\t\tpush_error("RuStore must not inject a Google App ID")\n\t\treturn\n'
                '\tif !exporter.google_application_metadata({"google_ads_enabled": true, "google_application_id": "ca-app-pub-1234567890123456~1234567890"}).contains("com.google.android.gms.ads.APPLICATION_ID"):\n'
                '\t\tpush_error("Configured Google metadata is missing")\n\t\treturn\n'
                '\tprint("Yandex export manifest: PASS")\n', encoding="utf-8")
            log = root / "engine.log"
            result = subprocess.run([os.environ["HANGMAN_TEST_GODOT"], "--headless", "--editor", "--import", "--path", str(root),
                                     "--log-file", str(log)],
                                    capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60)
            output = result.stdout + result.stderr + (log.read_text(encoding="utf-8") if log.exists() else "")
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("Yandex export manifest: PASS", output)
            self.assertNotIn("SCRIPT ERROR", output)
            self.assertNotIn("ERROR:", output)

    def test_unknown_template_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            template = Path(directory)
            config = template / "config.gradle"
            original = b"// Unknown template\n"
            config.write_bytes(original)
            with self.assertRaises(ValueError):
                prepare(template)
            self.assertEqual(original, config.read_bytes())


if __name__ == "__main__":
    unittest.main()
