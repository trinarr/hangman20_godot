# Word database update — 2026-10-04

Baseline: public 1.0 archive `hangman-2.0(20261004-094221).zip` (tracked HEAD `352df1c`). Apply this patch directly to that archive, without applying the earlier editorial patches again.

## Content

- NEUTRAL DENSITY keeps its answer and ID. New hint: “The light-reducing property of a camera filter designed to preserve colour balance.”
- CHEESE PANCAKE keeps its answer and ID. New hint: “A small pancake made from curd cheese, fried until golden and often served with sour cream or jam.”
- Remove the secondary active records in audit pairs 062–105: 19 EN and 25 RU.
- Add 44 genuinely new records with new IDs in the same language/theme and with exactly the retired record's model-3 difficulty, to four decimal places. The catalog's starting concept scores remain editorial estimates, not measured player difficulty. The total and per-theme counts remain unchanged: RU 5999, EN 5689.
- The user-selected canonical records are ГРИВИСТЫЙ ВОЛК, ДЖОМОЛУНГМА, ДЕКАБРИСТ, СТРЕЛЕЦ. Other canonical choices follow the updated audit.
- Retired records are absent from the active catalogs/exports. Their old data is retained only in the compatibility manifest, so an interrupted round can still finish.

## Save migration

Save format advances from 2 to 3; content version advances from 1 to 2. This is unrelated to the app-store version/name and does not change store metadata.

`word_content_migration.gd` migrates before normal save normalization:

- Classic played/guessed flags are OR-merged into the retained record.
- Level history merges counts, guessed/played flags and recent keys; old keys are removed. New replacement words receive no inherited history.
- Same-theme last_seen values share a sequence and can use max. Cross-theme sequences cannot be compared: the imported display is conservatively appended to the destination sequence, without treating the source sequence as a timestamp.
- Completed/assigned words and active snapshots get stable identities and current indices for surviving entries. Retired snapshots get index -1 and their original identity; the runtime accepts them from the compatibility archive only.
- The old word, revealed positions, guesses, mistakes, round_id, attempt offer and purchased hint state stay intact. Finishing an archived word credits its retained concept, including cross-theme pairs.
- Migration runs once through the versioned pipeline; subsequent loads do not sum counters again. Primary, temp and backup files use the same pipeline. Currency, hearts, level/reward states and rewarded receipts are not reset.
- An old snapshot keeps its stored hint text; the two new English hints apply to newly selected rounds. If an old snapshot has no hint, a matching record supplies it, never an unrelated word at the old index.
- New snapshots persist word_id and content_version. The manifest is explicitly included in the Android export filter; no editorial catalogs are added to the release package.

No global history redesign is included: after deduplication each of these 44 concepts has one active record, so the eliminated alternate no longer appears in another theme. Existing history remains separated by language and theme.

## Replacement map

D is the numeric model-3 difficulty. New words are unseen even when the retired word had been played.

