"""Profile suggestions must stay distinct from all published filler seed names."""
import json
from pathlib import Path
import unicodedata
import unittest

ROOT = Path(__file__).resolve().parents[2]


def normalized(value):
    return unicodedata.normalize("NFKC", value).casefold().replace("ё", "е")


class ProfileNicknameChecks(unittest.TestCase):
    def test_two_word_pools_and_reserved_names(self):
        pools = json.loads((ROOT / "data/profile_nicknames.json").read_text(encoding="utf-8"))
        self.assertEqual(set(pools), {"ru", "en"})
        reserved = set()
        for path in (ROOT / "supabase/seeds").glob("leaderboard_filler_nicknames*.json"):
            seed = json.loads(path.read_text(encoding="utf-8"))
            for pool in ("cis", "us_europe"):
                reserved.update(normalized(name['nickname'] if isinstance(name, dict) else name) for name in seed[pool])
        self.assertTrue(reserved)
        seen = set()
        for language, pairs in pools.items():
            self.assertTrue(pairs)
            for pair in pairs:
                with self.subTest(language=language, pair=pair):
                    self.assertEqual(len(pair), 2)
                    pattern = r"[А-ЯЁ][а-яё]+" if language == "ru" else r"[A-Z][a-z]+"
                    for word in pair:
                        self.assertRegex(word, "^" + pattern + "$")
                    name = "".join(pair)
                    # Every base leaves room for an eight-digit leaderboard ID.
                    self.assertTrue(2 <= len(name) <= 10, name)
                    self.assertLessEqual(len(name + "12345678"), 18)
                    key = normalized(name)
                    self.assertNotIn(key, reserved)
                    self.assertFalse(any(value.startswith(key) and value[len(key):].isdigit() for value in reserved), name)
                    self.assertNotIn(key, seen)
                    seen.add(key)

    def test_short_names_remain_available_for_long_ids(self):
        pools = json.loads((ROOT / "data/profile_nicknames.json").read_text(encoding="utf-8"))
        for language, pairs in pools.items():
            eligible = ["".join(words) for words in pairs if len("".join(words)) + 13 <= 18]
            self.assertGreaterEqual(len(eligible), 2, language)
