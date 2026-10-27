#!/usr/bin/env python3
"""Validate sequential hint-only revisions without weakening historical hashes."""
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / 'tools/word_hint_revision_20261004.json'
LATER_MANIFEST_PATH = ROOT / 'tools/word_hint_revision_20261027.json'
AUDIT_MANIFEST_PATH = ROOT / 'tools/word_hint_revision_20261027_audit.json'


def manifest():
    result = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    assert result['schema_version'] == 1
    assert result['revision'] == 'hint_editorial_20261004'
    return result


def later_manifest():
    result = json.loads(LATER_MANIFEST_PATH.read_text(encoding="utf-8"))
    assert result['schema_version'] == 1
    assert result['revision'] == 'hint_editorial_20261027'
    assert result['previous_revision'] == manifest()['revision']
    return result


def audit_manifest():
    result = json.loads(AUDIT_MANIFEST_PATH.read_text(encoding="utf-8"))
    assert result['schema_version'] == 1
    assert result['revision'] == 'hint_editorial_20261027_audit'
    assert result['previous_revision'] == later_manifest()['revision']
    return result


def revisions():
    return (manifest(), later_manifest(), audit_manifest())


def _restore_hints(entries, rows):
    approved = {r['id']: r for r in rows}
    restored = copy.deepcopy(entries)
    for entry in restored:
        if entry['id'] in approved:
            row = approved[entry['id']]
            assert entry['hint'] in (row['hint'], row['new_hint']), ('Unapproved hint', entry['id'])
            entry['hint'] = row['hint']
    return restored


def snapshot_before_revision(entries, language):
    restored = copy.deepcopy(entries)
    for revision in reversed(revisions()):
        rows = [r for r in revision['changes'] if r['language'] == language]
        restored = _restore_hints(restored, rows)
    return restored


def _digest(entries):
    encoded = json.dumps(sorted(entries, key=lambda e: e['id']), ensure_ascii=False,
                         sort_keys=True, separators=(',', ':')).encode()
    return hashlib.sha256(encoded).hexdigest()


def verify(catalog, language):
    snapshot = catalog['entries']
    counts = ((74, 116), (0, 10), (211, 577))
    for revision, quota in reversed(tuple(zip(revisions(), counts))):
        rows = [r for r in revision['changes'] if r['language'] == language]
        assert len(rows) == quota[0 if language == 'ru' else 1]
        assert len({r['id'] for r in rows}) == len(rows)
        by_id = {e['id']: e for e in snapshot}
        for row in rows:
            before = {k: v for k, v in row.items() if k not in ('language', 'new_hint')}
            assert by_id[row['id']] == {**before, 'hint': row['new_hint']}, ('Not a hint-only edit', row['id'])
            assert row['hint'] != row['new_hint']
        snapshot = _restore_hints(snapshot, rows)
        assert _digest(snapshot) == revision['baseline_digests'][language], (
            language, revision['revision'], 'Unapproved content/identity/calibration change')
        print(f"{language}: {len(rows)} hint-only edits in {revision['revision']}; baseline preserved")


def main():
    for language in ('ru', 'en'):
        catalog = json.loads((ROOT / f'data/word_catalog_{language}.json').read_text(encoding="utf-8"))
        verify(catalog, language)


if __name__ == '__main__':
    main()