| Audit | Language | Theme of replacement | Removed | Retained | New word | D |
|---|---|---:|---|---|---|---:|
| 062 | EN | 8 | DECOLONIZATION | DECOLONISATION | MANOR COURT | 0.4529 |
| 063 | EN | 6 | CARAMELIZATION | CARAMELISATION | MOTHER SAUCE | 0.7373 |
| 064 | EN | 4 | VOLTAGE STABILIZER | VOLTAGE STABILISER | RING LIGHT | 0.4808 |
| 065 | EN | 5 | PALEONTOLOGIST | PALAEONTOLOGIST | NUMISMATIST | 0.7297 |
| 066 | EN | 5 | COLORIST | COLOURIST | BUSKER | 0.2504 |
| 067 | EN | 9 | EBOOK READER | E-READER | DOUBLE BIND | 0.6096 |
| 068 | EN | 9 | MICROWAVE | MICROWAVE OVEN | BOOKEND | 0.1731 |
| 069 | EN | 4 | THERMAL IMAGER | THERMAL CAMERA | LINEAR BEARING | 0.5088 |
| 070 | EN | 9 | HYBRID WORKING | HYBRID WORK | DECISION FATIGUE | 0.5592 |
| 071 | EN | 9 | BRAINSTORM | BRAINSTORMING | ERRAND | 0.2362 |
| 072 | EN | 6 | PASTRY BAG | PIPING BAG | DOUGH SCRAPER | 0.5136 |
| 073 | EN | 7 | WAVE INTERFERENCE | INTERFERENCE | MAGNETOSTRICTION | 0.7100 |
| 074 | EN | 3 | PLANT POLLINATION | POLLINATION | NURSE SHARK | 0.3419 |
| 075 | EN | 3 | TREE CANOPY | CANOPY | BASKING SHARK | 0.3973 |
| 076 | EN | 3 | FOREST CLEARING | CLEARING | TIDE POOL | 0.2413 |
| 077 | EN | 3 | FALLING LEAVES | LEAF FALL | STARLING | 0.2068 |
| 078 | EN | 1 | PACEMAKER | PACER | PHOTO FINISH | 0.5051 |
| 079 | EN | 5 | CONSERVATOR | ART CONSERVATOR | BELLHOP | 0.2435 |
| 080 | EN | 8 | CRUSADES | CRUSADE | CASTLE KEEP | 0.2081 |
| 081 | RU | 3 | ГРИВАСТЫЙ ВОЛК | ГРИВИСТЫЙ ВОЛК | ЛЕЖБИЩЕ | 0.3865 |
| 082 | RU | 2 | АЗОРЫ | АЗОРСКИЕ ОСТРОВА | КУРОСИО | 0.4400 |
| 083 | RU | 2 | ДОЛОМИТОВЫЕ АЛЬПЫ | ДОЛОМИТЫ | ПУНА | 0.5238 |
| 084 | RU | 2 | ГОРА ЭВЕРЕСТ | ДЖОМОЛУНГМА | АТЛАС | 0.2018 |
| 085 | RU | 3 | МИЦЕЛИЙ | ГРИБНИЦА | ТРАВИНКА | 0.2200 |
| 086 | RU | 1 | СУДЕЙСКИЙ СВИСТОК | СВИСТОК | БРОСОК С ОТКЛОНЕНИЕМ | 0.7274 |
| 087 | RU | 1 | СТРЕТЧИНГ | РАСТЯЖКА | НАПУЛЬСНИК | 0.3222 |
| 088 | RU | 1 | ВНЕ ИГРЫ | ОФСАЙД | ПЕРЕИГРОВКА | 0.5069 |
| 089 | RU | 1 | КРУГОВОЙ ТУРНИР | КРУГОВАЯ СИСТЕМА | ПРИЕМ ПОДАЧИ | 0.5267 |
| 090 | RU | 4 | КАРДАН | КАРДАННЫЙ ВАЛ | ШАРНИР | 0.2444 |
| 091 | RU | 4 | КОЛЕНВАЛ | КОЛЕНЧАТЫЙ ВАЛ | ОБГОННАЯ МУФТА | 0.5072 |
| 092 | RU | 4 | СХОД-РАЗВАЛ | РАЗВАЛ-СХОЖДЕНИЕ | ОПТОПАРА | 0.5784 |
| 093 | RU | 4 | ОПТИЧЕСКИЙ КАБЕЛЬ | ОПТОВОЛОКОННЫЙ КАБЕЛЬ | ЗАКЛЕПОЧНИК | 0.4356 |
| 094 | RU | 9 | РОУТЕР | МАРШРУТИЗАТОР | ВИЗИТКА | 0.2125 |
| 095 | RU | 5 | ПРОДУКТ-МЕНЕДЖЕР | ПРОДАКТ-МЕНЕДЖЕР | ЛОКАЛИЗАТОР | 0.5428 |
| 096 | RU | 5 | МЕНТОР | НАСТАВНИК | КИНОМЕХАНИК | 0.4289 |
| 097 | RU | 5 | РЕЧЕВОЙ ТЕРАПЕВТ | ЛОГОПЕД | ПРОТЕЗИСТ | 0.5058 |
| 098 | RU | 6 | ТХИНА | ТАХИНИ | МИРИН | 0.5091 |
| 099 | RU | 9 | ГИБРИДНЫЙ ГРАФИК | ГИБРИДНАЯ РАБОТА | ОТЛОЖЕННЫЙ СПРОС | 0.5557 |
| 100 | RU | 6 | ГРЕЧНЕВАЯ КРУПА | ГРЕЧКА | МЯКИШ | 0.2341 |
| 101 | RU | 3 | ДРЕВЕСНАЯ КРОНА | КРОНА | КОМЕЛЬ | 0.3882 |
| 102 | RU | 7 | РЕАКТИВ | РЕАГЕНТ | БУФЕРНЫЙ РАСТВОР | 0.4104 |
| 103 | RU | 8 | ДЕКАБРИСТЫ | ДЕКАБРИСТ | МЕСТНИЧЕСТВО | 0.5195 |
| 104 | RU | 8 | СТРЕЛЬЦЫ | СТРЕЛЕЦ | ЗАСЕЧНАЯ ЧЕРТА | 0.5049 |
| 105 | RU | 8 | БОЛЕАДОРАС | БОЛАС | СФРАГИСТИКА | 0.8717 |

