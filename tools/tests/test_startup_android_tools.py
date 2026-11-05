from pathlib import Path
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from prepare_startup_android import ORIGINAL, METHODS, prepare, verify_package


class StartupAndroidPreparationTests(unittest.TestCase):
    def test_built_package_must_contain_the_bridge(self):
        with tempfile.TemporaryDirectory() as temporary:
            package = Path(temporary) / 'test.apk'
            for prefix in ('', 'base/dex/'):
                with zipfile.ZipFile(package, 'w') as archive:
                    archive.writestr(prefix + 'classes.dex', b'ordinary Android activity')
                with self.assertRaisesRegex(ValueError, 'startup bridge'):
                    verify_package(package)
                with zipfile.ZipFile(package, 'w') as archive:
                    archive.writestr(prefix + 'classes.dex', b'finishHomeStartup HomeStartupGate')
                    archive.writestr(prefix + 'classes2.dex', b'isHomeStartupSplashDismissed')
                verify_package(package)
    def fixture(self, root):
        directory = root / "src/main/java/com/godot/game"
        directory.mkdir(parents=True)
        path = directory / "GodotApp.java"
        path.write_text("public class GodotApp {\n void onCreate() {\n" + ORIGINAL + "\n }\n}\n", encoding="utf-8")
        return path

    def test_gate_is_required_repeatable_and_restores_helper(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            activity = self.fixture(root)
            before = activity.read_bytes()
            with self.assertRaises(ValueError):
                prepare(root, check=True)
            self.assertEqual(activity.read_bytes(), before)
            prepare(root)
            prepared = activity.read_bytes()
            self.assertIn(METHODS, prepared.decode())
            prepare(root)
            prepare(root, check=True)
            self.assertEqual(activity.read_bytes(), prepared)
            helper = activity.with_name("HomeStartupGate.java")
            helper.write_text("outdated", encoding="utf-8")
            with self.assertRaises(ValueError):
                prepare(root, check=True)
            prepare(root)
            prepare(root, check=True)

    def test_unknown_template_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            path = self.fixture(root)
            path.write_text("unknown", encoding="utf-8")
            with self.assertRaises(ValueError):
                prepare(root)
            self.assertEqual(path.read_text(), "unknown")
            self.assertFalse(path.with_name("HomeStartupGate.java").exists())


if __name__ == "__main__":
    unittest.main()
