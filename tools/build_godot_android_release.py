#!/usr/bin/env python3
"""Build all four Android release ABIs and replace native code in a matching AAR."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import runpy
import subprocess
import struct
import sys
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PROFILE = ROOT / "tools/godot_android_release_profile.py"
ENGINE_COMMIT = "ed1daf0bf001b61586d9930840f2f1394092c079"
ENGINE_VERSION = "4.7.2.stable"
METADATA = "hangman-engine-build.json"
BUILD_RECORD = "hangman-native-build.json"
ELF_ABIS = {"armeabi-v7a": (1, 40), "arm64-v8a": (2, 183), "x86": (1, 3), "x86_64": (2, 62)}
ARCHITECTURES = {
    "arm32": "armeabi-v7a",
    "arm64": "arm64-v8a",
    "x86_32": "x86",
    "x86_64": "x86_64",
}


def profile_options() -> dict:
    return {key: value for key, value in runpy.run_path(str(PROFILE)).items()
            if not key.startswith("_")}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def validate_elf(data: bytes, abi: str) -> None:
    kind, machine = ELF_ABIS[abi]
    minimum = 52 if kind == 1 else 64
    if (len(data) < minimum or data[:4] != b"\x7fELF" or data[4] != kind
            or data[5:7] != b"\x01\x01" or int.from_bytes(data[16:18], "little") != 3
            or int.from_bytes(data[18:20], "little") != machine):
        raise ValueError(f"Invalid ELF shared library or wrong ABI: {abi}")
    offset = struct.unpack_from("<I" if kind == 1 else "<Q", data, 28 if kind == 1 else 32)[0]
    header, size, count = struct.unpack_from("<HHH", data, 40 if kind == 1 else 52)
    if header != minimum or size != (32 if kind == 1 else 56) or not count or offset < minimum or offset + size * count > len(data):
        raise ValueError(f"Invalid ELF program headers: {abi}")
    loads = 0
    for index in range(count):
        entry = offset + index * size
        if struct.unpack_from("<I", data, entry)[0] != 1:
            continue
        loads += 1
        if kind == 1:
            start = struct.unpack_from("<I", data, entry + 4)[0]
            length, memory = struct.unpack_from("<II", data, entry + 16)
            alignment = struct.unpack_from("<I", data, entry + 28)[0]
        else:
            start = struct.unpack_from("<Q", data, entry + 8)[0]
            length, memory, alignment = struct.unpack_from("<QQQ", data, entry + 32)
        virtual = struct.unpack_from("<I" if kind == 1 else "<Q", data, entry + (8 if kind == 1 else 16))[0]
        if (start + length > len(data) or memory < length or alignment < (16384 if kind == 2 else 4096)
                or alignment & (alignment - 1) or start % alignment != virtual % alignment):
            raise ValueError(f"Invalid ELF load segment/alignment: {abi}")
    if not loads:
        raise ValueError(f"ELF has no load segments: {abi}")


def validate_java_version(archive: zipfile.ZipFile) -> None:
    manifest = ET.fromstring(archive.read("AndroidManifest.xml"))
    ns = "{http://schemas.android.com/apk/res/android}"
    versions = [entry.get(ns + "value") for entry in manifest.iter("meta-data")
                if entry.get(ns + "name") == "org.godotengine.library.version"]
    if versions != [ENGINE_VERSION]:
        raise ValueError(f"AAR Java wrapper must be {ENGINE_VERSION}; found {versions}")


def validate_record(record: dict, abi: str, hashes: dict) -> None:
    if not isinstance(record, dict):
        raise ValueError(f"Invalid build record: {abi}")
    arch = next(arch for arch, value in ARCHITECTURES.items() if value == abi)
    if (record.get("schema") != 1 or record.get("source_commit") != ENGINE_COMMIT
            or record.get("engine_version") != ENGINE_VERSION
            or record.get("profile") != profile_options()
            or record.get("build_options") != {"platform": "android", "arch": arch, "swappy": "yes"}
            or record.get("libraries") != hashes):
        raise ValueError(f"Missing/stale build provenance or native hashes: {abi}; rebuild this ABI")


def record_build(source: Path, abi: str) -> None:
    directory = source / "platform/android/java/lib/libs/release" / abi
    hashes = {}
    for name in ("libgodot_android.so", "libc++_shared.so"):
        data = (directory / name).read_bytes()
        validate_elf(data, abi)
        hashes[name] = digest(data)
    arch = next(arch for arch, value in ARCHITECTURES.items() if value == abi)
    record = {"schema": 1, "source_commit": ENGINE_COMMIT, "engine_version": ENGINE_VERSION,
              "profile": profile_options(), "build_options": {"platform": "android", "arch": arch, "swappy": "yes"},
              "libraries": hashes}
    (directory / BUILD_RECORD).write_text(json.dumps(record, indent=2), encoding="utf-8")


def verify_installed(path: Path) -> None:
    try:
        _verify_installed(path)
    except (KeyError, ET.ParseError, zipfile.BadZipFile, TypeError, AttributeError) as error:
        raise ValueError(f"Invalid release AAR/build record: {error}") from error


def _verify_installed(path: Path) -> None:
    with zipfile.ZipFile(path) as archive:
        validate_java_version(archive)
        if METADATA not in archive.namelist():
            raise ValueError("Release AAR has no optimized-engine build record; build/install it again")
        record = json.loads(archive.read(METADATA))
        if not isinstance(record, dict):
            raise ValueError("Invalid release AAR build record")
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError("Duplicate entries in release AAR")
        hashes = {name: digest(archive.read(name)) for name in names if name != METADATA}
        if record.get("files") != hashes:
            raise ValueError("Release AAR files differ from its build record")
        builds = record.get("builds", {})
        if set(builds) != set(ELF_ABIS):
            raise ValueError("Release AAR must record all four ABIs")
        for abi in ELF_ABIS:
            native = {}
            for name in ("libgodot_android.so", "libc++_shared.so"):
                data = archive.read(f"jni/{abi}/{name}")
                validate_elf(data, abi)
                native[name] = digest(data)
            validate_record(builds[abi], abi, native)


def package(source: Path, base: Path, output: Path) -> None:
    """Preserve the official Java wrapper; replace every native ABI together."""
    libs = source / "platform/android/java/lib/libs/release"
    replacements = {}
    builds = {}
    for abi in ARCHITECTURES.values():
        hashes = {}
        for name in ("libgodot_android.so", "libc++_shared.so"):
            path = libs / abi / name
            if not path.is_file():
                raise ValueError(f"Missing compiled library: {path}")
            replacements[f"jni/{abi}/{name}"] = path
            data = path.read_bytes()
            validate_elf(data, abi)
            hashes[name] = digest(data)
        record_path = libs / abi / BUILD_RECORD
        if not record_path.is_file():
            raise ValueError(f"Missing build provenance: {abi}; run a normal build first")
        builds[abi] = json.loads(record_path.read_text(encoding="utf-8"))
        validate_record(builds[abi], abi, hashes)
    if base.resolve() == output.resolve():
        raise ValueError("Output must differ from the base AAR")
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(".aar.tmp")
    try:
        with zipfile.ZipFile(base) as original:
            validate_java_version(original)
            native = {n for n in original.namelist() if n.startswith("jni/") and n.endswith(".so")}
            if native != set(replacements):
                raise ValueError("Base AAR must contain exactly the four Godot Android ABIs")
            with zipfile.ZipFile(temporary, "w") as result:
                hashes = {}
                for entry in original.infolist():
                    if entry.filename == METADATA:
                        continue
                    if entry.filename in replacements:
                        data = replacements[entry.filename].read_bytes()
                        result.writestr(entry.filename, data, zipfile.ZIP_DEFLATED)
                    else:
                        data = original.read(entry.filename)
                        result.writestr(entry, data)
                    hashes[entry.filename] = digest(data)
                result.writestr(METADATA, json.dumps({"builds": builds, "files": hashes}, sort_keys=True), zipfile.ZIP_DEFLATED)
        with zipfile.ZipFile(temporary) as result:
            if result.testzip() is not None:
                raise ValueError("Corrupt output AAR")
        verify_installed(temporary)
        temporary.replace(output)
    finally:
        temporary.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, help="Godot 4.7.2-stable source checkout")
    parser.add_argument("--android-sdk", type=Path, help="SDK containing NDK 29.0.14206865")
    parser.add_argument("--verify-installed", action="store_true", help="Verify installed release AAR without compiling")
    parser.add_argument("--jobs", type=int, default=6)
    parser.add_argument("--base-aar", type=Path, default=ROOT / "android/build/libs/release/godot-lib.template_release.aar")
    parser.add_argument("--output", type=Path, default=ROOT / "builds/godot-lib.optimized_release.aar")
    parser.add_argument("--package-only", action="store_true", help="Package previously compiled libraries")
    args = parser.parse_args()
    try:
        if args.verify_installed:
            verify_installed(args.base_aar)
            print("Installed optimized release engine verified")
            return 0
        if args.source is None or args.android_sdk is None:
            raise ValueError("--source and --android-sdk are required for building/packaging")
        source = args.source.resolve()
        sdk = args.android_sdk.resolve()
        if args.jobs < 1:
            raise ValueError("--jobs must be positive")
        actual = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip()
        if actual != ENGINE_COMMIT:
            raise ValueError("Source checkout must be at 4.7.2-stable, matching the installed AAR/editor")
        subprocess.run(["git", "diff", "--exit-code", "--quiet", "HEAD"], cwd=source, check=True)
        if (source / "custom.py").exists():
            raise ValueError("Remove custom.py from Godot sources: unrecorded build overrides")
        if not args.base_aar.is_file():
            raise ValueError(f"Missing matching official 4.7.2 release AAR: {args.base_aar}")
        with zipfile.ZipFile(args.base_aar) as archive:
            validate_java_version(archive)
        if not args.package_only:
            environment = os.environ.copy()
            environment["ANDROID_HOME"] = str(sdk)
            temporary = source / "bin/build_tmp"
            temporary.mkdir(parents=True, exist_ok=True)
            for name in ("TEMP", "TMP", "TMPDIR"):
                environment[name] = str(temporary)
            # Android's platform defaults override target loaded via profile=.
            # Pass the shared values as explicit SCons arguments instead.
            options = [f"{key}={value}" for key, value in profile_options().items()]
            for arch in ARCHITECTURES:
                command = [sys.executable, "-m", "SCons", "platform=android", f"arch={arch}",
                           *options, f"ANDROID_HOME={sdk}", "swappy=yes", f"-j{args.jobs}"]
                print("Building: " + " ".join(command), flush=True)
                subprocess.run(command, cwd=source, env=environment, check=True)
                host = "windows-x86_64" if sys.platform == "win32" else "linux-x86_64"
                strip = sdk / "ndk/29.0.14206865/toolchains/llvm/prebuilt" / host / "bin" / (
                    "llvm-strip.exe" if sys.platform == "win32" else "llvm-strip")
                cpp = source / "platform/android/java/lib/libs/release" / ARCHITECTURES[arch] / "libc++_shared.so"
                subprocess.run([str(strip), "--strip-unneeded", str(cpp)], check=True)
                record_build(source, ARCHITECTURES[arch])
        package(source, args.base_aar, args.output)
        print(f"Release AAR ready: {args.output.resolve()}", flush=True)
    except (OSError, ValueError, KeyError, ET.ParseError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        parser.exit(1, str(error) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
