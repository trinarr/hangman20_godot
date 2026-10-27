"""Sequential hint edits preserve historical snapshots and reject unrelated edits."""
import contextlib
import copy
import io
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from word_hint_revision import audit_manifest, later_manifest, manifest, snapshot_before_revision, verify


class WordHintRevisionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogs = {
            lang: json.loads((ROOT / f'data/word_catalog_{lang}.json').read_text(encoding='utf-8'))
            for lang in ('ru', 'en')
        }

    def test_current_catalogs_pass_all_revisions(self):
        for lang, catalog in self.catalogs.items():
            with self.subTest(language=lang), contextlib.redirect_stdout(io.StringIO()):
                verify(catalog, lang)

    def test_overlapping_edit_restores_oldest_hint(self):
        old = {r['id']: r for r in manifest()['changes']}
        newer = {r['id']: r for r in later_manifest()['changes']}
        overlap = old.keys() & newer.keys()
        self.assertEqual(overlap, {'en-a63ee6a1ffb40963'})
        restored = {e['id']: e for e in snapshot_before_revision(self.catalogs['en']['entries'], 'en')}
        for eid in overlap:
            self.assertEqual(newer[eid]['hint'], old[eid]['new_hint'])
            self.assertEqual(restored[eid]['hint'], old[eid]['hint'])
        # Historical expansion checks also pass subsets of the catalog.
        subset = [e for e in self.catalogs['en']['entries'] if e['id'] in overlap]
        self.assertEqual(snapshot_before_revision(subset, 'en'), [restored[subset[0]['id']]])

    def test_unapproved_content_and_metadata_are_rejected(self):
        approved_id = later_manifest()['changes'][0]['id']
        unrelated_id = next(e['id'] for e in self.catalogs['en']['entries']
                            if e['id'] not in {r['id'] for r in later_manifest()['changes']})
        for eid, field, value in (
            (approved_id, 'hint', 'An unapproved replacement.'),
            (approved_id, 'answer', 'OTHER ANSWER'),
            (approved_id, 'concept_score', .01),
            (unrelated_id, 'hint', 'An unrelated change.'),
        ):
            with self.subTest(entry=eid, field=field):
                broken = copy.deepcopy(self.catalogs['en'])
                next(e for e in broken['entries'] if e['id'] == eid)[field] = value
                with self.assertRaises(AssertionError), contextlib.redirect_stdout(io.StringIO()):
                    verify(broken, 'en')

    def test_reverting_approved_hint_is_rejected(self):
        row = later_manifest()['changes'][0]
        broken = copy.deepcopy(self.catalogs['en'])
        next(e for e in broken['entries'] if e['id'] == row['id'])['hint'] = row['hint']
        with self.assertRaises(AssertionError), contextlib.redirect_stdout(io.StringIO()):
            verify(broken, 'en')

    def test_audit_restores_previous_texts_without_mutating_catalog(self):
        for lang, catalog in self.catalogs.items():
            original = copy.deepcopy(catalog)
            restored = {e['id']: e for e in snapshot_before_revision(catalog['entries'], lang)}
            oldest = {r['id']: r['hint'] for r in manifest()['changes'] if r['language'] == lang}
            for row in audit_manifest()['changes']:
                if row['language'] == lang:
                    self.assertEqual(restored[row['id']]['hint'], oldest.get(row['id'], row['hint']))
            self.assertEqual(catalog, original)

    def test_reverting_audit_hint_is_rejected(self):
        for lang in ('ru', 'en'):
            row = next(r for r in audit_manifest()['changes'] if r['language'] == lang)
            broken = copy.deepcopy(self.catalogs[lang])
            next(e for e in broken['entries'] if e['id'] == row['id'])['hint'] = row['hint']
            with self.subTest(language=lang), self.assertRaises(AssertionError), contextlib.redirect_stdout(io.StringIO()):
                verify(broken, lang)


if __name__ == '__main__':
    unittest.main()
