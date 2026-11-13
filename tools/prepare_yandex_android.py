#!/usr/bin/env python3
"""Prepare the ignored Godot Android template for Easy Monetization; repeat after reinstalling it."""
import argparse
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
AGP_VERSION = "8.13.2"
GRADLE_VERSION = "8.14.7"
GRADLE_SHA256 = "903bfc4bc7622323124054c10f509246212a1902948bdaf26c379cca8735e856"


def prepare(template: Path, check: bool = False) -> None:
    path = template / "config.gradle"
    source = path.read_text(encoding="utf-8")
    pattern = r"(androidGradlePlugin\s*:\s*)'[^']+'"
    if len(re.findall(pattern, source)) != 1:
        raise ValueError("Unsupported Android template: expected one androidGradlePlugin version")
    updated = re.sub(pattern, lambda match: match[1] + "'" + AGP_VERSION + "'", source)
    wrapper = template / "gradle/wrapper/gradle-wrapper.properties"
    wrapper_source = wrapper.read_text(encoding="utf-8")
    url_pattern = r"(?m)^distributionUrl=https\\?://services\.gradle\.org/distributions/gradle-[^/\r\n]+-(?:bin|all)\.zip$"
    if len(re.findall(url_pattern, wrapper_source)) != 1:
        raise ValueError("Unsupported Android template: expected one Gradle distribution URL")
    wrapper_updated = re.sub(url_pattern, lambda _: "distributionUrl=https\\://services.gradle.org/distributions/gradle-" + GRADLE_VERSION + "-bin.zip", wrapper_source)
    checksum_pattern = r"(?m)^distributionSha256Sum=.*$"
    checksum = "distributionSha256Sum=" + GRADLE_SHA256
    checksum_count = len(re.findall(checksum_pattern, wrapper_updated))
    if checksum_count > 1:
        raise ValueError("Unsupported Android template: duplicate Gradle checksums")
    if checksum_count:
        wrapper_updated = re.sub(checksum_pattern, lambda _: checksum, wrapper_updated)
    else:
        wrapper_updated = wrapper_updated.rstrip("\n") + "\n" + checksum + "\n"
    if check and (source != updated or wrapper_source != wrapper_updated):
        raise ValueError("Android Easy Monetization preparation is missing or outdated")
    if not check and source != updated:
        path.write_bytes(updated.encode("utf-8"))
    if not check and wrapper_source != wrapper_updated:
        wrapper.write_bytes(wrapper_updated.encode("utf-8"))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", type=Path, default=ROOT / "android/build")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    prepare(args.template, args.check)
    print("Easy Monetization Android template verified" if args.check else "Easy Monetization Android template prepared")


if __name__ == "__main__":
    main()
