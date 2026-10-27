extends Control
## Keeps Home counters in sync with onboarding and delayed ad permission.

var build_counters: Callable

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameState.guided_onboarding_finished.connect(_rebuild)
	GameState.ads_became_available.connect(_rebuild)
	ConsentRegion.changed.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	if build_counters.is_valid():
		build_counters.call(self)
