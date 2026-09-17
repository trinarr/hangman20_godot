"""Regression checks for the editorial validator (standard library only)."""
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_quiz_answer_leaks import find_answer_leaks, find_duplicate_candidates, numeric_values

FIXTURES = json.loads(Path(__file__).with_name("quiz_editorial_fixtures.json").read_text())


class EditorialChecks(unittest.TestCase):
    def test_numeric_leaks_in_both_languages(self):
        for language in ("ru", "en"):
            for qid in (52, 389, 416, 664, 665):
                with self.subTest(language=language, id=qid):
                    self.assertTrue(find_answer_leaks(language, [FIXTURES[str(qid)][language]]))

    def test_number_grouping(self):
        self.assertEqual(numeric_values("1,000", "en"), {1000})
        self.assertEqual(numeric_values("1 000", "ru"), {1000})

    def test_shared_terms_are_not_answer_clues(self):
        for language, question, answers in (
            ("en", "Which password is hardest to guess?", ["Password K7zP2", "Password apple", "Password summer", "Password football"]),
            ("ru", "Какой пароль сложнее угадать?", ["Пароль K7zP2", "Пароль яблоко", "Пароль лето", "Пароль футбол"]),
            ("en", "Which symbol appears on route 4?", ["4 stars", "4 circles", "4 squares", "4 hearts"]),
        ):
            item = {"id": 1, "question": question, "answers": answers, "correct_index": 0}
            self.assertEqual(find_answer_leaks(language, [item]), [])

    def test_paraphrased_duplicates_across_themes(self):
        for language in ("ru", "en"):
            for left, right in ((612, 778), (726, 764)):
                questions = [FIXTURES[str(left)][language], FIXTURES[str(right)][language]]
                self.assertTrue(find_duplicate_candidates(language, questions), (language, left, right))

    def test_same_answer_is_not_enough(self):
        questions = [
            {"id": 1, "question": "In which city is the Louvre?", "answers": ["Paris"], "correct_index": 0},
            {"id": 2, "question": "Which city hosted the 2024 Summer Olympics?", "answers": ["Paris"], "correct_index": 0},
        ]
        self.assertFalse(find_duplicate_candidates("en", questions))


if __name__ == "__main__":
    unittest.main()
