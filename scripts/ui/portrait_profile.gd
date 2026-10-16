extends Control
## Profile tabs and the full settings page. Host retains existing action handlers.
const SETTINGS_SCROLL = preload("res://scripts/ui/profile_settings_scroll.gd")
const TABS = preload("res://scripts/ui/tabbed_page_style.gd")
const LAYOUT = preload("res://scripts/ui/portrait_stage_layout.gd")
const COPY = preload("res://scripts/ui/portrait_leaderboard.gd")
var host: Node
var heading: Label
var initial_tab := "profile"
var selected_tab := ""
var bottom_inset := 0.0
var _buttons: Dictionary = {}
var settings_scroll: ScrollContainer

func _ready() -> void:
	name = "ProfileScreen"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var previous: Control = host.content
	host.content = self
	for index in range(2):
		var key := "profile" if index == 0 else "settings"
		var holder: Control = host._stage_holder(Rect2(26 + index * 218, TABS.TAB_Y, 210, TABS.TAB_HEIGHT))
		var button := Button.new()
		button.name = "ProfileTab" if index == 0 else "SettingsTab"
		button.set_anchors_preset(Control.PRESET_FULL_RECT)
		var caption: String = COPY.localized("PROFILE_TITLE", "Профиль", "Profile") if index == 0 else tr("SETTINGS_TITLE")
		TABS.configure(button, caption, false)
		host._connect_stage_button_action(button, select_tab.bind(key))
		holder.add_child(button)
		_buttons[key] = button
	host.content = previous
	get_viewport().size_changed.connect(_layout)
	select_tab(initial_tab)

func select_tab(tab: String) -> void:
	if tab != "profile" and tab != "settings":
		return
	selected_tab = tab
	if tab == "settings" and !is_instance_valid(settings_scroll):
		_build_settings()
	if is_instance_valid(settings_scroll):
		settings_scroll.visible = tab == "settings"
	for key: String in _buttons:
		var button: Button = _buttons[key]
		TABS.select(button, key == tab)
	if is_instance_valid(heading):
		heading.text = str((_buttons[tab] as Button).get_meta("tab_title")).to_upper()
	_layout()

func _build_settings() -> void:
	host.settings_toggle_buttons.clear()
	host.settings_word_language_buttons.clear()
	settings_scroll = SETTINGS_SCROLL.new()
	settings_scroll.name = "ProfileSettingsScroll"
	settings_scroll.content_origin_y = 206
	settings_scroll.content_height = 520
	add_child(settings_scroll)
	_layout()
	var previous: Control = host.content
	host.content = settings_scroll.stage_content
	host._stage_settings_rows(true)
	host.content = previous
	settings_scroll._prepare_touch_controls(settings_scroll.stage_content)

func rebuild_settings() -> void:
	if is_instance_valid(settings_scroll):
		remove_child(settings_scroll)
		settings_scroll.queue_free()
	settings_scroll = null
	_build_settings()
	settings_scroll.visible = selected_tab == "settings"

func set_bottom_inset(value: float) -> void:
	bottom_inset = value
	_layout()

func _layout() -> void:
	if !is_inside_tree() or !is_instance_valid(settings_scroll):
		return
	var viewport_size := get_viewport_rect().size
	var top: float = TABS.CONTENT_Y + LAYOUT.safe_top_stage(viewport_size)
	var height: float = maxf(80, LAYOUT.expanded_stage_height(viewport_size) - bottom_inset - 12 - top)
	# The viewport includes the safe top inset exactly once.
	settings_scroll.stage_rect = Rect2(18.4, top, 443.2, height)
	settings_scroll._sync_to_stage()

func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.disconnect(_layout)
