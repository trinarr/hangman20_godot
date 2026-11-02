"""Explanation edits must preserve expansion identity and coverage checks."""
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import verify_easy_quiz_expansion as validator


class EasyQuizExpansionChecks(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        (self.root / "data").mkdir()
        for name in ("quiz_catalog.json", "quiz_questions_ru.json", "quiz_questions_en.json",
                     "quiz_explanations_ru.json", "quiz_explanations_en.json"):
            shutil.copyfile(validator.ROOT / "data" / name, self.root / "data" / name)

    def edit(self, name, change):
        path = self.root / "data" / name
        payload = json.loads(path.read_text(encoding="utf-8"))
        change(payload)
        path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

    def verify(self):
        with patch.object(validator, "ROOT", self.root), redirect_stdout(io.StringIO()):
            validator.main()

    def test_existing_explanation_edits_are_allowed_in_both_languages(self):
        for language in ("ru", "en"):
            self.edit(f"quiz_explanations_{language}.json",
                      lambda data: data["explanations"].update({"1": "Revised explanation."}))
        self.verify()

    def test_empty_existing_explanation_is_rejected(self):
        self.edit("quiz_explanations_ru.json",
                  lambda data: data["explanations"].update({"1": "  "}))
        with self.assertRaisesRegex(SystemExit, "Empty/invalid explanation: ru"):
            self.verify()

    def test_missing_new_explanation_is_rejected(self):
        self.edit("quiz_explanations_en.json",
                  lambda data: data["explanations"].pop(str(validator.FIRST_ID)))
        with self.assertRaisesRegex(SystemExit, "Incomplete explanation coverage: en"):
            self.verify()

    def test_existing_question_identity_changes_are_rejected(self):
        self.edit("quiz_questions_ru.json",
                  lambda data: data["questions"][0].update({"id": 999999}))
        with self.assertRaisesRegex(SystemExit, "Existing runtime order changed: ru"):
            self.verify()

    def test_missing_new_question_id_is_rejected(self):
        self.edit("quiz_catalog.json", lambda data: data.update({
            "records": [row for row in data["records"] if row["id"] != validator.FIRST_ID]}))
        with self.assertRaisesRegex(SystemExit, "Missing/changed new quiz IDs"):
            self.verify()


if __name__ == "__main__":
    unittest.main()
