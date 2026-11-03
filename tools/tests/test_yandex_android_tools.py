from pathlib import Path
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
