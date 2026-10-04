# Portrait large stage reward extraction

Apply `hangman_20261004_portrait_stage_reward_component.patch` after
`hangman_20261004_portrait_round_result_component.patch`.

`portrait_stage_reward.gd` owns the large stage coin reward body: coin pack and
extrusion shadow, amount, glow, x2/Continue and No Thanks controls, transition
from the chain tile, pack bounce, sparkle loop and action reveal. It receives a
parent, reward amount and source rectangle. The shared chain/header frame stays
in the existing chain builder. The component emits `claim_peak`,
`double_requested` and `continue_requested`; it neither reads GameState or
GameSession nor performs saves, ad calls or navigation.

Shared prize visuals move into `portrait_reward_prize.gd`, built on the small
`portrait_presentation.gd` renderer. Level rewards and other existing prize
presentations use thin main adapters to the same visual helper; their claim
callbacks and default navigation actions remain in main. This avoids duplicating
coin/glow/action code between stage and level rewards. The save-integrity
validator now checks the actual relocated bounce/reveal implementations.

The main adapter still marks durable presentation before building the screen,
claims coins at the pack growth peak, handles original rewarded request IDs and
late receipts, and resolves the offer. It retains the existing single-stage and
last-stage routing. No save migration or economy/config/data changes are needed.

Screen disposal explicitly stops the components, their tracked animations,
sparkles and action feedback. Stage transition phases use owned completion
callbacks; repeated build/transition/peak requests are ignored. Deferred chain
intro dispatch checks generation and argument validity before passing Controls
into its typed method, including an immediate close before intro starts.

Verification:
- 37 focused stage/prize checks pass with no script/runtime errors, including
  normal and ad offers, exactly-once peak credit, durable flags, decline,
  interrupted presentation settlement, one-stage offers, shared level coin/star
  grants, standalone operation after adapter deletion and animation cancellation.
- The first 26 shared checks also pass on the preceding baseline; both serialized
  visual signatures (ad offer and ordinary Continue) match exactly. The result
  suite's 29 checks and three matching visual signatures remain valid.
- Existing popup (46), visual helper (61), letter feedback (40) and runtime
  optimization (49) checks pass. Save-integrity, game-design config and runtime
  resource/catalog validators pass.
- Legacy broad suites have identical existing failures on both snapshots:
  release_reward_regression 42 checks / 2 failures; resume_flow 18 / 1; rewards
  217 / 34. These are not claimed as passing. The headless dummy renderer can
  also intermittently report a texture initialization diagnostic during
  headless tests; it originates in the existing display-text renderer.
- Godot 4.6 stable headless was used (the project declares 4.7). Comparisons are
  node/property checks, not screenshots or Android/native-ad testing.
- Both incremental patches were independently checked/applied and byte-compared.
