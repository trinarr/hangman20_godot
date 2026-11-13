extends Node
## Holds the rendered source behind destination content until its backdrop covers it.
## Uses a snapshot for removed pages or a composited backdrop over live source nodes.
signal finished

const FADE = preload("res://scripts/ui/composited_fade.gd")
var coverage: float = 0.0:
	set(value):
		coverage = clampf(value, 0.0, 1.0)
		if is_instance_valid(_snapshot):
			_snapshot.modulate.a = 1.0 - coverage
		elif is_instance_valid(_background_controller):
			_background_controller.set("opacity", coverage)
var has_source := false
var complete := false
var _background: Control
var _snapshot: TextureRect
var _blocker_layer: CanvasLayer
var _blocker: Control
var _animation: Tween
var _background_controller: Node
var _live_sources: Array[WeakRef] = []
var _live_layer: Control
var _live_layer_z := 0

static func capture(viewport: Viewport) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		return null
	var frame: Image = viewport.get_texture().get_image()
	if frame == null or frame.is_empty():
		return null
	return ImageTexture.create_from_image(frame)

func prepare(background: Control, source: Texture2D = null) -> void:
	name = "ScreenCoverTransition"
	_background = background
	has_source = source != null
	if has_source:
		FADE.set_opacity(background, 1.0)
		_snapshot = TextureRect.new()
		_snapshot.name = "OutgoingScreenSnapshot"
		_snapshot.texture = source
		_snapshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_snapshot.stretch_mode = TextureRect.STRETCH_SCALE
		_snapshot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_snapshot.z_index = background.z_index
		var parent := background.get_parent()
		parent.add_child(_snapshot)
		# Above the complete destination backdrop, below its live foreground/HUD.
		parent.move_child(_snapshot, background.get_index() + 1)
		_blocker_layer = CanvasLayer.new()
		_blocker_layer.layer = 900
		add_child(_blocker_layer)
		_blocker = Control.new()
		_blocker.name = "ScreenCoverInputBlocker"
		_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		_blocker.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
		_blocker_layer.add_child(_blocker)
		get_viewport().size_changed.connect(_sync_layout)
		_sync_layout()
	if !has_source:
		_background_controller = FADE.branch(background)
	coverage = 0.0

func prepare_live(background: Control, sources: Array[Control]) -> void:
	# Flatten only the incoming background on GPU. The outgoing hero/chain stay
	# in their original hierarchy, with no viewport readback or texture upload.
	# This fill reconnects its viewport resize handler when wrap reparents it.
	background.request_ready()
	var layer: Control = FADE.wrap(background)
	name = "ScreenCoverTransition"
	_background = background
	_background_controller = layer
	_live_layer = layer
	_live_layer_z = layer.z_index
	var maximum_z := _canvas_z(layer)
	for source: Control in sources:
		if !is_instance_valid(source):
			continue
		_live_sources.append(weakref(source))
		maximum_z = maxi(maximum_z, _canvas_z(source))
		for visual: Node in source.find_children("*", "CanvasItem", true, false):
			maximum_z = maxi(maximum_z, _canvas_z(visual as CanvasItem))
	layer.z_index += maximum_z - _canvas_z(layer) + 1
	has_source = !_live_sources.is_empty()
	_blocker_layer = CanvasLayer.new()
	_blocker_layer.layer = 900
	add_child(_blocker_layer)
	_blocker = Control.new()
	_blocker.name = "ScreenCoverInputBlocker"
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker_layer.add_child(_blocker)
	get_viewport().size_changed.connect(_sync_layout)
	_sync_layout()
	coverage = 0.0

static func _canvas_z(visual: CanvasItem) -> int:
	var value := 0
	var current := visual
	while is_instance_valid(current):
		value += current.z_index
		if !current.z_as_relative:
			break
		var parent: Node = current.get_parent()
		while parent != null and !(parent is CanvasItem):
			if parent is CanvasLayer or parent is Viewport:
				return value
			parent = parent.get_parent()
		current = parent as CanvasItem
	return value

func uses_live_source() -> bool:
	return !_live_sources.is_empty()

func cancel() -> void:
	if _animation != null and _animation.is_valid():
		_animation.kill()
	if uses_live_source() and !complete:
		coverage = 0.0
	_release_visuals()

func reveal(seconds: float) -> Tween:
	if _animation != null and _animation.is_valid():
		return _animation
	_animation = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animation.tween_property(self, "coverage", 1.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_animation.tween_callback(finish)
	return _animation

func finish() -> void:
	if complete:
		return
	complete = true
	coverage = 1.0
	_release_visuals()
	finished.emit()

func _input(event: InputEvent) -> void:
	if has_source and !complete and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		get_viewport().set_input_as_handled()

func _sync_layout() -> void:
	var bounds := get_viewport().get_visible_rect()
	if is_instance_valid(_snapshot):
		_snapshot.position = bounds.position
		_snapshot.size = bounds.size
	if is_instance_valid(_blocker):
		_blocker.position = bounds.position
		_blocker.size = bounds.size

func _release_visuals() -> void:
	if complete:
		for reference: WeakRef in _live_sources:
			var source: Control = reference.get_ref()
			if is_instance_valid(source):
				source.hide()
	if is_instance_valid(_live_layer):
		_live_layer.z_index = _live_layer_z
	for visual: Control in [_snapshot, _blocker]:
		if is_instance_valid(visual):
			visual.hide()
			visual.queue_free()
	_snapshot = null
	_blocker = null
	if is_instance_valid(_blocker_layer):
		_blocker_layer.queue_free()
	_blocker_layer = null

func _exit_tree() -> void:
	if _animation != null and _animation.is_valid():
		_animation.kill()
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_layout):
		get_viewport().size_changed.disconnect(_sync_layout)
	_release_visuals()
