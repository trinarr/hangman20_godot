extends "res://scripts/ui/portrait_stage_reward.gd"
## Presents an already persisted tournament award using campaign reward visuals.
var _host: Node
var _gift := false

func present(host: Node, parent: Control, award: Dictionary) -> void:
	_host = host
	_gift = int(award.rank) == 1
	var prize_size: Vector2 = host.PORTRAIT_LEVEL_COMPLETION_CHEST_SIZE if _gift else PORTRAIT_FINAL_REWARD_COIN_SIZE
	var rect := _portrait_final_reward_center_rect(prize_size)
	build(parent, int(award.amount), rect, false)
	prize.name = "TournamentGift" if _gift else "TournamentCoins"
	FADE.set_opacity(prize, 1.0)
	if _gift:
		prize_amount.set("stage_rect", host._portrait_level_completion_amount_rect(rect))
	_reveal_stage_reward(prize, prize_glow, prize_amount, action, collect, collect_hit)

func _stage_main_reward_coin_pack_transition(rect: Rect2) -> Control:
	if _gift:
		return _host._stage_reward_chest_transition(rect)
	return super._stage_main_reward_coin_pack_transition(rect)

func _reveal_stage_reward(pack: Control, glow: Control, amount_label: Label, button: Control, collect_holder: Control, collect_button: Button) -> void:
	if _stopped or !is_inside_tree():
		return
	if _gift:
		_start_final_reward_glow_rotation(glow)
		_host._play_level_completion_chest_pressure_burst(pack, glow, amount_label, Callable(self, "_gift_opened"))
	else:
		super._reveal_stage_reward(pack, glow, amount_label, button, collect_holder, collect_button)

func _gift_opened() -> void:
	if _stopped or !is_inside_tree():
		return
	_on_claim_peak(prize)
	_reveal_final_reward_actions(action, collect, collect_hit)
