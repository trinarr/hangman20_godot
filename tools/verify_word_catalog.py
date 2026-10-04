#!/usr/bin/env python3
"""Check content exports and stability under edits, reordering, and deletions."""
import copy
from collections import Counter
import json
import re
from curate_word_database import ROOT, difficulty, export, rendered, validate
from verify_easy_word_expansion import verify as verify_easy_expansion


# (term, place name, original term score, original place score).
# Swapping preserves the complete geography difficulty distribution.
GEOGRAPHY_REBALANCE_PAIRS = (
    ('БАССЕЙН', 'ГЕРМАНИЯ', 0.1374, 0.2609),
    ('ЭКВАТОР', 'ГРЕЦИЯ', 0.14, 0.2505),
    ('ПАРАЛЛЕЛЬ', 'ФРАНЦИЯ', 0.1715, 0.2813),
    ('МЕРИДИАН', 'ВЕНЕЦИЯ', 0.18, 0.355),
    ('ШИРОТА', 'СТАМБУЛ', 0.18, 0.3792),
    ('ДОЛГОТА', 'БАРСЕЛОНА', 0.18, 0.3813),
    ('ЛИТОСФЕРА', 'ПЕКИН', 0.24, 0.4633),
    ('ИЗОТЕРМА', 'ПАНАМСКИЙ КАНАЛ', 0.28, 0.5589),
    ('ИЗОБАРА', 'СУЭЦКИЙ КАНАЛ', 0.28, 0.5978),
    ('ЭСТУАРИЙ', 'ФЛОРЕНЦИЯ', 0.2877, 0.7043),
)
GEOGRAPHY_ORIGINAL_SCORES = {
    word: score
    for term, place, term_score, place_score in GEOGRAPHY_REBALANCE_PAIRS
    for word, score in ((term, term_score), (place, place_score))
}


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
    for entry in additions:
        answer = normalized(entry['answer'])
        assert answer not in used, ('Duplicate expansion answer', entry['answer'])
        used.add(answer)
        assert answer not in normalized(entry['hint']), ('Hint reveals answer', entry['answer'])
        low, high = bounds[entry[band_key]]
        # Expansion bands record the original batch, before later rebalancing.
        score = difficulty(entry, language)
        if language == 'ru':
            score = GEOGRAPHY_ORIGINAL_SCORES.get(entry['answer'], score)
        assert low <= score < high, entry['answer']
    # Editorial metadata must not increase the runtime payload.
    words, hints = rendered(catalog)
    assert not {'entries', 'difficulty_band', 'central_band', 'assessment'} & words.keys()
    assert set(hints) == {'hints'}


def verify_medium_hard_expansion(catalog, language):
    """The 2026-09-28 batch adds 100 fresh answers to every theme."""
    batch = 'editorial_expansion_20260928'
    additions = [e for e in catalog['entries'] if e.get('assessment') == batch]
    assert len(additions) == 1000, (language, 'Expansion size', len(additions))
    assert Counter(e['theme_id'] for e in additions) == {t: 100 for t in range(1, 11)}

    def normalized(text):
        return re.sub(r'[^A-ZА-Я]', '', text.upper().replace('Ё', 'Е'))

    # Uniqueness is language-wide, not per theme.
    used = {normalized(e['answer']) for e in catalog['entries']
            if e.get('assessment') != batch}
    for entry in additions:
        answer = normalized(entry['answer'])
        assert answer not in used, ('Expansion duplicate', language, entry['answer'])
        used.add(answer)
        assert answer not in normalized(entry['hint']), ('Answer in hint', entry['answer'])
        score = difficulty(entry, language)
        assert .42 <= score < .78, (entry['answer'], score)
        assert entry['expansion_band'] == ('hard' if score >= .58 else 'medium')
    for theme in range(1, 11):
        assert {e['expansion_band'] for e in additions if e['theme_id'] == theme} == {'medium', 'hard'}


def verify_high_difficulty_en_expansion(catalog, language):
    """245 English additions, with equal coverage of the requested hard range."""
    batch = 'editorial_hard_expansion_20260929'
    additions = [e for e in catalog['entries'] if e.get('assessment') == batch]
    if language != 'en':
        assert not additions, 'English expansion must not change Russian content'
        return
    themes = {2, 3, 4, 5, 8, 9, 10}
    assert Counter(e['theme_id'] for e in additions) == {t: 35 for t in themes}
    expected_scores = [round(.78 + .12 * i / 34, 4) for i in range(35)]
    for theme in themes:
        actual = sorted(difficulty(e, language) for e in additions if e['theme_id'] == theme)
        assert actual == expected_scores, ('Hard range distribution', theme, actual)
    def normalized(text):
        return re.sub(r'[^A-Z]', '', text.upper())
    used = {normalized(e['answer']) for e in catalog['entries']
            if e.get('assessment') != batch}
    for entry in additions:
        answer = normalized(entry['answer'])
        assert answer not in used, ('Hard expansion duplicate', entry['answer'])
        used.add(answer)
        assert answer not in normalized(entry['hint']), ('Answer in hint', entry['answer'])
        assert difficulty(entry, language) == entry['target_difficulty'], entry['answer']
        assert 'minimum' not in entry and 'maximum' not in entry, entry['answer']



