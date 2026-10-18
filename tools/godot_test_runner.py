"""Desktop test isolation and UTF-8 engine logs; never change the parent profile."""
from contextlib import contextmanager
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ANSI = re.compile(r"\x1b\[[0-9;]*m")


def configure_console():
    # Captured Windows stdout defaults to the legacy code page. Engine logs can
    # contain Greek/math symbols as well as both game languages.
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")


def has_engine_errors(output: str) -> bool:
    return re.search(r"^(?:SCRIPT ERROR|ERROR):", ANSI.sub("", output), re.MULTILINE) is not None


def run_godot(executable, project, arguments, env, timeout=150):
    # GUI Windows executables may not deliver stdout. Always retain the engine
    # log as well, rather than interpreting an empty successful process as PASS.
    with tempfile.TemporaryDirectory(prefix="hangman-log-") as directory:
        log = Path(directory) / "engine.log"
        try:
            result = subprocess.run(
                [str(executable), "--headless", "--log-file", str(log),
                 "--path", str(project), *arguments],
                env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, encoding="utf-8", errors="replace", timeout=timeout,
            )
        except subprocess.TimeoutExpired as error:
            # Preserve GUI executable diagnostics before the log folder is removed.
            if log.exists():
                error.stdout = log.read_text(encoding="utf-8")
            raise
        output = ANSI.sub("", result.stdout)
        if log.exists():
            logged = ANSI.sub("", log.read_text(encoding="utf-8"))
            if logged.strip() and logged.strip() not in output:
                output += "\n" + logged
        result.stdout = output
        return result


@contextmanager
def isolated_environment(executable, root):
    """Prove the actual project's user-dir settings resolve inside our sandbox.

    The probe uses the same config without autoloads, before any game code can
    read/write saves. A failed probe aborts the suite. Reuse this context for all
    phases of a save/restart test; each other suite gets a fresh context.
    """
    if sys.platform != "win32" and not sys.platform.startswith("linux"):
        raise RuntimeError("Test save isolation currently supports Windows and Linux")
    root = Path(root)
    if (root / "override.cfg").exists():
        raise RuntimeError("Remove local override.cfg before isolated tests (unverified user-dir overrides)")
    with tempfile.TemporaryDirectory(prefix="hangman-profile-") as directory:
        profile = Path(directory).resolve()
        env = os.environ.copy()
        env.update({"PYTHONUTF8": "1", "HANGMAN_SUPABASE_NETWORK_DISABLED": "1"})
        keys = ("APPDATA", "LOCALAPPDATA") if sys.platform == "win32" else (
            "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME")
        for key in keys:
            location = profile / key.lower()
            location.mkdir()
            env[key] = str(location)
        probe = profile / "probe"
        probe.mkdir()
        config = (root / "project.godot").read_text(encoding="utf-8")
        # Preserve [application] verbatim, including platform-specific settings.
        application = re.search(r"(?ms)^\[application\]\s*.*?(?=^\[|\Z)", config)
        if application is None:
            raise RuntimeError("Project has no [application] settings for isolation probe")
        config = "config_version=5\n\n" + application.group(0)
        (probe / "project.godot").write_text(config, encoding="utf-8")
        (probe / "probe.gd").write_text(
            'extends SceneTree\n'
            'func _initialize():\n'
            '\tprint("ISOLATED_USER_DIR " + JSON.stringify(OS.get_user_data_dir()))\n'
            '\tquit()\n', encoding="utf-8")
        result = run_godot(executable, probe, ["--script", "res://probe.gd"], env, timeout=30)
        matches = re.findall(r"^ISOLATED_USER_DIR (.+)$", result.stdout, re.MULTILINE)
        if result.returncode or has_engine_errors(result.stdout) or not matches:
            raise RuntimeError("Godot save isolation probe failed:\n" + result.stdout)
        user_dir = Path(json.loads(matches[-1])).resolve()
        if not user_dir.is_relative_to(profile) or user_dir == profile:
            raise RuntimeError(f"Unsafe user:// path outside temporary profile: {user_dir}")
        print(f"Verified isolated user://: {user_dir}", flush=True)
        yield env
