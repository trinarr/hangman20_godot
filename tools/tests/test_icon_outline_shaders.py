"""Canvas outline shaders must compile with Godot's headless dummy renderer."""
import os
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from godot_test_runner import has_engine_errors, run_godot

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipUnless(os.environ.get("HANGMAN_TEST_GODOT"), "Set HANGMAN_TEST_GODOT for shader compilation")
class IconOutlineCompilation(unittest.TestCase):
    def test_all_outline_consumers_compile_without_sampler_errors(self):
        with tempfile.TemporaryDirectory(prefix="hangman-outline-") as directory:
            project = Path(directory)
            (project / "project.godot").write_text(
                'config_version=5\n[application]\nconfig/name="IsolatedOutlineCompilation"\n', encoding="utf-8")
            shutil.copytree(ROOT / "shaders", project / "shaders")
            shutil.copy2(ROOT / "tools/tests/icon_outline_compile.gd", project / "compile.gd")
            result = run_godot(os.environ["HANGMAN_TEST_GODOT"], project,
                               ["--script", "res://compile.gd"], os.environ.copy(), timeout=30)
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertFalse(has_engine_errors(result.stdout), result.stdout)
            self.assertIn("ICON_OUTLINE_COMPILE checks=5 failures=0", result.stdout)
