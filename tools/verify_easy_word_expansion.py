#!/usr/bin/env python3
"""Verify easy additions and the unchanged pre-expansion save identities."""
from collections import Counter
import hashlib
from word_hint_revision import snapshot_before_revision, verify as verify_hint_revision
import json
import re
from curate_word_database import ROOT, difficulty, rendered, validate

BATCH = 'editorial_easy_expansion_20261004'
REVISION = 'editorial_rebalance_20261004'
SOURCE_BATCH_DIGESTS = {
    'ru': '9158366ea176f56063eaee6198d6f0c9e8f59c1e99249e5116e5d50d3baecf5d',
    'en': 'dffaba952357a1e1cc135ebdfd038b973ec9439b39b69edffb30226f9eef0b29',
}
BASE_COUNTS = {
    'ru': [631, 591, 605, 605, 611, 624, 587, 566, 627, 552],
    'en': [572, 570, 573, 592, 600, 589, 480, 500, 600, 613],
}
# Hash every field of every surviving pre-expansion record, independent of order.
# Intentional later editorial edits must explicitly refresh this batch snapshot.
BASE_DIGESTS = {
    'ru': 'c74df995da2dad8e39d9f257866b58de242831ad3b1d43afc9521d55cdf672fe',
    'en': 'd17f9e620f886949655984ad72badca2e2071af3b81f7425312cfb4d7062cfe1',
}


def normalized(text):
    return re.sub(r'[^A-ZА-Я]', '', text.upper().replace('Ё', 'Е'))


def verify_retirements(additions, language):
    archive = json.loads((ROOT / 'data/word_retirements_20261004.json').read_text())
    assert archive['schema_version'] == 1 and archive['revision'] == REVISION
    assert archive['source_batch'] == BATCH
    bucket = archive['languages'][language]
    records = bucket['retired']
    retired = [r['entry'] for r in records]
    replacements = [e for e in additions if e.get('editorial_revision') == REVISION]
    surviving = [e for e in additions if e.get('editorial_revision') != REVISION]
    assert len(retired) == len(replacements) >= 750
    assert Counter(e['theme_id'] for e in retired) == Counter(e['theme_id'] for e in replacements)
    assert all(e.get('assessment') == BATCH and 'editorial_revision' not in e for e in retired)
    original = surviving + retired
    assert len(original) == 1500 and len({e['id'] for e in original}) == 1500
    encoded = json.dumps(sorted(snapshot_before_revision(original, language), key=lambda e: e['id']), ensure_ascii=False,
                         sort_keys=True, separators=(',', ':')).encode()
    assert hashlib.sha256(encoded).hexdigest() == SOURCE_BATCH_DIGESTS[language]
    assert bucket['original_batch_digest'] == SOURCE_BATCH_DIGESTS[language]
    assert not {e['id'] for e in original} & {e['id'] for e in replacements}
    assert not {normalized(e['answer']) for e in retired} & {normalized(e['answer']) for e in additions}
    for record in records:
        assert record['word_index'] >= 0
        assert record['difficulty'] == difficulty(record['entry'], language)
    single = sum(' ' not in e['answer'] and '-' not in e['answer'] for e in replacements)
    assert single > len(replacements) / 2, 'Replacements should mostly be single words'
    print(f'{language}: {len(retired)}/1500 replaced; {single} single words; '
          'original batch records archived exactly; no identity reuse')
    return retired


def verify(catalog, language):
    validate(catalog)
    verify_hint_revision(catalog, language)
    additions = [e for e in catalog['entries'] if e.get('assessment') == BATCH]
    retired = verify_retirements(additions, language)
    baseline = [e for e in catalog['entries'] if e.get('assessment') != BATCH]
    assert Counter(e['theme_id'] for e in additions) == {t: 150 for t in range(1, 11)}
    assert Counter(e['theme_id'] for e in baseline) == dict(enumerate(BASE_COUNTS[language], 1))
    encoded = json.dumps(sorted(snapshot_before_revision(baseline, language), key=lambda e: e['id']), ensure_ascii=False,
                         sort_keys=True, separators=(',', ':')).encode()
    assert hashlib.sha256(encoded).hexdigest() == BASE_DIGESTS[language], (
        language, 'Pre-expansion records changed: IDs, text, hints or calibration')
    manifest = json.loads((ROOT / 'data/word_content_migration_v2.json').read_text())
    used = {normalized(e['answer']) for e in baseline}
    used.update(normalized(e['answer']) for e in retired)
    used.update(normalized(m['retired']['answer']) for m in manifest['merges']
                if m['language'] == language)
    for entry in additions:
        answer = normalized(entry['answer'])
        assert answer not in used, (language, 'Duplicate or retired answer', entry['answer'])
        used.add(answer)
        assert answer not in normalized(entry['hint']), ('Hint reveals answer', entry['answer'])
        assert difficulty(entry, language) < .25, (entry['answer'], difficulty(entry, language))
        assert not {'score_adjustment', 'minimum', 'maximum', 'aliases'} & entry.keys(), entry['id']
        assert entry.get('audience') == 'A', entry['id']

    # Old saved word IDs must still resolve to their own text, hint and score
    # after sorting the enlarged arrays. Array positions are allowed to change.
    old_words, old_hints = rendered({**catalog, 'entries': baseline})
    new_words, new_hints = rendered(catalog)
    shifted = 0
    for theme in range(1, 11):
        key = str(theme)
        locations = {eid: i for i, eid in enumerate(new_words['ids'][key])}
        for i, eid in enumerate(old_words['ids'][key]):
            j = locations[eid]
            assert new_words['words'][key][j] == old_words['words'][key][i]
            assert new_words['difficulty'][key][j] == old_words['difficulty'][key][i]
            assert new_hints['hints'][key][j] == old_hints['hints'][key][i]
            shifted += i != j
    assert shifted > 0, 'Regression must exercise changed word array positions'
    scores = [difficulty(e, language) for e in additions]
    print(f'{language}: +150 in all 10 themes; {len(additions)} additions; '
          f'difficulty {min(scores):.4f}..{max(scores):.4f}; '
          f'{len(baseline)} old identities/calibration preserved, {shifted} positions reindexed')


def main():
    for language in ('ru', 'en'):
        catalog = json.loads((ROOT / f'data/word_catalog_{language}.json').read_text())
        verify(catalog, language)


if __name__ == '__main__':
    main()