## Verification

All content exports and the word, quiz, theme, game-design, optimization/resource-reference and save-integrity Python verifiers passed. The five quiz editorial unit tests also passed. `verify_word_content_migration.py` checks all 44 replacement identities, exact difficulties, theme quotas and the four explicit canonical choices.

Godot 4.6 stable, Linux headless, disposable user-data directories:

- `word_content_migration`: 1059 checks, 0 failures, no script errors. Covers all 44 merges, classic/level flags, counters, recency, repeated loads, archived rounds, stable IDs, surviving indices, paid hints, attempt offers, untouched economy/receipts and recovery from a v2 backup.
- `word_selection`: 23 checks, 0 failures.
- `save_recovery`: 51 checks across independent processes, 0 failures.

The wider pre-existing suites still have identical failures on the original supplied archive and on this patch:

| Suite | Checks | Failures before | Failures after |
|---|---:|---:|---:|
| release_reward_regression | 42 | 2 | 2 |
| resume_flow | 18 | 1 | 1 |
| rewards | 217 | 34 | 34 |

The release regression fails “tagged late callback reaches original hint” and “second UI request can load”. The resume suite expects a heart loss in level 1 even though the released game protects the first two levels. The larger rewards suite has outdated reward/UI expectations. These production behaviors and unrelated tests are not changed by this content patch. The release-regression word fixture now uses an actual database word and ID, so its save/restore check remains meaningful with identity validation.

`git diff --check` and clean-archive `git apply --check` passed. The patch was applied to a clean copy of the supplied baseline; all 21 changed files matched the prepared source byte for byte, the content/save verifiers passed, and the migration suite again passed all 1059 checks. No device UI inspection or Android store build is claimed.

Reproduce focused tests after editor import:

```sh
python tools/verify_word_content_migration.py
python tools/run_content_tests.py --godot /path/to/godot --suite word_content_migration
python tools/run_content_tests.py --godot /path/to/godot --suite word_selection
python tools/run_reward_tests.py --godot /path/to/godot --suite save_recovery
```

Selective references for specialized new definitions: [Florida Museum — nurse shark](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/nurse-shark/), [Vishay — optical isolators](https://www.vishay.com/en/optocouplers/), [Kikkoman — mirin](https://www.kikkoman.com/en/cookbook/glossary/mirin.html). The replacement text was reviewed for language and distinction from existing words; the references are not an independent fact-check of every record in the full database.
