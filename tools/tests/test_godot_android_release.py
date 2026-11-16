"""Native AAR replacement must preserve the Java bridge and all Android ABIs."""
import importlib.util
from pathlib import Path
import tempfile
import json
import struct
import os
import subprocess
import shutil
import sys
import unittest
from unittest.mock import patch
import zipfile

TOOLS = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("godot_release_builder", TOOLS / "build_godot_android_release.py")
BUILDER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILDER)


def elf(abi):
    kind, machine = BUILDER.ELF_ABIS[abi]
    header, phsize = (52, 32) if kind == 1 else (64, 56)
    data = bytearray(header + phsize)
    data[:7] = b"\x7fELF" + bytes([kind, 1, 1])
    struct.pack_into("<HHI", data, 16, 3, machine, 1)
    struct.pack_into("<I" if kind == 1 else "<Q", data, 28 if kind == 1 else 32, header)
    struct.pack_into("<HHH", data, 40 if kind == 1 else 52, header, phsize, 1)
    struct.pack_into("<I", data, header, 1)
    if kind == 1:
        struct.pack_into("<II", data, header + 16, len(data), len(data))
        struct.pack_into("<I", data, header + 28, 4096)
    else:
        struct.pack_into("<QQQ", data, header + 32, len(data), len(data), 16384)
    return bytes(data)


class ReleaseAarTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.base = self.root / "official.aar"
        self.output = self.root / "optimized.aar"
        manifest = ('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application>'
                    '<meta-data android:name="org.godotengine.library.version" android:value="4.7.2.stable"/>'
                    '</application></manifest>')
        self.members = {"classes.jar": b"unchanged Java bridge", "AndroidManifest.xml": manifest.encode()}
        for abi in BUILDER.ARCHITECTURES.values():
            for name in ("libgodot_android.so", "libc++_shared.so"):
                self.members[f"jni/{abi}/{name}"] = b"official native"
                path = self.root / "platform/android/java/lib/libs/release" / abi / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(elf(abi))
            BUILDER.record_build(self.root, abi)
        self.write_base()

    def write_base(self):
        with zipfile.ZipFile(self.base, "w") as archive:
            for name, data in self.members.items():
                archive.writestr(name, data)

    def test_replace_all_abis_and_preserve_wrapper(self):
        BUILDER.package(self.root, self.base, self.output)
        with zipfile.ZipFile(self.output) as archive:
            self.assertEqual(set(archive.namelist()), set(self.members) | {BUILDER.METADATA})
            for name, data in self.members.items():
                expected = elf(name.split('/')[1]) if name.startswith("jni/") else data
                self.assertEqual(archive.read(name), expected)
        BUILDER.verify_installed(self.output)
        with zipfile.ZipFile(self.base) as archive:
            self.assertEqual(archive.read("jni/x86/libgodot_android.so"), b"official native")

    def test_missing_compiled_abi_preserves_existing_output(self):
        (self.root / "platform/android/java/lib/libs/release/x86/libgodot_android.so").unlink()
        self.output.write_bytes(b"previous output")
        with self.assertRaisesRegex(ValueError, "Missing compiled"):
            BUILDER.package(self.root, self.base, self.output)
        self.assertEqual(self.output.read_bytes(), b"previous output")

    def test_incomplete_base_aar_is_rejected(self):
        del self.members["jni/x86_64/libgodot_android.so"]
        self.write_base()
        with self.assertRaisesRegex(ValueError, "exactly the four"):
            BUILDER.package(self.root, self.base, self.output)
        self.assertFalse(self.output.exists())
        self.assertFalse(self.output.with_suffix(".aar.tmp").exists())

    def test_base_cannot_be_overwritten(self):
        with self.assertRaisesRegex(ValueError, "must differ"):
            BUILDER.package(self.root, self.base, self.base)

    def test_all_scons_calls_explicitly_override_android_debug_default(self):
        arguments = ["build_godot_android_release.py", "--source", str(self.root),
                     "--android-sdk", str(self.root), "--base-aar", str(self.base),
                     "--output", str(self.output)]
        with patch.object(BUILDER.sys, "argv", arguments), \
                patch.object(BUILDER.subprocess, "check_output", return_value=BUILDER.ENGINE_COMMIT + "\n"), \
                patch.object(BUILDER.subprocess, "run") as run, \
                patch.object(BUILDER, "record_build"), \
                patch.object(BUILDER, "package"):
            self.assertEqual(BUILDER.main(), 0)
        calls = [call for call in run.call_args_list if "SCons" in call.args[0]]
        self.assertEqual(len(calls), 4)
        for call, arch in zip(calls, BUILDER.ARCHITECTURES):
            command = call.args[0]
            for option in ["target=template_release", "optimize=size", "disable_3d=yes",
                           "disable_physics_2d=yes", "disable_navigation_2d=yes", f"arch={arch}"]:
                self.assertIn(option, command)
            self.assertEqual(call.kwargs["env"]["ANDROID_HOME"], str(self.root.resolve()))
            for name in ("TEMP", "TMP", "TMPDIR"):
                self.assertEqual(call.kwargs["env"][name], str(self.root / "bin/build_tmp"))

    def test_wrong_java_version_rejected(self):
        self.members['AndroidManifest.xml'] = self.members['AndroidManifest.xml'].replace(b'4.7.2.stable', b'4.6.stable')
        self.write_base()
        with self.assertRaisesRegex(ValueError, 'Java wrapper'):
            BUILDER.package(self.root, self.base, self.output)

    def test_text_instead_of_elf_rejected(self):
        path = self.root / 'platform/android/java/lib/libs/release/x86/libgodot_android.so'
        path.write_bytes(b'not an ELF library')
        with self.assertRaisesRegex(ValueError, 'Invalid ELF'):
            BUILDER.package(self.root, self.base, self.output)

    def test_wrong_native_architecture_rejected(self):
        path = self.root / 'platform/android/java/lib/libs/release/x86/libgodot_android.so'
        path.write_bytes(elf('arm64-v8a'))
        with self.assertRaisesRegex(ValueError, 'wrong ABI'):
            BUILDER.package(self.root, self.base, self.output)

    def test_64_bit_alignment_below_16k_rejected(self):
        data = bytearray(elf('arm64-v8a'))
        struct.pack_into('<Q', data, 64 + 48, 4096)
        with self.assertRaisesRegex(ValueError, 'alignment'):
            BUILDER.validate_elf(bytes(data), 'arm64-v8a')

    def test_dirty_sources_rejected_before_build(self):
        arguments = ['builder', '--source', str(self.root), '--android-sdk', str(self.root), '--base-aar', str(self.base)]
        with patch.object(BUILDER.sys, 'argv', arguments), \
                patch.object(BUILDER.subprocess, 'check_output', return_value=BUILDER.ENGINE_COMMIT), \
                patch.object(BUILDER.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'git diff')) as run:
            with self.assertRaises(SystemExit) as result:
                BUILDER.main()
        self.assertEqual(result.exception.code, 1)
        self.assertEqual(run.call_count, 1)

    def test_custom_py_rejected_before_build(self):
        (self.root / 'custom.py').write_text('precision="double"')
        arguments = ['builder', '--source', str(self.root), '--android-sdk', str(self.root), '--base-aar', str(self.base)]
        with patch.object(BUILDER.sys, 'argv', arguments), \
                patch.object(BUILDER.subprocess, 'check_output', return_value=BUILDER.ENGINE_COMMIT), \
                patch.object(BUILDER.subprocess, 'run') as run:
            with self.assertRaises(SystemExit) as result:
                BUILDER.main()
        self.assertEqual(result.exception.code, 1)
        self.assertEqual(run.call_count, 1)

    def test_export_stops_before_sdk_when_release_engine_is_invalid(self):
        sys.path.insert(0, str(TOOLS))
        import export_android as exporter
        arguments = ['exporter', '--preset', 'Example', '--output', str(self.root / 'test.aab')]
        with patch.object(sys, 'argv', arguments), patch.object(exporter, 'ROOT', self.root), \
                patch.object(exporter, 'validate_store', return_value='rustore'), \
                patch.object(exporter, 'validate_firebase_config'), \
                patch.object(exporter, 'verify_installed', side_effect=ValueError('wrong engine')) as verify, \
                patch.object(exporter, 'prepare_yandex') as prepare:
            with self.assertRaises(SystemExit) as result:
                exporter.main()
        self.assertEqual(result.exception.code, 2)
        verify.assert_called_once()
        prepare.assert_not_called()

    def test_modified_native_hash_rejected(self):
        path = self.root / 'platform/android/java/lib/libs/release/x86/libgodot_android.so'
        path.write_bytes(path.read_bytes() + b'modified')
        with self.assertRaisesRegex(ValueError, 'provenance'):
            BUILDER.package(self.root, self.base, self.output)

    def test_old_profile_record_rejected(self):
        path = self.root / 'platform/android/java/lib/libs/release/x86' / BUILDER.BUILD_RECORD
        record = json.loads(path.read_text());record['profile']['disable_3d'] = 'no'
        path.write_text(json.dumps(record))
        with self.assertRaisesRegex(ValueError, 'provenance'):
            BUILDER.package(self.root, self.base, self.output)

    def test_missing_native_record_rejected(self):
        (self.root / 'platform/android/java/lib/libs/release/x86' / BUILDER.BUILD_RECORD).unlink()
        with self.assertRaisesRegex(ValueError, 'Missing build provenance'):
            BUILDER.package(self.root, self.base, self.output)

    def test_standard_installed_template_rejected(self):
        with self.assertRaisesRegex(ValueError, 'no optimized-engine'):
            BUILDER.verify_installed(self.base)

    def test_replaced_installed_native_rejected(self):
        BUILDER.package(self.root, self.base, self.output)
        altered = self.root / 'altered.aar'
        with zipfile.ZipFile(self.output) as source, zipfile.ZipFile(altered, 'w') as target:
            for item in source.infolist():
                data = source.read(item.filename)
                if item.filename == 'jni/x86/libgodot_android.so':
                    data += b'replaced'
                target.writestr(item, data)
        with self.assertRaisesRegex(ValueError, 'differ from'):
            BUILDER.verify_installed(altered)

    def test_runtime_does_not_access_removed_viewport_property(self):
        import re
        for path in (TOOLS.parent / 'scripts').rglob('*.gd'):
            self.assertIsNone(re.search(r'\.disable_3d\s*=', path.read_text(encoding='utf-8')), str(path))

    @unittest.skipUnless(os.environ.get('HANGMAN_TEST_GRADLE'), 'Set HANGMAN_TEST_GRADLE for direct-export guard integration')
    def test_gradle_checks_release_engine_and_leaves_debug_available(self):
        directory = self.root / 'android/build'
        directory.mkdir(parents=True)
        tools = self.root / 'tools'
        tools.mkdir()
        for name in ['build_godot_android_release.py', 'godot_android_release_profile.py']:
            shutil.copy2(TOOLS / name, tools / name)
        guard = (TOOLS / 'android_startup/release_engine_guard.gradle').as_posix()
        (directory / 'settings.gradle').write_text("rootProject.name = 'engine-guard-test'\n")
        (directory / 'build.gradle').write_text(
            f"apply from: '{guard}'\ntasks.register('assembleRelease')\ntasks.register('assembleDebug')\n")
        env = os.environ.copy()
        env['GRADLE_USER_HOME'] = str(self.root / 'gradle-home')
        env['HANGMAN_PYTHON'] = sys.executable
        def execute(task):
            return subprocess.run([env['HANGMAN_TEST_GRADLE'], '--offline', '--no-daemon', '-p', str(directory), task],
                                  env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=120)
        result = execute('assembleDebug')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        result = execute('assembleRelease')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('verification failed', result.stdout + result.stderr)
        BUILDER.package(self.root, self.base, self.output)
        target = directory / 'libs/release/godot-lib.template_release.aar'
        target.parent.mkdir(parents=True)
        shutil.copy2(self.output, target)
        result = execute('assembleRelease')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        shutil.copy2(self.base, target)
        result = execute('assembleRelease')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('no optimized-engine', result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
