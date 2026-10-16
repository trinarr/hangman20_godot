extends "res://scripts/ui/settings_scroll.gd"
## Full-page stage widgets already include the safe-top inset. Cancel it in
## the content origin because the scroll viewport itself sits below the inset.
func _sync_stage_content_position() -> void:
	super._sync_stage_content_position()
	stage_content.position.y -= LAYOUT.safe_top_stage(get_viewport_rect().size) * _fit_scale
