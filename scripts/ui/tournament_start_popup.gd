extends Node
## A durable tournament starts with this introduction; its action only dismisses it.
const GROUP: StringName = &"tournament_start_popup"
const TROPHY = preload("res://assets/tournament/start_trophy_low.png")
const PEDESTAL = preload("res://assets/tournament/start_pedestal.png")
const COIN_RAIN = preload("res://scripts/ui/tournament_coin_rain.gd")
const CURTAIN = preload("res://assets/tournament/red_curtain.png")
const MASK = preload("res://scripts/ui/rounded_rect_texture_mask.gdshader")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const CLOCK_ICON = preload("res://scripts/ui/timer_clock_icon.gd")
var host: Node
var popup: CanvasLayer
var action: Control
var countdown: Label
var _sparkles: Control
var _closed := false

static func present_after_home_return(target: Node, generation: int) -> void:
	while true:
		if !is_instance_valid(target) or !target.is_inside_tree() \
			or target.result_transition_generation != generation \
			or !is_instance_valid(target._home_logo_reveal) or !GameState.is_tournament_unlocked():
			return
		if !target.get_tree().get_nodes_in_group(GROUP).is_empty():
			return
		if GameState.has_accepted_legal_documents() \
			and !is_instance_valid(target._home_transition) \
			and target.get_tree().get_nodes_in_group(target.PORTRAIT_MODAL_POPUP_GROUP).is_empty():
			break
		# Consent or another Home-owned popup must finish first. Leaving this
		# Home generation cancels the request before it can affect another page.
		await target.get_tree().process_frame
	var snapshot := GameState.get_tournament_snapshot()
	# The previous tournament's mandatory prize takes precedence over a new intro.
	if str(snapshot.phase) == "finished" and int(snapshot.reward) > 0:
		return
	present(target)

static func present(target: Node) -> bool:
	if !target.get_tree().get_nodes_in_group(GROUP).is_empty():
		return true
	if !target.get_tree().get_nodes_in_group(target.PORTRAIT_MODAL_POPUP_GROUP).is_empty():
		return false
	var snapshot: Dictionary = GameState.get_tournament_snapshot()
	if str(snapshot.phase) != "active" and !GameState.start_tournament():
		target._show_portrait_status_toast(TranslationServer.translate("TOURNAMENT_SAVE_ERROR"))
		return false
	var prompt: Node = load("res://scripts/ui/tournament_start_popup.gd").new()
	prompt.host = target
	prompt.name = "TournamentStartPrompt"
	target.content.add_child(prompt)
	prompt._build()
	return true

