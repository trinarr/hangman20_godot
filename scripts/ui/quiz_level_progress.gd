extends Control

const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const ICONS = preload("res://scripts/ui/portrait_icon_extrusion.gd")
const COUNTER_STYLE = preload("res://scripts/ui/resource_counter_style.gd")

var _segments: Array[Panel] = []

func setup(count: int, reward_texture: Texture2D) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := HBoxContainer.new()
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_theme_constant_override("separation", 4)
	add_child(track)
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.offset_left = 6.0
	track.offset_right = -23.0
	track.offset_top = 5.0
	track.offset_bottom = -5.0
	var plate := Panel.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", _style(PALETTE.UI_BLUE_DARK, 12))
	add_child(plate)
	move_child(plate, 0)
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for slot: int in range(count):
		var segment := Panel.new()
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.add_child(segment)
		_segments.append(segment)
	var reward := Control.new()
	reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(reward)
	reward.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	reward.offset_left = -20.0
	reward.offset_right = 12.0
	reward.offset_top = -16.0
	reward.offset_bottom = 16.0
	ICONS._add_portrait_icon_with_extrusion_to_holder(reward, reward_texture, "QuizLevelReward", 1, COUNTER_STYLE.ICON_SHADOW_ALPHA)

func set_statuses(statuses: PackedInt32Array) -> void:
	for slot: int in range(_segments.size()):
		var color: Color = PALETTE.UI_BLUE
		match statuses[slot]:
			1: color = PALETTE.SUCCESS_BORDER
			2: color = PALETTE.ERROR_SOFT
		_segments[slot].add_theme_stylebox_override("panel", _style(color, 6))

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
