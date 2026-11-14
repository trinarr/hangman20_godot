extends Node
## Resource counter presentation. Receives an explicit render parent and bounded callbacks.
## Currency grants, save operations and navigation belong to the game controller.

const LAYOUT = preload("res://scripts/ui/portrait_stage_layout.gd")

var state := CounterState.new()
var content: Control
var render: Callable
var actions: Dictionary

const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")
const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")
var UI_REGULAR_FONT: Font = UI_FONTS.regular_font()
const SOFT_CURRENCY_COIN_TEXTURE: Texture2D = preload("res://flash_assets/soft_currency_coin.png")
const STAR_CURRENCY_TEXTURE: Texture2D = preload("res://flash_assets/star_currency_icon.png")
const LIFE_HEART_ICON_TEXTURE: Texture2D = preload("res://flash_assets/life_heart_icon.png")
const RESOURCE_COUNTER_STYLE = preload("res://scripts/ui/resource_counter_style.gd")
const PORTRAIT_GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")
const PORTRAIT_UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const PORTRAIT_COIN_COUNTER_ANCHOR = preload("res://scripts/ui/portrait_coin_counter_anchor.gd")
const PORTRAIT_STAGE_SIZE = LAYOUT.PORTRAIT_STAGE_SIZE
const PORTRAIT_LONG_BUTTON_SIZE = LAYOUT.PORTRAIT_LONG_BUTTON_SIZE
const PORTRAIT_ROUND_BUTTON_SIZE = LAYOUT.PORTRAIT_ROUND_BUTTON_SIZE
const PORTRAIT_PAGE_BACK_BUTTON_SCALE = LAYOUT.PORTRAIT_PAGE_BACK_BUTTON_SCALE
const PORTRAIT_PAGE_BACK_BUTTON_SIZE = LAYOUT.PORTRAIT_PAGE_BACK_BUTTON_SIZE
const PORTRAIT_PAGE_BACK_BUTTON_RECT = LAYOUT.PORTRAIT_PAGE_BACK_BUTTON_RECT
const PORTRAIT_HOME_AVATAR_SIZE = LAYOUT.PORTRAIT_HOME_AVATAR_SIZE
const PORTRAIT_HOME_AVATAR_RECT = LAYOUT.PORTRAIT_HOME_AVATAR_RECT
const PORTRAIT_RESOURCE_COUNTER_GAP: float = 5.0
const PORTRAIT_RESOURCE_COUNTER_PANEL_TRAILING_INSET: float = RESOURCE_COUNTER_STYLE.TRAILING_INSET
const PORTRAIT_RESOURCE_COUNTER_FONT_SCALE: float = RESOURCE_COUNTER_STYLE.FONT_SCALE
const PORTRAIT_CURRENCY_COUNTER_RECT = LAYOUT.PORTRAIT_CURRENCY_COUNTER_RECT
const PORTRAIT_HOME_RESOURCE_COUNTER_WIDTH: float = PORTRAIT_CURRENCY_COUNTER_RECT.size.x
const PORTRAIT_CURRENCY_ICON_SIZE: float = RESOURCE_COUNTER_STYLE.ICON_SIZE
const PORTRAIT_RESOURCE_COUNTER_ICON_X_SHIFT: float = PORTRAIT_CURRENCY_ICON_SIZE * 0.28
const PORTRAIT_HEART_ICON_ASPECT_RATIO: float = 1.0
const PORTRAIT_HEART_ICON_LEFT_INSET: float = 2.0
const PORTRAIT_CURRENCY_COUNTER_PRESSED_SCALE: float = 0.94
var PORTRAIT_CURRENCY_COUNTER_PRESS_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.counter_press_seconds"
)
var PORTRAIT_CURRENCY_COUNTER_RELEASE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.counter_release_seconds"
)
const PORTRAIT_CURRENCY_ADD_BADGE_SIZE: float = 20.0
const PORTRAIT_CURRENCY_ADD_BADGE_GREEN := PORTRAIT_UI_PALETTE.SUCCESS
const PORTRAIT_CURRENCY_ADD_BADGE_BORDER := PORTRAIT_UI_PALETTE.SUCCESS_BORDER
var PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_PEAK_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.icon_peak_scale"
)
var PORTRAIT_CURRENCY_COUNTER_REWARD_BOUNCE_PEAK_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.counter_peak_scale"
)
var PORTRAIT_CURRENCY_COUNTER_REWARD_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.counter_grow_seconds"
)
var PORTRAIT_CURRENCY_COUNTER_REWARD_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.counter_settle_seconds"
)
var PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.icon_bounce_grow_seconds"
)
var PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.icon_bounce_settle_seconds"
)
const PORTRAIT_DARK_BLUE := PORTRAIT_UI_PALETTE.UI_BLUE_DARK
const PORTRAIT_CHALLENGE_HUD_PANEL := PORTRAIT_UI_PALETTE.CHALLENGE_HUD_PANEL
var _portrait_top_bar_content: Control = null
var _portrait_coin_store_active: bool = false

func _portrait_resource_counter_panel_rect(
	counter_rect: Rect2
) -> Rect2:
	return RESOURCE_COUNTER_STYLE.panel_rect(counter_rect)

