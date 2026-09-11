#!/usr/bin/env python3
"""Validate the editorial source and runtime quizzes; --write regenerates JSON."""
from __future__ import annotations

import argparse
from collections import Counter
import configparser
import fnmatch
import json
import re
from pathlib import Path

from verify_quiz_answer_leaks import find_answer_leaks, find_duplicate_candidates, tokens

ROOT = Path(__file__).resolve().parents[1]
FIELDS = {"id", "theme_id", "difficulty", "question", "answers", "correct_index"}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def build(catalog: dict, language: str) -> dict:
    # Preserve the pre-existing file order to keep incremental patches readable.
    by_id = {r["id"]: r for r in catalog["records"]}
    order = catalog["runtime_order"][language]
    require(len(order) == len(by_id) and set(order) == set(by_id), "Invalid runtime order")
    records = [by_id[qid] for qid in order]
    return {"format_version": 2, "language": language,
            "questions": [r["questions"][language] for r in records]}


def serialize(payload: dict) -> str:
    if payload["language"] == "en":
        # Keep the existing one-question-per-line English formatting.
        return ('{\n  "format_version": 2,\n  "language": "en",\n  "questions": [\n'
                + ",\n".join("    " + json.dumps(q, ensure_ascii=False) for q in payload["questions"])
                + "\n  ]\n}\n")
    return json.dumps(payload, ensure_ascii=False, indent=2) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    catalog = json.loads((ROOT / "data/quiz_catalog.json").read_text())
    ids = [r["id"] for r in catalog["records"]]
    require(len(ids) == len(set(ids)), "Duplicate catalog ID")
    retired = {int(key): value for key, value in catalog["retired_ids"].items()}
    require(not set(retired) & set(ids), "Retired fact is still playable")
    require(set(retired.values()) <= set(ids), "Replacement fact is missing")
    for record in catalog["records"]:
        require(all(record["questions"][lang]["id"] == record["id"] for lang in ("ru", "en")), "Catalog/runtime ID mismatch")
        require(set(record["sources"]) <= set(catalog["sources"]), f"Unknown source: {record['id']}")
        require(record["questions"]["ru"]["theme_id"] == record["questions"]["en"]["theme_id"], "RU/EN theme mismatch")
        if record["action"] == "replace":
            require(retired.get(record["source_id"]) == record["id"], "Missing fresh ID for replacement")
        else:
            require(record["source_id"] == record["id"], "Existing fact lost its ID")
    config = json.loads((ROOT / "data/game_design_config.json").read_text())
    window = config["difficulty"]["quiz_pick_window"]
    require(0 <= window <= 1, "Invalid quiz difficulty window")
    require("question_pick_jitter" not in config["difficulty"], "Obsolete quiz jitter setting")
    minimum = round(config["difficulty"]["minimum"] * 100)
    maximum = round(config["difficulty"]["maximum"] * 100)
    target_grid = [i / 100 for i in range(minimum, maximum + 1)]
    for language in ("ru", "en"):
        payload = build(catalog, language)
        questions = payload["questions"]
        for q in questions:
            require(set(q) == FIELDS, f"Runtime metadata/unexpected field: {q['id']}")
            require(q["id"] in ids and type(q["id"]) is int, "Invalid runtime ID")
            require(type(q["correct_index"]) is int and 0 <= q["correct_index"] < 4, f"Invalid answer key: {q['id']}")
            require(0 <= q["difficulty"] <= 1, f"Invalid difficulty: {q['id']}")
            require(isinstance(q["question"], str) and bool(q["question"].strip()), "Empty question")
            require(len(q["answers"]) == 4 and all(isinstance(a, str) and a.strip() for a in q["answers"]), f"Invalid options: {q['id']}")
            require(len({tuple(tokens(a)) for a in q["answers"]}) == 4, f"Duplicate options: {q['id']}")
        leaks = find_answer_leaks(language, questions)
        require(not leaks, "\n".join(leaks))
        candidates = find_duplicate_candidates(language, questions)
        require(not any(kind == "exact" for _, _, kind in candidates), "Duplicate question text")
        for left, right, kind in candidates:
            print(f"Review candidate ({kind}): {language} {left}/{right}")
        path = ROOT / f"data/quiz_questions_{language}.json"
        if args.write:
            path.write_text(serialize(payload), encoding="utf-8")
        require(json.loads(path.read_text()) == payload, f"Catalog/runtime mismatch: {path.name}; run --write")
        counts = Counter(q["theme_id"] for q in questions)
        print(f"{language}: {len(questions)} questions; per theme: {dict(sorted(counts.items()))}")
        # Report actual gaps rather than silently claiming a window is populated.
        for theme in sorted(counts):
            grades = [q["difficulty"] for q in questions if q["theme_id"] == theme]
            missing = [target for target in target_grid
                       if not any(abs(d - target) <= window + 1e-6 for d in grades)]
            if missing:
                print(f"  nearest-grade fallback: theme {theme}, targets {min(missing):.2f}..{max(missing):.2f}")
    exports = configparser.ConfigParser(interpolation=None)
    exports.read(ROOT / "export_presets.cfg")
    for section in exports.sections():
        if not re.fullmatch(r"preset\.\d+", section):
            continue
        patterns = exports.get(section, "exclude_filter", fallback="").strip('"').split(",")
        for path in ("data/quiz_catalog.json", "tools/verify_quiz_catalog.py", "docs/QUIZ_EDITORIAL.md"):
            require(any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns), f"Editor file exported by {section}: {path}")
    print("Quiz catalog/runtime validation passed")


if __name__ == "__main__":
    main()
