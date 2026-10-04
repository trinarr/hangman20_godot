#!/usr/bin/env python3
"""Validate release replacement identity, exact difficulty and unchanged quotas."""
import json
import re
from collections import Counter
from curate_word_database import ROOT, difficulty
from verify_easy_word_expansion import BATCH


def main():
    manifest = json.loads((ROOT / 'data/word_content_migration_v2.json').read_text())
    assert len(manifest['merges']) == 44
    assert Counter(m['language'] for m in manifest['merges']) == {'ru': 25, 'en': 19}
    norm = lambda text: re.sub(r'[^A-ZА-Я]', '', text.upper().replace('Ё', 'Е'))
    for language in ('ru', 'en'):
        catalog = json.loads((ROOT / f'data/word_catalog_{language}.json').read_text())
        # The migration replaces release records one for one. Later additions
        # have independent IDs and do not belong to its released quota.
        entries = {e['id']: e for e in catalog['entries'] if e.get('assessment') != BATCH}
        added = [e for e in catalog['entries'] if e.get('assessment') == BATCH]
        assert Counter(e['theme_id'] for e in added) == {t: 150 for t in range(1, 11)}
        old_ids = {i for ids in manifest['released_ids'][language].values() for i in ids}
        merges = [m for m in manifest['merges'] if m['language'] == language]
        retired_ids = {m['retired']['id'] for m in merges}
        new_ids = {m['replacement_id'] for m in merges}
        assert set(entries) == old_ids - retired_ids | new_ids
        for theme, ids in manifest['released_ids'][language].items():
            assert sum(e['theme_id'] == int(theme) for e in entries.values()) == len(ids)
        normalized = [norm(e['answer']) for e in catalog['entries']]
        assert len(normalized) == len(set(normalized))
        for merge in merges:
            old = merge['retired']
            keep = entries[merge['canonical_id']]
            new = entries[merge['replacement_id']]
            assert old['id'] not in entries
            assert keep['answer'] == merge['canonical_answer']
            assert keep['theme_id'] == merge['canonical_theme_id']
            assert new['theme_id'] == old['theme_id']
            assert new['id'] not in old_ids
            assert difficulty(new, language) == difficulty(old, language) == merge['replacement_difficulty']
            assert norm(new['answer']) not in norm(new['hint'])
        print(f'{language}: {len(merges)} replacements; identity, difficulty, theme quotas and hints OK')
    expected = {81: 'ГРИВИСТЫЙ ВОЛК', 84: 'ДЖОМОЛУНГМА', 103: 'ДЕКАБРИСТ', 104: 'СТРЕЛЕЦ'}
    for merge in manifest['merges']:
        if merge['audit_number'] in expected:
            assert merge['canonical_answer'] == expected[merge['audit_number']]
    print('User-selected canonical answers OK')


if __name__ == '__main__':
    main()