def verify_apostrophe_policy(catalog, language):
    """ASCII apostrophe is valid; typographic lookalikes must fail validation."""
    if language != 'en':
        return
    ascii_entries = [e for e in catalog['entries'] if "'" in e['answer']]
    assert ascii_entries, 'Expected at least one English answer with an ASCII apostrophe'
    broken = copy.deepcopy(catalog)
    target_id = ascii_entries[0]['id']
    target = next(e for e in broken['entries'] if e['id'] == target_id)
    target['answer'] = target['answer'].replace("'", "’", 1)
    try:
        validate(broken)
    except AssertionError as exc:
        assert 'Use ASCII apostrophe' in str(exc), exc
    else:
        raise AssertionError('Typographic apostrophe unexpectedly passed word validation')

def main():
    for language in ('ru', 'en'):
        catalog = json.loads((ROOT / f'data/word_catalog_{language}.json').read_text())
        validate(catalog)
        verify_apostrophe_policy(catalog, language)
        verify_easy_expansion(catalog, language)
        manifest = json.loads((ROOT / 'data/word_content_migration_v2.json').read_text())
        historical = copy.deepcopy(catalog)
        historical['entries'] = [e for e in catalog['entries']
                                 if e.get('assessment') != 'editorial_dedup_replacement_20261004']
        historical['entries'] += [m['retired'] for m in manifest['merges']
                                  if m['language'] == language]
        verify_expansion(
            historical, language, 'editorial_expansion_patch09', 'difficulty_band',
            {1: (0.0, .30), 2: (.30, .42), 3: (.42, .52), 4: (.52, 1.0)},
            {1: 25, 2: 15, 3: 7, 4: 3},
        )
        verify_expansion(
            historical, language, 'editorial_expansion_patch10', 'central_band',
            {'lower': (.35, .42), 'core': (.42, .54), 'upper': (.54, .65)},
            {'lower': 15, 'core': 25, 'upper': 10},
        )
        verify_medium_hard_expansion(historical, language)
        verify_high_difficulty_en_expansion(historical, language)
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
            assert all('aliases' not in entry for entry in catalog['entries'])
            for term, place, term_score, place_score in GEOGRAPHY_REBALANCE_PAIRS:
                assert byword[term]['theme_id'] == byword[place]['theme_id'] == 2
                assert difficulty(byword[term], language) == place_score, term
                assert difficulty(byword[place], language) == term_score, place
            assert len(byword) == 7499
            assert difficulty(byword['ПОДСОЛНУХ'], language) < .3
            assert difficulty(byword['БЕГОВАЯ ДОРОЖКА'], language) < .3
            for word in ('АТОМ', 'КОЛБА', 'ПРОБИРКА'):
                assert difficulty(byword[word], language) < .4
            assert sum(c.isalpha() for c in byword['БЕСПРОВОДНЫЕ НАУШНИКИ']['answer']) == 20
            assert 'ПОЛОВИННАЯ НОТА' in byword
            for removed_note in ('ЦЕЛАЯ НОТА', 'ЧЕТВЕРТНАЯ НОТА', 'ВОСЬМАЯ НОТА'):
                assert removed_note not in byword
        else:
            byword = {e['answer']: e for e in catalog['entries']}
            assert len(byword) == 7189
            assert 'GLUON' not in byword and 'ETERNAL SUNSHINE' not in byword
            renamed_apostrophe_answers = {
                "RUBIK'S CUBE": 'RUBIKS CUBE',
                "PAN'S LABYRINTH": 'PANS LABYRINTH',
                "THE QUEEN'S GAMBIT": 'THE QUEENS GAMBIT',
                "HUNDRED YEARS' WAR": 'HUNDRED YEARS WAR',
            }
            for current, legacy in renamed_apostrophe_answers.items():
                assert current in byword and legacy not in byword
            assert all('aliases' not in entry for entry in catalog['entries'])
            assert difficulty(byword["CAPTAIN'S ARMBAND"], language) < .4
            assert 'crustacean' not in byword['GROUPER']['hint'].lower()
        print(f'{language}: export, stable IDs, reorder/delete invariance, editorial calibration OK')


if __name__ == '__main__':
    main()
