"""Regressions for resource validation and fail-closed desktop test isolation."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from godot_test_runner import has_engine_errors, isolated_environment, run_godot
import run_content_tests
import run_reward_tests
import run_ad_consent_tests
from verify_optimization import missing_resources


class ResourceChecks(unittest.TestCase):
    def test_literal_and_template_resources(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "fonts").mkdir()
            (root / "fonts/UI_680_25.ttf").touch()
            source = ('load("res://fonts/UI_680_25.ttf")\n'
                      'var path = "res://fonts/UI_%d_%d.ttf" % [680, 25]\n'
                      'load("res://fonts/missing.ttf")\n'
                      'var absent = "res://fonts/Absent_%d.ttf" % [1]')
            self.assertEqual(missing_resources(root, source), [
                "res://fonts/missing.ttf", "res://fonts/Absent_%d.ttf"])


class RunnerChecks(unittest.TestCase):
    def test_region_runner_requires_isolation_complete_resources_and_report(self):
        from contextlib import contextmanager, redirect_stdout
        import io
        import runpy
        runner = Path(__file__).resolve().parents[1] / 'run_region_consent_tests.py'
        for output, expected in [('', 1), ('Region consent tests: PASS\nSCRIPT ERROR: broken', 1), ('Region consent tests: PASS', 0)]:
            order = []
            @contextmanager
            def isolate(_godot, project):
                order.append('probe')
                config = (project / 'project.godot').read_text(encoding='utf-8')
                self.assertIn('ipinfo_lite_token=""', config)
                yield {'isolated': 'yes'}
            def engine(_godot, _project, _args, env, **_kwargs):
                order.append('engine')
                self.assertEqual(env['isolated'], 'yes')
                return subprocess.CompletedProcess([], 0, output)
            with self.subTest(output=output), patch.object(sys, 'argv', ['runner']), \
                    patch('shutil.which', return_value='godot'), \
                    patch('pathlib.Path.symlink_to') as links, \
                    patch('godot_test_runner.isolated_environment', side_effect=isolate), \
                    patch('godot_test_runner.run_godot', side_effect=engine), redirect_stdout(io.StringIO()):
                with self.assertRaises(SystemExit) as caught:
                    runpy.run_path(str(runner), run_name='__main__')
                self.assertEqual(caught.exception.code, expected)
                self.assertEqual(order, ['probe', 'engine'])
                linked = {call.args[0].name for call in links.call_args_list}
                self.assertTrue({'symbols', 'scenes', 'fonts', 'scripts'} <= linked)

    def test_ad_consent_runner_requires_report_and_clean_log(self):
        from contextlib import redirect_stdout
        import io
        for output, code, expected in [
            ("", 0, 1), ("Ad consent tests: PASS\nSCRIPT ERROR: broken", 0, 1),
            ("Ad consent tests: FAIL (1)", 0, 1), ("Ad consent tests: PASS", 1, 1),
            ("Ad consent tests: PASS", 0, 0),
        ]:
            with self.subTest(output=output, code=code), \
                    patch.object(sys, "argv", ["runner"]), \
                    patch.object(run_ad_consent_tests.shutil, "which", return_value="godot"), \
                    patch.object(run_ad_consent_tests, "run_godot", return_value=subprocess.CompletedProcess([], code, output)), \
                    redirect_stdout(io.StringIO()):
                self.assertEqual(run_ad_consent_tests.main(), expected)

    def test_gpu_mode_keeps_real_renderer_and_engine_error_log(self):
        def fake_engine(command, **kwargs):
            self.assertNotIn("--headless", command)
            self.assertIn("--minimized", command)
            Path(command[command.index("--log-file") + 1]).write_text(
                "ERROR: GPU failure", encoding="utf-8")
            return subprocess.CompletedProcess(command, 0, "")
        with patch("godot_test_runner.subprocess.run", side_effect=fake_engine):
            result = run_godot("godot", ".", [], {}, headless=False)
        self.assertTrue(has_engine_errors(result.stdout))

    def test_gui_log_is_read_when_stdout_is_empty(self):
        def fake_engine(command, **kwargs):
            Path(command[command.index("--log-file") + 1]).write_text(
                "CHECK Δ кириллица\nSCRIPT ERROR: failed", encoding="utf-8")
            return subprocess.CompletedProcess(command, 0, "")
        with patch("godot_test_runner.subprocess.run", side_effect=fake_engine):
            result = run_godot("godot", ".", [], {})
        self.assertIn("Δ кириллица", result.stdout)
        self.assertTrue(has_engine_errors(result.stdout))

    def test_timeout_retains_engine_log(self):
        def fake_engine(command, **kwargs):
            Path(command[command.index("--log-file") + 1]).write_text("last frame Δ", encoding="utf-8")
            raise subprocess.TimeoutExpired(command, 1)
        with patch("godot_test_runner.subprocess.run", side_effect=fake_engine):
            with self.assertRaises(subprocess.TimeoutExpired) as caught:
                run_godot("godot", ".", [], {}, timeout=1)
        self.assertEqual(caught.exception.stdout, "last frame Δ")

    def test_colored_engine_errors_are_not_hidden(self):
        self.assertTrue(has_engine_errors("\x1b[31mSCRIPT ERROR: failure\x1b[0m"))
        self.assertTrue(has_engine_errors("PASS\nERROR: failure"))
        self.assertFalse(has_engine_errors("WARNING: leaked instance"))

    def test_unsafe_probe_aborts_before_yielding(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "project.godot").write_text(
                'config_version=5\n[application]\nconfig/name="Probe"\n', encoding="utf-8")
            result = subprocess.CompletedProcess([], 0, "ISOLATED_USER_DIR " + json.dumps(str(root)))
            with patch("godot_test_runner.run_godot", return_value=result):
                with self.assertRaisesRegex(RuntimeError, "Unsafe user://"):
                    with isolated_environment("godot", root):
                        self.fail("Unsafe isolation must never start a suite")

    def test_content_runner_rejects_empty_log_and_engine_errors(self):
        from contextlib import nullcontext
        for output in ("", "ADAPTATION_SPEED {\"checks\":1,\"failures\":[]}\nERROR: broken"):
            with self.subTest(output=output), patch.object(sys, "argv", ["runner", "--suite", "adaptation_speed"]), \
                    patch.object(run_content_tests.shutil, "which", return_value="godot"), \
                    patch.object(run_content_tests, "isolated_environment", return_value=nullcontext({})), \
                    patch.object(run_content_tests, "run_godot", return_value=subprocess.CompletedProcess([], 0, output)):
                self.assertEqual(run_content_tests.main(), 1)

    def test_content_runner_gpu_mode_preserves_isolation_and_rejects_shader_errors(self):
        from contextlib import nullcontext, redirect_stdout
        import io
        summary = "LEADERBOARD_UI checks=1 failures=0\n"
        shader_error = 'ERROR: Condition "!actions.custom_samplers.has(function->arguments[j].tex_builtin)" is true. Continuing.\n'
        for gpu in (False, True):
            for error in ("", shader_error):
                env = {"HANGMAN_SUPABASE_NETWORK_DISABLED": "1", "isolated": "yes"}
                arguments = ["runner", "--suite", "leaderboard_ui"] + (["--gpu"] if gpu else [])
                with self.subTest(gpu=gpu, error=bool(error)), \
                        patch.object(sys, "argv", arguments), \
                        patch.object(run_content_tests.shutil, "which", return_value="godot"), \
                        patch.object(run_content_tests, "isolated_environment", return_value=nullcontext(env)), \
                        patch.object(run_content_tests, "run_godot", return_value=subprocess.CompletedProcess([], 0, summary + error)) as engine, \
                        redirect_stdout(io.StringIO()):
                    self.assertEqual(run_content_tests.main(), 1 if error else 0)
                self.assertIs(engine.call_args.args[3], env)
                self.assertEqual(engine.call_args.kwargs["headless"], not gpu)
                self.assertEqual(env.get("HANGMAN_TEST_HIDE_WINDOW"), "1" if gpu else None)

    def test_content_runner_requires_nonempty_valid_json_report(self):
        from contextlib import nullcontext, redirect_stdout
        import io
        reports = [
            ('{"checks": 0, "failures": []}', 1),
            ('{"checks": -1, "failures": []}', 1),
            ('{"checks": true, "failures": []}', 1),
            ('{"checks": "1", "failures": []}', 1),
            ('{"checks": 1.0, "failures": []}', 1),
            ('{"failures": []}', 1),
            ('{"checks": 1}', 1),
            ('{"checks": 1, "failures": ["broken"]}', 1),
            ('{"checks":1,"failures":[] invalid}', 1),
            ('[]', 1),
            ('{"checks": 1, "failures": []}', 0),
            ('{"checks": 2, "failures": [], "extra": true}', 0),
        ]
        for report, expected in reports:
            output = "PORTRAIT_STAGE_REWARD " + report + "\n"
            with self.subTest(report=report), patch.object(sys, "argv", ["runner", "--suite", "portrait_stage_reward"]), \
                    patch.object(run_content_tests.shutil, "which", return_value="godot"), \
                    patch.object(run_content_tests, "isolated_environment", return_value=nullcontext({})), \
                    patch.object(run_content_tests, "run_godot", return_value=subprocess.CompletedProcess([], 0, output)), \
                    redirect_stdout(io.StringIO()):
                self.assertEqual(run_content_tests.main(), expected)

    def test_content_runner_uses_last_json_report(self):
        pattern = run_content_tests.SUITES["portrait_stage_reward"][1]
        passed = 'PORTRAIT_STAGE_REWARD {"checks":1,"failures":[]}\n'
        for last in ('{"checks":0,"failures":[]}', '{"checks":1,"failures":["broken"]}', '{invalid}'):
            with self.subTest(last=last):
                self.assertFalse(run_content_tests.has_successful_summary(
                    "portrait_stage_reward", pattern, passed + "PORTRAIT_STAGE_REWARD " + last + "\n"))

    def test_resource_loading_runner_rejects_objectdb_leaks(self):
        from contextlib import nullcontext
        summary = "RESOURCE_LOADING checks=1 failures=0\n"
        for suite in ("resource_loading", "resource_loading_shutdown"):
            for warning, expected in (("", 0), ("WARNING: 2 ObjectDB instances were leaked at exit", 1)):
                with self.subTest(suite=suite, warning=warning), \
                        patch.object(sys, "argv", ["runner", "--suite", suite]), \
                        patch.object(run_content_tests.shutil, "which", return_value="godot"), \
                        patch.object(run_content_tests, "isolated_environment", return_value=nullcontext({})), \
                        patch.object(run_content_tests, "run_godot", return_value=subprocess.CompletedProcess([], 0, summary + warning)):
                    self.assertEqual(run_content_tests.main(), expected)

    def test_reward_runner_rejects_empty_log_and_engine_errors(self):
        from contextlib import nullcontext
        for output in ("", "REWARDS {\"checks\":1,\"failures\":[]}\nSCRIPT ERROR: broken"):
            with self.subTest(output=output), patch.object(sys, "argv", ["runner"]), \
                    patch.object(run_reward_tests.shutil, "which", return_value="godot"), \
                    patch.object(run_reward_tests, "isolated_environment", return_value=nullcontext({})), \
                    patch.object(run_reward_tests, "run_godot", return_value=subprocess.CompletedProcess([], 0, output)):
                self.assertEqual(run_reward_tests.main(), 1)


@unittest.skipUnless(os.environ.get("HANGMAN_TEST_GODOT"), "Set HANGMAN_TEST_GODOT for real engine isolation checks")
class EngineIsolationChecks(unittest.TestCase):
    def test_restart_persistence_fresh_profile_and_parent_environment(self):
        executable = os.environ["HANGMAN_TEST_GODOT"]
        original = os.environ.copy()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "project.godot").write_text(
                'config_version=5\n[application]\nconfig/name="Hangman isolation regression"\n', encoding="utf-8")
            # Use the same scene/script in independent Godot processes. A second
            # profile must not see the first one's saved marker.
            (root / "check.gd").write_text(
                'extends SceneTree\n'
                'func _initialize():\n'
                '\tvar expected := OS.get_cmdline_user_args()[0]\n'
                '\tvar exists := FileAccess.file_exists("user://restart-marker")\n'
                '\tif exists != (expected == "existing"):\n'
                '\t\tpush_error("Unexpected marker in test profile")\n'
                '\t\tquit(1)\n'
                '\t\treturn\n'
                '\tvar file := FileAccess.open("user://restart-marker", FileAccess.WRITE)\n'
                '\tfile.store_string("test only")\n'
                '\tfile.close()\n'
                '\tprint("ISOLATION_CHECK PASS")\n'
                '\tquit()\n', encoding="utf-8")
            for expected_sequence in (("fresh", "existing"), ("fresh",)):
                with isolated_environment(executable, root) as env:
                    for expected in expected_sequence:
                        result = run_godot(executable, root, ["--script", "res://check.gd", "--", expected], env)
                        self.assertEqual(result.returncode, 0, result.stdout)
                        self.assertFalse(has_engine_errors(result.stdout), result.stdout)
                        self.assertIn("ISOLATION_CHECK PASS", result.stdout)
        self.assertEqual(dict(os.environ), original)


if __name__ == "__main__":
    unittest.main()
