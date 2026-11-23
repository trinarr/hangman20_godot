extends "res://scripts/ui/settings_scroll.gd"

func _ready() -> void:
	super._ready()
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

func _sync_to_stage() -> void:
	super._sync_to_stage()
	position.y += LAYOUT.extra_stage_height(get_viewport_rect().size) * _fit_scale

func _sync_stage_content_position() -> void:
	super._sync_stage_content_position()
	stage_content.position.y -= LAYOUT.extra_stage_height(get_viewport_rect().size) * _fit_scale

func _on_scroll_gui_input(event: InputEvent) -> void:
	if _max_scroll_vertical() > 0.0:
		super._on_scroll_gui_input(event)
