#!/usr/bin/env python3
"""Check the 2026-10-04 easy quiz addition and released content identity."""
from collections import Counter
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIRST_ID, LAST_ID = 1329, 1928
BASELINE = {'records': '064466e52a64329c02e5bb5ce8ea328304f92b9b1dc85c20edf0ec2ba2b878db', 'retired_ids': '4120a69787da24fd5958d838d32f0c6a6c02bb3b0f1bdad0bafad3cd7e71d1d4', 'ru_questions': 'f69f2b3556a9e9f7360bfb4fa0101a0e65e3c76b85da7ae5dc7d5b68a89a7bd5', 'ru_explanations': '3b0f5b8f12c427dcb33a59c493d5667ddb7b5cd5144fecdba082f63c7b2cc254', 'en_questions': '5ec6ac9107175d8e1fd432efc3c7ffb6c24474532c8fef98d295f8aac9363100', 'en_explanations': '451372b87d5e4b93da33d9dd98f07379efe4ed142ded6f7c525db074846f79d6'}


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                   separators=(",", ":")).encode()).hexdigest()


def require(ok, message):
    if not ok:
        raise SystemExit(message)


def main():
    catalog = json.loads((ROOT / "data/quiz_catalog.json").read_text())
    require(digest([r for r in catalog["records"] if r["id"] < FIRST_ID]) == BASELINE["records"],
            "Existing editorial records changed")
    require(digest(catalog["retired_ids"]) == BASELINE["retired_ids"], "Existing quiz aliases changed")
    additions = {r["id"]: r for r in catalog["records"] if FIRST_ID <= r["id"] <= LAST_ID}
    require(set(additions) == set(range(FIRST_ID, LAST_ID + 1)), "Missing/changed new quiz IDs")
    for language in ("ru", "en"):
        payload = json.loads((ROOT / f"data/quiz_questions_{language}.json").read_text())
        questions = payload["questions"]
        original = [q for q in questions if q["id"] < FIRST_ID]
        require(len(original) == 1300 and questions[:1300] == original,
                f"Existing runtime order changed: {language}")
        require(digest(original) == BASELINE[language + "_questions"],
                f"Existing question/answer/difficulty/ID changed: {language}")
        explanations = json.loads((ROOT / f"data/quiz_explanations_{language}.json").read_text())["explanations"]
        old_explanations = {key: text for key, text in explanations.items() if int(key) < FIRST_ID}
        require(digest(old_explanations) == BASELINE[language + "_explanations"],
                f"Existing explanation changed: {language}")
        require(set(explanations) == {str(q["id"]) for q in questions}, f"Incomplete explanation coverage: {language}")
        new = [q for q in questions if FIRST_ID <= q["id"] <= LAST_ID]
        require(len(new) == 600, f"Expected 600 additions: {language}")
        for theme in range(1, 11):
            rows = [q for q in new if q["theme_id"] == theme]
            easy = [q for q in rows if q["difficulty"] <= .16]
            light = [q for q in rows if .16 < q["difficulty"] <= .25]
            require(len(rows) == 60 and len(easy) == 40 and len(light) == 20,
                    f"Wrong theme quotas: {language}/{theme}")
            require(Counter(q["difficulty"] for q in easy) == {.08: 10, .10: 10, .12: 10, .14: 10},
                    f"Easy grades drifted: {language}/{theme}")
            require(Counter(q["correct_index"] for q in easy) == {i: 10 for i in range(4)},
                    f"Easy correct positions unbalanced: {language}/{theme}")
            require(Counter(q["correct_index"] for q in light) == {i: 5 for i in range(4)},
                    f"Light correct positions unbalanced: {language}/{theme}")
            for q in rows:
                require(q == additions[q["id"]]["questions"][language], "New catalog/runtime mismatch")
                require(bool(explanations[str(q["id"])].strip()), "Missing new explanation")
                require(explanations[str(q["id"])] not in (q["question"], q["answers"][q["correct_index"]]),
                        "Explanation only repeats question/answer")
        print(f"{language}: 600 new (400 <=0.16, 200 >0.16–0.25); {len(questions)} total; old content intact")
    for record in additions.values():
        require(record["questions"]["ru"]["correct_index"] == record["questions"]["en"]["correct_index"],
                "Localized correct positions differ")
        require(record["source_id"] == record["id"] and record["action"] == "add", "Addition lost stable identity")
    print("Easy quiz expansion checks passed")


if __name__ == "__main__":
    main()
