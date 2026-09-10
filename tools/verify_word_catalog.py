#!/usr/bin/env python3
"""Check content exports and stability under edits, reordering, and deletions."""
import copy
import json
from curate_word_database import ROOT, difficulty, export, rendered, validate


def main():
    for language in ('ru', 'en'):
        catalog = json.loads((ROOT / f'data/word_catalog_{language}.json').read_text())
        validate(catalog)
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
            assert len(byword) == 4002
            assert difficulty(byword['ПОДСОЛНУХ'], language) < .3
            assert difficulty(byword['БЕГОВАЯ ДОРОЖКА'], language) < .3
            for word in ('АТОМ', 'КОЛБА', 'ПРОБИРКА'):
                assert difficulty(byword[word], language) < .4
            assert sum(c.isalpha() for c in byword['БЕСПРОВОДНЫЕ НАУШНИКИ']['answer']) == 20
        else:
            byword = {e['answer']: e for e in catalog['entries']}
            assert len(byword) == 3444
            assert 'GLUON' not in byword and 'ETERNAL SUNSHINE' not in byword
            assert "CAPTAIN ARMBAND" in byword["CAPTAIN'S ARMBAND"]['aliases']
            assert 'FILM DIRECTOR' in byword['DIRECTOR']['aliases']
            assert difficulty(byword["CAPTAIN'S ARMBAND"], language) < .4
            assert 'crustacean' not in byword['GROUPER']['hint'].lower()
        print(f'{language}: export, stable IDs, reorder/delete invariance, editorial calibration OK')


if __name__ == '__main__':
    main()