func _build() -> void:
	var panel_rect := Rect2(48, 236, 384, 168)
	var description_rect := Rect2(56, 421, 368, 100)
	var description_gap: float = description_rect.position.y - panel_rect.end.y
	var button_rect: Rect2 = host._portrait_popup_button_rect(Rect2(90, 0, 300, 56))
	var popup_bottom: float = description_rect.end.y + description_gap + button_rect.size.y + host.PORTRAIT_POPUP_BOTTOM_BUTTON_GAP
	var rect := Rect2(28, 145, 424, popup_bottom - 145.0)
	var previous: Control = host._portrait_popup_begin("TournamentStartPopup", str(GROUP), 140,
		_go, rect.position.y, rect.end.y, false, Callable(), false)
	var stage: Control = host.content
	popup = stage.get_parent().get_parent() as CanvasLayer
	host._portrait_popup_shell(rect, tr("TOURNAMENT_START_TITLE"), _go, 28,
		host.PORTRAIT_BLUE, host.PORTRAIT_DARK_BLUE, host.PORTRAIT_ORANGE, "", true)
	var panel: Control = host._stage_panel(panel_rect,
		host.PORTRAIT_UI_PALETTE.THEME_CARD, host.PORTRAIT_REFILL_STATUS_CORNER_RADIUS)
	panel.name = "TournamentStartDescriptionPanel"
	panel.z_index = 8
	var curtain := TextureRect.new()
	curtain.name = "TournamentStartCurtain"
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.texture = CURTAIN
	curtain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	curtain.stretch_mode = TextureRect.STRETCH_SCALE
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mask := ShaderMaterial.new()
	mask.shader = MASK
	mask.set_shader_parameter("source_size", panel_rect.size)
	mask.set_shader_parameter("mask_rect", Vector4(0, 0, panel_rect.size.x, panel_rect.size.y))
	mask.set_shader_parameter("corner_radius", host.PORTRAIT_REFILL_STATUS_CORNER_RADIUS)
	curtain.material = mask
	panel.add_child(curtain)
	var glow: TextureRect = host._stage_refill_status_glow(panel, panel_rect, Rect2(162, 248, 156, 156), &"TournamentStartRewardGlow")
	glow.modulate = host.PORTRAIT_UI_PALETTE.TOURNAMENT_GLOW
	_build_reward_art(panel_rect)
	var timer_size := Vector2(144, 34) * 0.85
	var timer_rect := Rect2(Vector2(panel_rect.get_center().x, panel_rect.position.y) - timer_size * 0.5, timer_size)
	var timer_plate: Control = host._stage_panel(timer_rect, host.PORTRAIT_UI_PALETTE.TEXT_DARK, timer_size.y * 0.5)
	timer_plate.name = "TournamentStartTimerPlate"
	timer_plate.z_index = 13
	var clock_inset: float = (timer_rect.size.y - 26.0) * 0.5
	var clock_holder: Control = host._stage_holder(Rect2(timer_rect.position + Vector2.ONE * clock_inset, Vector2(26, 26)), Control.MOUSE_FILTER_IGNORE)
	clock_holder.z_index = 14
	var clock: Control = CLOCK_ICON.new()
	clock.name = "TournamentStartClockIcon"
	clock.size = Vector2(26, 26)
	clock_holder.add_child(clock)
	var digits_rect := Rect2(timer_rect.position + Vector2(31, 0), timer_rect.size - Vector2(34, 0))
	countdown = host._stage_label(digits_rect, "", 20, Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER, host.UI_REGULAR_FONT)
	countdown.name = "TournamentStartTimer"
	countdown.z_index = 14
	TEXT_STYLE.apply_regular_display(countdown)
	_update_countdown()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_countdown)
	add_child(timer)
	timer.start()
	var description_holder: Control = host._stage_holder(description_rect, Control.MOUSE_FILTER_IGNORE)
	description_holder.z_index = 11
	var description := RichTextLabel.new()
	description.name = "TournamentStartDescription"
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description.bbcode_enabled = true
	description.scroll_active = false
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	description.add_theme_font_override("normal_font", host.UI_REGULAR_FONT)
	description.add_theme_font_size_override("normal_font_size", 22)
	description.add_theme_color_override("default_color", Color.WHITE)
	description.text = "[center]" + tr("TOURNAMENT_START_DESCRIPTION").replace("{star}",
		"[img=24x24]res://flash_assets/star_currency_icon.png[/img]") + "[/center]"
	host._apply_regular_display_to_rich_text(description_holder, description)
	description_holder.add_child(description)
	action = host._stage_portrait_popup_main_button(Rect2(90, host._portrait_popup_bottom_button_y(rect.end.y, 56.0), 300, 56), _go,
		tr("TOURNAMENT_START_GO"), 22, false, 0.32, false, false, false, host.LONG_BUTTON_COLOR_ORANGE)
	action.name = "TournamentStartGo"
	action.z_index = 16
	action.set("drop_shadow_enabled", true)
	host.content = previous

func _build_reward_art(panel_rect: Rect2) -> void:
	var art: Control = host._stage_holder(panel_rect, Control.MOUSE_FILTER_IGNORE)
	art.name = "TournamentStartArtwork"
	art.z_index = 11
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.clip_contents = true
	var rain: Control = COIN_RAIN.new()
	rain.name = "TournamentStartCoinRain"
	rain.size = panel_rect.size
	art.add_child(rain)
	_reward_texture(art, "TournamentStartPedestal", PEDESTAL, Rect2(127, 135, 130, 52))
	_reward_texture(art, "TournamentStartTrophy", TROPHY, Rect2(122, 19, 140, 136))
	_sparkles = Control.new()
	_sparkles.name = "TournamentStartTrophySparkles"
	_sparkles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sparkles.position = Vector2(143, 32)
	_sparkles.size = Vector2(98, 76)
	art.add_child(_sparkles)
	host._play_reward_coin_sparkles(_sparkles)

func _reward_texture(parent: Control, node_name: String, texture: Texture2D, rect: Rect2) -> void:
	var icon := TextureRect.new()
	icon.name = node_name
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = rect.position
	icon.size = rect.size
	parent.add_child(icon)

func _update_countdown() -> void:
	if _closed or !is_instance_valid(countdown):
		return
	var remaining: int = int(GameState.get_tournament_snapshot().get("remaining", 0))
	countdown.text = "%02d:%02d:%02d" % [remaining / 3600, (remaining % 3600) / 60, remaining % 60]
	if remaining <= 0:
		# Defer because the initial countdown also runs while the popup is built.
		_go.call_deferred()

func _go() -> void:
	if _closed:
		return
	_closed = true
	_remove_popup()
	queue_free()

func _remove_popup() -> void:
	if is_instance_valid(popup):
		popup.hide()
		popup.remove_from_group(GROUP)
		popup.remove_from_group(host.PORTRAIT_MODAL_POPUP_GROUP)
		popup.queue_free()
	popup = null

func _exit_tree() -> void:
	if is_instance_valid(_sparkles) and is_instance_valid(host):
		host._stop_reward_coin_sparkles(_sparkles)
	_remove_popup()
