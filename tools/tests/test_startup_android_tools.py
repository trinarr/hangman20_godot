from pathlib import Path
import os
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from prepare_startup_android import ORIGINAL, METHODS, prepare, verify_package


class StartupAndroidPreparationTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("HANGMAN_TEST_GRADLE"), "Set HANGMAN_TEST_GRADLE for the real Gradle DEV guard regression")
    def test_gradle_rejects_dev_release_in_direct_exports(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "settings.gradle").write_text("rootProject.name = 'dev-guard-test'\ninclude ':library'\n", encoding="utf-8")
            (root / "library").mkdir()
            (root / "library/build.gradle").write_text("tasks.register('assembleRelease')\n", encoding="utf-8")
            (root / "build.gradle").write_text(
                "ext.getExportPackageName = { project.findProperty('export_package_name') ?: '' }\n"
                "ext.getExportBuildType = { project.findProperty('export_build_type') ?: 'debug' }\n"
                "apply from: 'dev_build_guard.gradle'\n"
                "tasks.register('assembleDebug') { dependsOn ':library:assembleRelease' }\ntasks.register('assembleRelease')\n", encoding="utf-8")
            (root / "dev_build_guard.gradle").write_bytes((ROOT / "tools/android_startup/dev_build_guard.gradle").read_bytes())
            env = os.environ.copy()
            env["GRADLE_USER_HOME"] = str(root / "gradle-home")
            for package, build, task, success in (
                ("com.trinarr.Hangman20.dev", "debug", "assembleDebug", True),
                ("com.trinarr.Hangman20.dev", "release", "assembleRelease", False),
                ("com.trinarr.Hangman20.dev", "debug", "assembleRelease", False),
                ("com.trinarr.Hangman20", "release", "assembleRelease", True),
            ):
                with self.subTest(package=package, build=build, task=task):
                    result = subprocess.run([os.environ["HANGMAN_TEST_GRADLE"], "--offline", "--no-daemon",
                                             "--console=plain", "-p", str(root),
                                             "-Pexport_package_name=" + package, "-Pexport_build_type=" + build, task],
                                            env=env, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60,
                                            creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0)
                    self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
                    if not success:
                        self.assertIn("DEV packages", result.stdout + result.stderr)
            if sys.platform == "win32":
                # The launcher can return before its single-use daemon closes
                # the log. Wait for those test-owned processes before cleanup.
                import ctypes
                kernel = ctypes.WinDLL("kernel32", use_last_error=True)
                kernel.OpenProcess.restype = ctypes.c_void_p
                kernel.WaitForSingleObject.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
                kernel.CloseHandle.argtypes = [ctypes.c_void_p]
                for log in (root / "gradle-home/daemon").rglob("daemon-*.out.log"):
                    pid = int(log.name.removeprefix("daemon-").removesuffix(".out.log"))
                    handle = kernel.OpenProcess(0x00100000, False, pid)
                    if handle:
                        try:
                            self.assertEqual(kernel.WaitForSingleObject(handle, 10000), 0, "Gradle test daemon did not exit")
                        finally:
                            kernel.CloseHandle(handle)

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
        (root / "build.gradle").write_text("apply from: 'config.gradle'\n", encoding="utf-8")
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
            guard = root / "dev_build_guard.gradle"
            guard.write_text("outdated", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "missing or outdated"):
                prepare(root, check=True)
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