func _stage_top_bar_resource_icon(
	icon_rect: Rect2,
	texture: Texture2D,
	prefix: String
) -> Control:
	# Keep the stage-mapped holder as the animated resource icon so existing
	# counter/bounce tweens scale the artwork and its extrusion shadow together.
	var holder: Control = _stage_holder(icon_rect, Control.MOUSE_FILTER_IGNORE)
	holder.name = "%sHolder" % prefix
	# The counter plate itself uses z=20. The holder stays on that plane while
	# its relative child z-indices put the shadow above the plate and the icon
	# at the same effective depth the old stage texture used.
	holder.z_index = 20
	_add_portrait_icon_with_extrusion_to_holder(
		holder,
		texture,
		prefix,
		1,
		RESOURCE_COUNTER_STYLE.ICON_SHADOW_ALPHA,
		1.0
	)
	return holder

func _stage_currency_counter(
	return_action: Callable,
	rect: Rect2 = Rect2(),
	challenge_colors: bool = false,
	interactive: bool = true
) -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var counter_rect: Rect2 = rect if rect.size.x > 0.0 and rect.size.y > 0.0 else PORTRAIT_CURRENCY_COUNTER_RECT
	state._portrait_active_currency_counter_rect = counter_rect
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_UI_PALETTE.with_alpha(
		PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE,
		PORTRAIT_UI_PALETTE.RESOURCE_COUNTER_OPACITY
	)
	# Keep resource counters pressable in the shop as well. Their action is
	# resolved centrally below so pressing them while the shop is already open
	# only plays the normal press feedback instead of rebuilding the same screen.
	var counter_is_interactive: bool = interactive and _portrait_ads_enabled()
	var counter_parent_content: Control = content
	var counter_visual := Control.new()
	counter_visual.name = "CurrencyCounterVisual"
	PORTRAIT_COIN_COUNTER_ANCHOR.register(counter_visual, counter_rect)
	counter_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_parent_content.add_child(counter_visual)
	counter_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	counter_visual.pivot_offset = _portrait_stage_point_to_viewport(
		counter_rect.get_center(),
		counter_visual
	)
	state._portrait_currency_counter_visual = counter_visual
	content = counter_visual
	var icon_rect := Rect2(
		counter_rect.position + Vector2(
			2.0 * counter_scale + PORTRAIT_RESOURCE_COUNTER_ICON_X_SHIFT,
			(counter_rect.size.y - PORTRAIT_CURRENCY_ICON_SIZE) * 0.5
		),
		Vector2(PORTRAIT_CURRENCY_ICON_SIZE, PORTRAIT_CURRENCY_ICON_SIZE)
	)
	var panel_rect: Rect2 = _portrait_resource_counter_panel_rect(counter_rect)
	var panel := _stage_panel(
		panel_rect,
		panel_color,
		panel_rect.size.y * 0.5,
		Color.TRANSPARENT,
		0.0
	)
	panel.z_index = 20
	var coin_icon := _stage_top_bar_resource_icon(
		icon_rect,
		SOFT_CURRENCY_COIN_TEXTURE,
		"TopBarCoinIcon"
	)
	state._portrait_currency_coin_icon_visual = coin_icon
	if counter_is_interactive and !_portrait_coin_store_active:
		_stage_resource_add_badge(icon_rect, counter_scale)
	var balance_left: float = counter_rect.position.x + 43.0 * counter_scale
	var balance_right: float = (
		panel_rect.end.x - PORTRAIT_RESOURCE_COUNTER_PANEL_TRAILING_INSET * counter_scale
	)
	var balance_rect := Rect2(
		Vector2(balance_left, panel_rect.position.y),
		Vector2(maxf(1.0, balance_right - balance_left), panel_rect.size.y)
	)
	var balance_text: String = _soft_currency_balance_text(GameState.get_soft_currency())
	var balance_font_size: int = maxi(1, int(round(
		24.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var balance_min_font_size: int = maxi(1, int(round(
		14.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var balance_label := _stage_label(
		balance_rect,
		balance_text,
		balance_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	balance_label.add_theme_font_override("font", UI_REGULAR_FONT)
	BUTTON_TEXT_STYLE_SCRIPT.apply_regular_display(balance_label)
	balance_label.add_to_group(&"soft_currency_balance_label")
	balance_label.z_index = 21
	_fit_single_line_label_to_width(balance_label, balance_text, balance_rect.size.x, balance_font_size, balance_min_font_size)
	content = counter_parent_content
	if counter_is_interactive:
		_stage_resource_counter_button(counter_rect, counter_visual, return_action)
	content = screen_content

	var heart_rect := Rect2(
		counter_rect.position + Vector2(counter_rect.size.x + PORTRAIT_RESOURCE_COUNTER_GAP, 0.0),
		counter_rect.size
	)
	_stage_heart_counter(return_action, heart_rect, challenge_colors, interactive)
	# Every screen that exposes the global resources shares the same top bar.
	# Staging Settings here keeps the right corner consistent for main tabs,
	# gameplay, result, shop, and nested pages without per-screen omissions.
	_stage_menu_settings_button()

func _stage_centered_coin_only_counter(
	return_action: Callable,
	rect: Rect2 = Rect2(),
	challenge_colors: bool = false,
	interactive: bool = true,
	center_horizontally: bool = true,
	track_as_active_counter: bool = true,
	direct_action: Callable = Callable()
) -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var source_rect: Rect2 = rect if rect.size.x > 0.0 and rect.size.y > 0.0 else PORTRAIT_CURRENCY_COUNTER_RECT
	var counter_x: float = (
		(PORTRAIT_STAGE_SIZE.x - source_rect.size.x) * 0.5
		if center_horizontally
		else source_rect.position.x
	)
	var counter_rect := Rect2(
		counter_x,
		source_rect.position.y,
		source_rect.size.x,
		source_rect.size.y
	)
	if track_as_active_counter:
		state._portrait_active_currency_counter_rect = counter_rect
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_UI_PALETTE.with_alpha(
		PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE,
		PORTRAIT_UI_PALETTE.RESOURCE_COUNTER_OPACITY
	)
	var counter_is_interactive: bool = interactive and _portrait_ads_enabled()
	var counter_parent_content: Control = content
	var counter_visual := Control.new()
	counter_visual.name = "CurrencyCounterVisual"
	PORTRAIT_COIN_COUNTER_ANCHOR.register(counter_visual, counter_rect)
	counter_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_parent_content.add_child(counter_visual)
	counter_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	counter_visual.pivot_offset = _portrait_stage_point_to_viewport(
		counter_rect.get_center(),
		counter_visual
	)
	state._portrait_currency_counter_visual = counter_visual
	content = counter_visual
	var icon_rect := Rect2(
		counter_rect.position + Vector2(
			2.0 * counter_scale + PORTRAIT_RESOURCE_COUNTER_ICON_X_SHIFT,
			(counter_rect.size.y - PORTRAIT_CURRENCY_ICON_SIZE) * 0.5
		),
		Vector2(PORTRAIT_CURRENCY_ICON_SIZE, PORTRAIT_CURRENCY_ICON_SIZE)
	)
	var panel_rect: Rect2 = _portrait_resource_counter_panel_rect(counter_rect)
	var panel := _stage_panel(
		panel_rect,
		panel_color,
		panel_rect.size.y * 0.5,
		Color.TRANSPARENT,
		0.0
	)
	panel.z_index = 20
	var coin_icon := _stage_top_bar_resource_icon(
		icon_rect,
		SOFT_CURRENCY_COIN_TEXTURE,
		"TopBarCoinIcon"
	)
	state._portrait_currency_coin_icon_visual = coin_icon
	if counter_is_interactive and (!_portrait_coin_store_active or direct_action.is_valid()):
		_stage_resource_add_badge(icon_rect, counter_scale)
	var balance_left: float = counter_rect.position.x + 43.0 * counter_scale
	var balance_right: float = (
		panel_rect.end.x - PORTRAIT_RESOURCE_COUNTER_PANEL_TRAILING_INSET * counter_scale
	)
	var balance_rect := Rect2(
		Vector2(balance_left, panel_rect.position.y),
		Vector2(maxf(1.0, balance_right - balance_left), panel_rect.size.y)
	)
	var balance_text: String = _soft_currency_balance_text(GameState.get_soft_currency())
	var balance_font_size: int = maxi(1, int(round(
		24.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var balance_min_font_size: int = maxi(1, int(round(
		14.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var balance_label := _stage_label(
		balance_rect,
		balance_text,
		balance_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	balance_label.add_theme_font_override("font", UI_REGULAR_FONT)
	BUTTON_TEXT_STYLE_SCRIPT.apply_regular_display(balance_label)
	balance_label.add_to_group(&"soft_currency_balance_label")
	balance_label.z_index = 21
	_fit_single_line_label_to_width(balance_label, balance_text, balance_rect.size.x, balance_font_size, balance_min_font_size)
	content = counter_parent_content
	if counter_is_interactive:
		_stage_resource_counter_button(
			counter_rect,
			counter_visual,
			return_action,
			direct_action
		)
	content = screen_content

func _stage_star_counter(
	counter_rect: Rect2,
	challenge_colors: bool = false
) -> void:
	state._portrait_active_star_counter_rect = counter_rect
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_UI_PALETTE.with_alpha(
		PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE,
		PORTRAIT_UI_PALETTE.RESOURCE_COUNTER_OPACITY
	)
	var counter_parent_content: Control = content
	var counter_visual := Control.new()
	counter_visual.name = "StarCounterVisual"
	counter_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_parent_content.add_child(counter_visual)
	counter_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	counter_visual.pivot_offset = _portrait_stage_point_to_viewport(
		counter_rect.get_center(),
		counter_visual
	)
	state._portrait_star_counter_visual = counter_visual
	content = counter_visual
	var icon_rect := Rect2(
		counter_rect.position + Vector2(
			2.0 * counter_scale + PORTRAIT_RESOURCE_COUNTER_ICON_X_SHIFT,
			(counter_rect.size.y - PORTRAIT_CURRENCY_ICON_SIZE) * 0.5
		),
		Vector2(PORTRAIT_CURRENCY_ICON_SIZE, PORTRAIT_CURRENCY_ICON_SIZE)
	)
	var panel_rect: Rect2 = _portrait_resource_counter_panel_rect(counter_rect)
	var panel := _stage_panel(
		panel_rect,
		panel_color,
		panel_rect.size.y * 0.5,
		Color.TRANSPARENT,
		0.0
	)
	panel.z_index = 20
	icon_rect.position += RESOURCE_COUNTER_STYLE.STAR_ICON_OFFSET
	var star_icon := _stage_top_bar_resource_icon(
		icon_rect,
		STAR_CURRENCY_TEXTURE,
		"TopBarStarIcon"
	)
	state._portrait_star_icon_visual = star_icon
	var balance_rect: Rect2 = RESOURCE_COUNTER_STYLE.value_rect(counter_rect)
	var balance_text: String = _soft_currency_balance_text(GameState.get_stars())
	var balance_font_size: int = maxi(1, int(round(
		24.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var balance_min_font_size: int = maxi(1, int(round(
		14.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var balance_label := _stage_label(
		balance_rect,
		balance_text,
		balance_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	balance_label.add_theme_font_override("font", UI_REGULAR_FONT)
	BUTTON_TEXT_STYLE_SCRIPT.apply_regular_display(balance_label)
	balance_label.add_to_group(&"stars_balance_label")
	balance_label.z_index = 21
	_fit_single_line_label_to_width(
		balance_label,
		balance_text,
		balance_rect.size.x,
		balance_font_size,
		balance_min_font_size
	)
	content = counter_parent_content
	content = screen_content

func _stage_coin_and_star_counters(
	return_action: Callable,
	rect: Rect2 = Rect2(),
	challenge_colors: bool = false,
	interactive: bool = true
) -> void:
	var source_rect: Rect2 = (
		rect
		if rect.size.x > 0.0 and rect.size.y > 0.0
		else PORTRAIT_CURRENCY_COUNTER_RECT
	)
	var total_width: float = source_rect.size.x * 2.0 + PORTRAIT_RESOURCE_COUNTER_GAP
	var coin_rect := Rect2(
		(PORTRAIT_STAGE_SIZE.x - total_width) * 0.5,
		source_rect.position.y,
		source_rect.size.x,
		source_rect.size.y
	)
	_stage_centered_coin_only_counter(
		return_action,
		coin_rect,
		challenge_colors,
		interactive,
		false
	)
	var star_rect := Rect2(
		coin_rect.position + Vector2(coin_rect.size.x + PORTRAIT_RESOURCE_COUNTER_GAP, 0.0),
		coin_rect.size
	)
	_stage_star_counter(star_rect, challenge_colors)

func _stage_home_resource_counters(return_action: Callable) -> void:
	var counters := preload("res://scripts/ui/home_resource_counters.gd").new()
	counters.name = "HomeResourceCounters"
	counters.build_counters = actions[&"_stage_home_resource_counter_content"].bind(return_action)
	_portrait_top_bar_content.add_child(counters)
	_stage_home_avatar_button()

func _stage_home_resource_counter_content(counters: Control, return_action: Callable) -> void:
	var top_bar := _portrait_top_bar_content
	_portrait_top_bar_content = counters
	var counter_size := Vector2(
		PORTRAIT_HOME_RESOURCE_COUNTER_WIDTH,
		PORTRAIT_CURRENCY_COUNTER_RECT.size.y
	)
	var total_width: float = (
		counter_size.x * 3.0 + PORTRAIT_RESOURCE_COUNTER_GAP * 2.0
	)
	var available_start: float = PORTRAIT_HOME_AVATAR_RECT.end.x if GameState.is_single_player_guided_onboarding_completed() else 0.0
	var available_width: float = PORTRAIT_STAGE_SIZE.x - available_start
	var coin_rect := Rect2(
		available_start + (available_width - total_width) * 0.5,
		PORTRAIT_CURRENCY_COUNTER_RECT.position.y,
		counter_size.x,
		counter_size.y
	)
	_stage_centered_coin_only_counter(
		return_action,
		coin_rect,
		false,
		true,
		false
	)
	var heart_rect := Rect2(
		coin_rect.position + Vector2(coin_rect.size.x + PORTRAIT_RESOURCE_COUNTER_GAP, 0.0),
		coin_rect.size
	)
	_stage_heart_counter(return_action, heart_rect)
	var star_rect := Rect2(
		heart_rect.position + Vector2(heart_rect.size.x + PORTRAIT_RESOURCE_COUNTER_GAP, 0.0),
		heart_rect.size
	)
	_stage_star_counter(star_rect)
	_portrait_top_bar_content = top_bar

func _stage_heart_counter(
	return_action: Callable,
	counter_rect: Rect2,
	challenge_colors: bool = false,
	interactive: bool = true
) -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_UI_PALETTE.with_alpha(
		PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE,
		PORTRAIT_UI_PALETTE.RESOURCE_COUNTER_OPACITY
	)
	var resolved_hearts: int = GameState.get_hearts()
	# A full inventory has no available action: omit both the invisible hit area
	# and the plus badge so the complete heart plate behaves as static UI.
	var counter_is_interactive: bool = interactive and resolved_hearts < GameState.MAX_HEARTS
	var counter_parent_content: Control = content
	var counter_visual := Control.new()
	counter_visual.name = "HeartCounterVisual"
	counter_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_parent_content.add_child(counter_visual)
	counter_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = counter_visual
	# Match the coin icon height while preserving the source heart's wider
	# artwork proportions inside its new square 128x128 texture canvas. Keep the
	# complete texture aligned with the coin and star icons.
	var heart_icon_size := Vector2(
		PORTRAIT_CURRENCY_ICON_SIZE * PORTRAIT_HEART_ICON_ASPECT_RATIO,
		PORTRAIT_CURRENCY_ICON_SIZE
	)
	var icon_rect := Rect2(
		Vector2(
			counter_rect.position.x
			+ PORTRAIT_HEART_ICON_LEFT_INSET * counter_scale
			+ PORTRAIT_RESOURCE_COUNTER_ICON_X_SHIFT,
			counter_rect.position.y + (counter_rect.size.y - heart_icon_size.y) * 0.5
		),
		heart_icon_size
	)
	var panel_rect: Rect2 = _portrait_resource_counter_panel_rect(counter_rect)
	var panel := _stage_panel(
		panel_rect,
		panel_color,
		panel_rect.size.y * 0.5,
		Color.TRANSPARENT,
		0.0
	)
	panel.z_index = 20
	var heart_icon: Control = _stage_top_bar_resource_icon(
		icon_rect,
		LIFE_HEART_ICON_TEXTURE,
		"TopBarHeartIcon"
	)
	state._portrait_heart_icon_visual = heart_icon

	var count_label := _stage_label(
		icon_rect,
		str(resolved_hearts),
		maxi(1, int(round(
			22.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
		))),
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	count_label.add_theme_font_override("font", UI_REGULAR_FONT)
	BUTTON_TEXT_STYLE_SCRIPT.apply_regular_display(count_label)
	count_label.z_index = 22
	state.heart_count_label = count_label

	if counter_is_interactive:
		var add_badge_visual: Control = _stage_resource_add_badge(icon_rect, counter_scale)
		add_badge_visual.set_meta(&"badge_allowed", true)
		add_badge_visual.visible = true
		state.heart_add_badge_visual = add_badge_visual

	var status_left: float = counter_rect.position.x + 52.0 * counter_scale
	var status_right: float = (
		panel_rect.end.x - PORTRAIT_RESOURCE_COUNTER_PANEL_TRAILING_INSET * counter_scale
	)
	var status_rect := Rect2(
		Vector2(status_left, panel_rect.position.y),
		Vector2(maxf(1.0, status_right - status_left), panel_rect.size.y)
	)
	var recovery_seconds: int = GameState.get_heart_recovery_seconds()
	var status_text: String = _heart_status_text(resolved_hearts, recovery_seconds)
	var status_font_size: int = maxi(1, int(round(
		25.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var status_min_font_size: int = maxi(1, int(round(
		16.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var status_label := _stage_label(
		status_rect,
		status_text,
		status_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	status_label.add_theme_font_override("font", UI_REGULAR_FONT)
	BUTTON_TEXT_STYLE_SCRIPT.apply_regular_display(status_label)
	status_label.z_index = 21
	state.heart_status_label = status_label
	_fit_single_line_label_to_width(status_label, status_text, status_rect.size.x, status_font_size, status_min_font_size)
	content = counter_parent_content
	if counter_is_interactive:
		state.heart_counter_button = _stage_resource_counter_button(
			counter_rect,
			counter_visual,
			Callable(),
			Callable(self, "_show_heart_refill_popup").bind(Callable(), return_action)
		)
	content = screen_content

func _stage_resource_add_badge(icon_rect: Rect2, counter_scale: float) -> Control:
	var badge_parent: Control = content
	var badge_visual := Control.new()
	badge_visual.name = "ResourceAddBadgeVisual"
	badge_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_parent.add_child(badge_visual)
	badge_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = badge_visual
	var add_badge_size: float = PORTRAIT_CURRENCY_ADD_BADGE_SIZE * counter_scale
	var add_badge_rect := Rect2(
		icon_rect.end - Vector2.ONE * add_badge_size * 0.82,
		Vector2.ONE * add_badge_size
	)
	var add_badge := _stage_panel(
		add_badge_rect,
		PORTRAIT_CURRENCY_ADD_BADGE_GREEN,
		add_badge_size * 0.5,
		PORTRAIT_CURRENCY_ADD_BADGE_BORDER,
		maxf(1.0, 1.5 * counter_scale)
	)
	add_badge.z_index = 23
	var plus_arm: float = add_badge_size * 0.58
	var plus_stroke: float = maxf(2.0, add_badge_size * 0.20)
	var plus_center: Vector2 = add_badge_rect.get_center()
	var plus_horizontal := _stage_panel(
		Rect2(
			plus_center - Vector2(plus_arm, plus_stroke) * 0.5,
			Vector2(plus_arm, plus_stroke)
		),
		Color.WHITE,
		plus_stroke * 0.5
	)
	plus_horizontal.z_index = 24
	var plus_vertical := _stage_panel(
		Rect2(
			plus_center - Vector2(plus_stroke, plus_arm) * 0.5,
			Vector2(plus_stroke, plus_arm)
		),
		Color.WHITE,
		plus_stroke * 0.5
	)
	plus_vertical.z_index = 24
	content = badge_parent
	return badge_visual

func _stage_resource_counter_button(
	counter_rect: Rect2,
	counter_visual: Control,
	return_action: Callable,
	direct_action: Callable = Callable()
) -> Control:
	var counter_action: Callable = direct_action
	if !counter_action.is_valid():
		counter_action = Callable(self, "_open_coin_store").bind(return_action)
		if _portrait_coin_store_active:
			counter_action = Callable(self, "_ignore_resource_counter_press")
		elif return_action.is_valid() and return_action.get_method() == &"show_coin_store":
			counter_action = return_action
	var counter_button := _stage_button(counter_rect, counter_action, "")
	counter_button.z_index = 25
	counter_button.button_down.connect(
		Callable(self, "_set_currency_counter_pressed").bind(
			counter_visual,
			counter_rect,
			true
		)
	)
	counter_button.button_up.connect(
		Callable(self, "_set_currency_counter_pressed").bind(
			counter_visual,
			counter_rect,
			false
		)
	)
	counter_button.mouse_exited.connect(
		Callable(self, "_set_currency_counter_pressed").bind(
			counter_visual,
			counter_rect,
			false
		)
	)
	return counter_button

func _ignore_resource_counter_press() -> void:
	# The shop is already visible. Keep the button and its press animation, but
	# do not rebuild or push the same store screen again.
	pass

func _set_currency_counter_pressed(
	counter_visual: Control,
	counter_rect: Rect2,
	is_pressed: bool
) -> void:
	if counter_visual == null or !is_instance_valid(counter_visual) or !counter_visual.is_inside_tree():
		return
	counter_visual.pivot_offset = _portrait_stage_point_to_viewport(
		counter_rect.get_center(),
		counter_visual
	)
	var previous_tween: Tween = _optional_node_meta(counter_visual, &"press_tween") as Tween
	if previous_tween != null and previous_tween.is_valid():
		_cancel_owned_tween(previous_tween)
	var target_scale: Vector2 = (
		Vector2.ONE * PORTRAIT_CURRENCY_COUNTER_PRESSED_SCALE
		if is_pressed
		else Vector2.ONE
	)
	var duration: float = (
		PORTRAIT_CURRENCY_COUNTER_PRESS_DURATION
		if is_pressed
		else PORTRAIT_CURRENCY_COUNTER_RELEASE_DURATION
	)
	var press_tween: Tween = _owned_tween(counter_visual)
	press_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var scale_tweener: PropertyTweener = press_tween.tween_property(
		counter_visual,
		"scale",
		target_scale,
		duration
	)
	scale_tweener.set_trans(Tween.TRANS_QUAD)
	scale_tweener.set_ease(Tween.EASE_OUT)
	counter_visual.set_meta(&"press_tween", press_tween)

func _set_portrait_resource_counter_collection_active(
	reward_currency: String,
	active: bool
) -> void:
	var resource_icon: Control = (
		state._portrait_star_icon_visual
		if reward_currency == GameState.STAGE_REWARD_STARS
		else state._portrait_currency_coin_icon_visual
	)
	var counter_visual: Control = (
		state._portrait_star_counter_visual
		if reward_currency == GameState.STAGE_REWARD_STARS
		else state._portrait_currency_counter_visual
	)
	if (
		resource_icon == null
		or !is_instance_valid(resource_icon)
		or !resource_icon.is_inside_tree()
		or counter_visual == null
		or !is_instance_valid(counter_visual)
		or !counter_visual.is_inside_tree()
	):
		return

	# Keep the currency icon inside the counter for the complete animation.
	# The counter's scale now affects the plate and icon as one unit.
	if resource_icon.get_parent() != counter_visual:
		resource_icon.reparent(counter_visual, true)
	resource_icon.pivot_offset = Vector2.ZERO

	var icon_rest_scale: Vector2 = resource_icon.get_meta(
		&"reward_icon_rest_scale",
		Vector2.ZERO
	)
	if icon_rest_scale == Vector2.ZERO:
		icon_rest_scale = resource_icon.scale
		if icon_rest_scale == Vector2.ZERO:
			icon_rest_scale = Vector2.ONE
		resource_icon.set_meta(&"reward_icon_rest_scale", icon_rest_scale)
	var icon_rest_position: Vector2 = resource_icon.position
	if resource_icon.has_meta(&"reward_icon_rest_position"):
		icon_rest_position = resource_icon.get_meta(
			&"reward_icon_rest_position",
			resource_icon.position
		)
	else:
		resource_icon.set_meta(&"reward_icon_rest_position", icon_rest_position)

	var counter_rest_scale: Vector2 = counter_visual.get_meta(
		&"reward_counter_rest_scale",
		Vector2.ZERO
	)
	if counter_rest_scale == Vector2.ZERO:
		counter_rest_scale = counter_visual.scale
		if counter_rest_scale == Vector2.ZERO:
			counter_rest_scale = Vector2.ONE
		counter_visual.set_meta(&"reward_counter_rest_scale", counter_rest_scale)

	var previous_counter_tween: Tween = _optional_node_meta(
		counter_visual, &"reward_counter_hold_tween"
	) as Tween
	if previous_counter_tween != null and previous_counter_tween.is_valid():
		_cancel_owned_tween(previous_counter_tween)

	# Collection starts and ends only with the icon at its normal LOCAL size.
	# This gives the exact order: whole counter grows -> icon impacts -> icon
	# settles -> whole counter shrinks.
	var previous_impact_tween: Tween = _optional_node_meta(
		resource_icon, &"reward_icon_impact_tween"
	) as Tween
	if previous_impact_tween != null and previous_impact_tween.is_valid():
		_cancel_owned_tween(previous_impact_tween)
	resource_icon.scale = icon_rest_scale
	resource_icon.position = icon_rest_position
	counter_visual.set_meta(&"reward_counter_collection_active", active)

	var target_scale: Vector2 = (
		counter_rest_scale * PORTRAIT_CURRENCY_COUNTER_REWARD_BOUNCE_PEAK_SCALE
		if active
		else counter_rest_scale
	)
	var duration: float = (
		PORTRAIT_CURRENCY_COUNTER_REWARD_GROW_DURATION
		if active
		else PORTRAIT_CURRENCY_COUNTER_REWARD_SETTLE_DURATION
	)
	var collection_tween: Tween = _owned_tween(counter_visual)
	collection_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var scale_tweener: PropertyTweener = collection_tween.tween_property(
		counter_visual,
		"scale",
		target_scale,
		duration
	)
	scale_tweener.set_trans(Tween.TRANS_SINE)
	scale_tweener.set_ease(Tween.EASE_IN_OUT)
	counter_visual.set_meta(&"reward_counter_hold_tween", collection_tween)

func _bounce_portrait_resource_counter_icon(reward_currency: String) -> void:
	var resource_icon: Control = (
		state._portrait_star_icon_visual
		if reward_currency == GameState.STAGE_REWARD_STARS
		else state._portrait_currency_coin_icon_visual
	)
	if (
		resource_icon == null
		or !is_instance_valid(resource_icon)
		or !resource_icon.is_inside_tree()
	):
		return
	var previous_tween: Tween = _optional_node_meta(
		resource_icon, &"reward_icon_impact_tween"
	) as Tween
	if previous_tween != null and previous_tween.is_valid():
		_cancel_owned_tween(previous_tween)

	var rest_scale: Vector2 = resource_icon.get_meta(
		&"reward_icon_rest_scale",
		resource_icon.scale
	)
	if rest_scale == Vector2.ZERO:
		rest_scale = Vector2.ONE
	var rest_position: Vector2 = resource_icon.get_meta(
		&"reward_icon_rest_position",
		resource_icon.position
	)
	var peak_scale: Vector2 = (
		rest_scale * PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_PEAK_SCALE
	)
	var peak_position: Vector2 = (
		rest_position
		- resource_icon.size * (peak_scale - rest_scale) * 0.5
	)

	# Parent is already enlarged and stays untouched during the impact.
	# Only the icon's local transform bounces, then returns exactly to rest.
	resource_icon.scale = rest_scale
	resource_icon.position = rest_position
	var impact_tween: Tween = _owned_tween(resource_icon)
	impact_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow_scale: PropertyTweener = impact_tween.tween_property(
		resource_icon,
		"scale",
		peak_scale,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION
	)
	grow_scale.set_trans(Tween.TRANS_BACK)
	grow_scale.set_ease(Tween.EASE_OUT)
	var grow_position: PropertyTweener = impact_tween.parallel().tween_property(
		resource_icon,
		"position",
		peak_position,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION
	)
	grow_position.set_trans(Tween.TRANS_BACK)
	grow_position.set_ease(Tween.EASE_OUT)
	var settle_scale: PropertyTweener = impact_tween.tween_property(
		resource_icon,
		"scale",
		rest_scale,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION
	)
	settle_scale.set_trans(Tween.TRANS_BOUNCE)
	settle_scale.set_ease(Tween.EASE_OUT)
	var settle_position: PropertyTweener = impact_tween.parallel().tween_property(
		resource_icon,
		"position",
		rest_position,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION
	)
	settle_position.set_trans(Tween.TRANS_BOUNCE)
	settle_position.set_ease(Tween.EASE_OUT)
	resource_icon.set_meta(&"reward_icon_impact_tween", impact_tween)

func _stage_holder(rect: Rect2, mouse_filter: int = Control.MOUSE_FILTER_PASS) -> Control:
	return render.call(&"_stage_holder", content if is_instance_valid(content) else null, [rect, mouse_filter])

func _stage_panel(rect: Rect2, fill_color: Color, corner_radius: float = 0.0, border_color: Color = Color(0.0, 0.0, 0.0, 0.0), border_width: float = 0.0) -> Control:
	return render.call(&"_stage_panel", content if is_instance_valid(content) else null, [rect, fill_color, corner_radius, border_color, border_width])

func _stage_label(rect: Rect2, text: String, font_size: int = 20, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, font: Font = null) -> Label:
	return render.call(&"_stage_label", content if is_instance_valid(content) else null, [rect, text, font_size, color, align, font])

func _stage_button(rect: Rect2, callable: Callable, text: String = "", font_size: int = 20) -> Button:
	return render.call(&"_stage_button", content if is_instance_valid(content) else null, [rect, callable, text, font_size])

func _fit_single_line_label_to_width(label: Label, text: String, available_width: float, max_font_size: int, min_font_size: int) -> void:
	render.call(&"_fit_single_line_label_to_width", content if is_instance_valid(content) else null, [label, text, available_width, max_font_size, min_font_size])

func _portrait_stage_point_to_viewport(stage_point: Vector2, reference_node: Node = null) -> Vector2:
	return render.call(&"_portrait_stage_point_to_viewport", content if is_instance_valid(content) else null, [stage_point, reference_node])

func _optional_node_meta(node: Object, key: StringName) -> Variant:
	return render.call(&"_optional_node_meta", content if is_instance_valid(content) else null, [node, key])

func _soft_currency_balance_text(balance: int) -> String:
	return render.call(&"_soft_currency_balance_text", content if is_instance_valid(content) else null, [balance])

func _heart_status_text(heart_count: int, recovery_seconds: int) -> String:
	return render.call(&"_heart_status_text", content if is_instance_valid(content) else null, [heart_count, recovery_seconds])

func _add_portrait_icon_with_extrusion_to_holder(
	holder: Control,
	texture: Texture2D,
	prefix: String,
	icon_z_index: int = 1,
	shadow_alpha: float = 1.0,
	shadow_offset_scale: float = 1.0
) -> TextureRect:
	return render.call(&"_add_portrait_icon_with_extrusion_to_holder", content if is_instance_valid(content) else null, [holder, texture, prefix, icon_z_index, shadow_alpha, shadow_offset_scale])

func _portrait_ads_enabled() -> bool:
	return actions[&"_portrait_ads_enabled"].callv([])

func _stage_home_avatar_button() -> void:
	actions[&"_stage_home_avatar_button"].callv([])

func _stage_menu_settings_button() -> void:
	actions[&"_stage_menu_settings_button"].callv([])

func _open_coin_store(return_action: Callable = Callable()) -> void:
	actions[&"_open_coin_store"].callv([return_action])

func _show_heart_refill_popup(
	continue_action: Callable = Callable(),
	store_return_action: Callable = Callable(),
	cancel_action: Callable = Callable(),
	reward_acquired: bool = false
) -> void:
	actions[&"_show_heart_refill_popup"].callv([continue_action, store_return_action, cancel_action, reward_acquired])


var _owned_animations: Array[Tween] = []

func _owned_tween(owner: Node) -> Tween:
	_prune_owned_animations()
	var tween := owner.create_tween()
	_owned_animations.append(tween)
	set_process(true)
	tween.finished.connect(_on_owned_tween_finished.bind(tween.get_instance_id()), CONNECT_ONE_SHOT)
	return tween

func stop() -> void:
	for tween: Tween in _owned_animations:
		if tween != null and tween.is_valid():
			tween.kill()
	_owned_animations.clear()
	set_process(false)
	# A retained HUD must not inherit a half-pressed or half-collected pose.
	for counter_value: Variant in [state._portrait_currency_counter_visual, state._portrait_star_counter_visual]:
		if is_instance_valid(counter_value):
			var counter: Control = counter_value
			counter.scale = counter.get_meta(&"reward_counter_rest_scale", Vector2.ONE)
			counter.set_meta(&"reward_counter_collection_active", false)
	for icon_value: Variant in [state._portrait_currency_coin_icon_visual, state._portrait_star_icon_visual]:
		if is_instance_valid(icon_value):
			var icon: Control = icon_value
			icon.scale = icon.get_meta(&"reward_icon_rest_scale", icon.scale)
			icon.position = icon.get_meta(&"reward_icon_rest_position", icon.position)

func _exit_tree() -> void:
	stop()


class CounterState extends RefCounted:
	## One set of live HUD bindings shared with the navigation/gameplay adapter.
	var _portrait_active_currency_counter_rect: Rect2 = PORTRAIT_CURRENCY_COUNTER_RECT
	var _portrait_active_star_counter_rect: Rect2 = Rect2()
	var _binding_portrait_currency_counter_visual: Control
	var _portrait_currency_counter_visual: Control:
		get:
			return _binding_portrait_currency_counter_visual if is_instance_valid(_binding_portrait_currency_counter_visual) else null
		set(value):
			_binding_portrait_currency_counter_visual = value
	var _binding_portrait_currency_coin_icon_visual: Control
	var _portrait_currency_coin_icon_visual: Control:
		get:
			return _binding_portrait_currency_coin_icon_visual if is_instance_valid(_binding_portrait_currency_coin_icon_visual) else null
		set(value):
			_binding_portrait_currency_coin_icon_visual = value
	var _binding_portrait_star_counter_visual: Control
	var _portrait_star_counter_visual: Control:
		get:
			return _binding_portrait_star_counter_visual if is_instance_valid(_binding_portrait_star_counter_visual) else null
		set(value):
			_binding_portrait_star_counter_visual = value
	var _binding_portrait_star_icon_visual: Control
	var _portrait_star_icon_visual: Control:
		get:
			return _binding_portrait_star_icon_visual if is_instance_valid(_binding_portrait_star_icon_visual) else null
		set(value):
			_binding_portrait_star_icon_visual = value
	var _binding_portrait_heart_icon_visual: Control
	var _portrait_heart_icon_visual: Control:
		get:
			return _binding_portrait_heart_icon_visual if is_instance_valid(_binding_portrait_heart_icon_visual) else null
		set(value):
			_binding_portrait_heart_icon_visual = value
	var _bindingheart_count_label: Label
	var heart_count_label: Label:
		get:
			return _bindingheart_count_label if is_instance_valid(_bindingheart_count_label) else null
		set(value):
			_bindingheart_count_label = value
	var _bindingheart_status_label: Label
	var heart_status_label: Label:
		get:
			return _bindingheart_status_label if is_instance_valid(_bindingheart_status_label) else null
		set(value):
			_bindingheart_status_label = value
	var _bindingheart_add_badge_visual: Control
	var heart_add_badge_visual: Control:
		get:
			return _bindingheart_add_badge_visual if is_instance_valid(_bindingheart_add_badge_visual) else null
		set(value):
			_bindingheart_add_badge_visual = value
	var _bindingheart_counter_button: Control
	var heart_counter_button: Control:
		get:
			return _bindingheart_counter_button if is_instance_valid(_bindingheart_counter_button) else null
		set(value):
			_bindingheart_counter_button = value

func prepare(parent: Control, top_bar: Control, store_active: bool) -> void:
	content = parent
	_portrait_top_bar_content = top_bar
	_portrait_coin_store_active = store_active

func _on_owned_tween_finished(identifier: int) -> void:
	for index in range(_owned_animations.size() - 1, -1, -1):
		if _owned_animations[index].get_instance_id() == identifier:
			_owned_animations.remove_at(index)
			set_process(!_owned_animations.is_empty())
			return

func _cancel_owned_tween(tween: Tween) -> void:
	if tween != null:
		tween.kill()
		_owned_animations.erase(tween)
		set_process(!_owned_animations.is_empty())

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	_prune_owned_animations()

func _prune_owned_animations() -> void:
	# kill() and a bound owner's destruction do not emit finished.
	for index in range(_owned_animations.size() - 1, -1, -1):
		if !_owned_animations[index].is_valid():
			_owned_animations.remove_at(index)
	set_process(!_owned_animations.is_empty())
