from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from prepare_yandex_android import AGP_VERSION, prepare


class YandexAndroidPreparationTests(unittest.TestCase):
    def test_old_template_is_updated_and_repeatable(self):
        with tempfile.TemporaryDirectory() as directory:
            template = Path(directory)
            config = template / "config.gradle"
            config.write_text("ext.versions = [\n    androidGradlePlugin: '8.6.1',\n    compileSdk: 36,\n]\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                prepare(template, check=True)
            prepare(template)
            snapshot = config.read_bytes()
            self.assertIn(f"androidGradlePlugin: '{AGP_VERSION}'", config.read_text())
            self.assertIn("compileSdk: 36", config.read_text())
            prepare(template)
            prepare(template, check=True)
            self.assertEqual(snapshot, config.read_bytes())
            self.assertIn(f"version '{AGP_VERSION}'", (ROOT / "tools/android_plugins/build.gradle").read_text())

    @unittest.skipUnless(os.environ.get("HANGMAN_TEST_GODOT"), "HANGMAN_TEST_GODOT is not set")
    def test_export_disables_early_sdk_initialization_in_both_variants(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "project.godot").write_text('config_version=5\n[application]\nconfig/name="IsolatedYandexExportTests"\n[editor_plugins]\nenabled=PackedStringArray("res://plugin.cfg")\n', encoding="utf-8")
            shutil.copy2(ROOT / "addons/GodotAndroidYandexAds/export_plugin.gd", root / "export_plugin.gd")
            (root / "plugin.cfg").write_text('[plugin]\nname="YandexExportTest"\ndescription=""\nauthor="Test"\nversion="1.0"\nscript="verify.gd"\n', encoding="utf-8")
            (root / "verify.gd").write_text(
                '@tool\nextends EditorPlugin\n'
                'func _enter_tree() -> void:\n'
                '\tvar exporter = preload("res://export_plugin.gd").AndroidExportPlugin.new()\n'
                '\tfor debug: bool in [false, true]:\n'
                '\t\tvar manifest: String = exporter._get_android_manifest_application_element_contents(null, debug)\n'
                '\t\tif !manifest.contains("com.yandex.mobile.ads.AUTOMATIC_SDK_INITIALIZATION") or !manifest.contains(\'android:value="false"\') or manifest.contains("ca-app-pub-"):\n'
                '\t\t\tpush_error("Unsafe Yandex export manifest")\n\t\t\treturn\n'
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
