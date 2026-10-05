#!/usr/bin/env python3
"""Validate the approved hint-only revision without weakening historical hashes."""
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / 'tools/word_hint_revision_20261004.json'


def manifest():
    result = json.loads(MANIFEST_PATH.read_text())
    assert result['schema_version'] == 1
    assert result['revision'] == 'hint_editorial_20261004'
    return result


def snapshot_before_revision(entries, language):
    approved = {r['id']: r for r in manifest()['changes'] if r['language'] == language}
    restored = copy.deepcopy(entries)
    for entry in restored:
        if entry['id'] in approved:
            row = approved[entry['id']]
            assert entry['hint'] in (row['hint'], row['new_hint']), ('Unapproved hint', entry['id'])
            entry['hint'] = row['hint']
    return restored


def verify(catalog, language):
    data = manifest()
    rows = [r for r in data['changes'] if r['language'] == language]
    assert len(rows) == (74 if language == 'ru' else 116)
    assert len({r['id'] for r in rows}) == len(rows)
    by_id = {e['id']: e for e in catalog['entries']}
    for row in rows:
        before = {k: v for k, v in row.items() if k not in ('language', 'new_hint')}
        assert by_id[row['id']] == {**before, 'hint': row['new_hint']}, ('Not a hint-only edit', row['id'])
        assert row['hint'] != row['new_hint']
    snapshot = snapshot_before_revision(catalog['entries'], language)
    encoded = json.dumps(sorted(snapshot, key=lambda e: e['id']), ensure_ascii=False,
                         sort_keys=True, separators=(',', ':')).encode()
    assert hashlib.sha256(encoded).hexdigest() == data['baseline_digests'][language], (
        language, 'Unapproved content/identity/calibration change')
    print(f'{language}: {len(rows)} approved hint-only edits; all other fields and records preserved')


def main():
    for language in ('ru', 'en'):
        catalog = json.loads((ROOT / f'data/word_catalog_{language}.json').read_text())
        verify(catalog, language)


if __name__ == '__main__':
    main()
