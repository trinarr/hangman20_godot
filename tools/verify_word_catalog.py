#!/usr/bin/env python3
"""Check content exports and stability under edits, reordering, and deletions."""
import copy
from collections import Counter
import json
import re
from curate_word_database import ROOT, difficulty, export, rendered, validate


def verify_expansion(catalog, language, batch, band_key, bounds, quota):
    additions = [e for e in catalog['entries']
                 if e.get('assessment') == batch]
    assert len(additions) == 500, 'Expansion must add 500 words per language'
    for theme in range(1, 11):
        entries = [e for e in additions if e['theme_id'] == theme]
        assert Counter(e[band_key] for e in entries) == quota, (batch, language, theme)
    # Spaces, punctuation and the Russian Yo must not disguise a repeated answer.
    def normalized(text):
        return re.sub(r'[^A-ZА-Я]', '', text.upper().replace('Ё', 'Е'))
    added_ids = {e['id'] for e in additions}
    old = [e for e in catalog['entries'] if e['id'] not in added_ids]
    used = {normalized(e['answer']) for e in old}
    used.update(normalized(a) for e in catalog['entries'] for a in e.get('aliases', []))
    for entry in additions:
        answer = normalized(entry['answer'])
        assert answer not in used, ('Duplicate expansion answer', entry['answer'])
        used.add(answer)
        assert answer not in normalized(entry['hint']), ('Hint reveals answer', entry['answer'])
        low, high = bounds[entry[band_key]]
        assert low <= difficulty(entry, language) < high, entry['answer']
    # Editorial metadata must not increase the runtime payload.
    words, hints = rendered(catalog)
    assert not {'entries', 'difficulty_band', 'central_band', 'assessment'} & words.keys()
    assert set(hints) == {'hints'}


def main():
    for language in ('ru', 'en'):
        catalog = json.loads((ROOT / f'data/word_catalog_{language}.json').read_text())
        validate(catalog)
        verify_expansion(
            catalog, language, 'editorial_expansion_patch09', 'difficulty_band',
            {1: (0.0, .30), 2: (.30, .42), 3: (.42, .52), 4: (.52, 1.0)},
            {1: 25, 2: 15, 3: 7, 4: 3},
        )
        verify_expansion(
            catalog, language, 'editorial_expansion_patch10', 'central_band',
            {'lower': (.35, .42), 'core': (.42, .54), 'upper': (.54, .65)},
            {'lower': 15, 'core': 25, 'upper': 10},
        )
        export(language, check=True)
        expected = rendered(catalog)
        reordered = copy.deepcopy(catalog)
        reordered['entries'].reverse()
        assert rendered(reordered) == expected, 'Source order changed output'
        scores = {e['id']: difficulty(e, language) for e in catalog['entries']}
        # Removing a row must not change any surviving score or stable identity.
        reduced = copy.deepcopy(catalog)
        reduced['entries'].pop(len(reduced['entries']) // 2)
        for entry in reduced['entries']:
            assert difficulty(entry, language) == scores[entry['id']]
        edited = copy.deepcopy(catalog['entries'][0])
        edited['hint'] = 'A different explanation'
        assert difficulty(edited, language) == scores[edited['id']]
        if language == 'ru':
            byword = {e['answer']: e for e in catalog['entries']}
            assert len(byword) == 5002
            assert difficulty(byword['ПОДСОЛНУХ'], language) < .3
            assert difficulty(byword['БЕГОВАЯ ДОРОЖКА'], language) < .3
            for word in ('АТОМ', 'КОЛБА', 'ПРОБИРКА'):
                assert difficulty(byword[word], language) < .4
            assert sum(c.isalpha() for c in byword['БЕСПРОВОДНЫЕ НАУШНИКИ']['answer']) == 20
        else:
            byword = {e['answer']: e for e in catalog['entries']}
            assert len(byword) == 4444
            assert 'GLUON' not in byword and 'ETERNAL SUNSHINE' not in byword
            assert "CAPTAIN ARMBAND" in byword["CAPTAIN'S ARMBAND"]['aliases']
            assert 'FILM DIRECTOR' in byword['DIRECTOR']['aliases']
            assert difficulty(byword["CAPTAIN'S ARMBAND"], language) < .4
            assert 'crustacean' not in byword['GROUPER']['hint'].lower()
        print(f'{language}: export, stable IDs, reorder/delete invariance, editorial calibration OK')


if __name__ == '__main__':
    main()
