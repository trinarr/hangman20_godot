extends Control
## Fade overlapping text/outline/shadow/icon layers after they are composited.
var opacity: float = 1.0:
	set(value):
		opacity = clampf(value, 0.0, 1.0)
		_group.self_modulate.a = opacity * _parent_opacity

var _parent_opacity := 1.0

func set_parent_opacity(value: float) -> void:
	_parent_opacity = value
	_group.self_modulate.a = opacity * _parent_opacity

func get_parent_opacity() -> float:
	return _parent_opacity

var _group := CanvasGroup.new()
var _layout_root := Control.new()

# Existing interactive/layout roots stay in place. Each styled text item is
# composited separately; backgrounds retain their authored clipping and Z order.
class Branch extends Node:
	var opacity := 1.0:
		set(value):
			opacity = clampf(value, 0.0, 1.0)
			_apply(opacity * _parent_opacity)
	var _parent_opacity := 1.0

	func set_parent_opacity(value: float) -> void:
		_parent_opacity = value
		_apply(opacity * _parent_opacity)

	func get_parent_opacity() -> float:
		return _parent_opacity

	func _apply(value: float) -> void:
		for entry: Dictionary in _items:
			var item: Object = entry.reference.get_ref()
			if !is_instance_valid(item):
				continue
			if entry.grouped:
				item.set_parent_opacity(float(entry.alpha) * value)
			else:
				item.self_modulate.a = float(entry.alpha) * value
	var _items: Array[Dictionary] = []
	var _root: WeakRef
	var _collecting := false
	var _refresh_pending := false

	func refresh() -> void:
		# Restore authored alpha before collecting a rebuilt/dynamically extended UI.
		_collecting = true
		_refresh_pending = false
		var previous := opacity
		_apply(1.0)
		_items.clear()
		var root: Control = _root.get_ref()
		if is_instance_valid(root):
			_collect(root, 1.0, true)
		opacity = previous
		_collecting = false

	func _collect(node: Node, inherited_alpha: float, is_root: bool = false) -> void:
		if node is Control and !is_root:
			if node.get_script() == load("res://scripts/ui/composited_fade.gd"):
				_items.append({"reference":weakref(node), "alpha":float(node.get_parent_opacity()) * inherited_alpha, "grouped":true})
				return
			if node.has_meta(&"composited_branch"):
				var nested: Object = node.get_meta(&"composited_branch").get_ref()
				if is_instance_valid(nested):
					_items.append({"reference":weakref(nested), "alpha":float(nested.get_parent_opacity()) * inherited_alpha, "grouped":true})
					return
			var existing: WeakRef = node.get_meta(&"composited_fade") as WeakRef if node.has_meta(&"composited_fade") else null
			if existing != null and is_instance_valid(existing.get_ref()):
				var group: Object = existing.get_ref()
				_items.append({"reference":weakref(group), "alpha":float(group.get_parent_opacity()) * inherited_alpha, "grouped":true})
				return
			if node is Label or (node is Button and !node.text.is_empty()):
				var group: Control = load("res://scripts/ui/composited_fade.gd").wrap(node)
				_items.append({"reference":weakref(group), "alpha":float(group.get_parent_opacity()) * inherited_alpha, "grouped":true})
				return
		if node is CanvasItem:
			inherited_alpha *= node.modulate.a
			node.modulate.a = 1.0
			_items.append({"reference":weakref(node), "alpha":node.self_modulate.a * inherited_alpha, "grouped":false})
		if !node.child_entered_tree.is_connected(_queue_refresh):
			node.child_entered_tree.connect(_queue_refresh)
		for child: Node in node.get_children():
			if child != self:
				_collect(child, inherited_alpha)

	func _queue_refresh(_child: Node) -> void:
		if _collecting or _refresh_pending:
			return
		_refresh_pending = true
		refresh.call_deferred()

static func branch(visual: Control) -> Node:
	if visual is Label or visual is Button:
		return load("res://scripts/ui/composited_fade.gd").wrap(visual)
	var existing: WeakRef = visual.get_meta(&"composited_branch") as WeakRef if visual.has_meta(&"composited_branch") else null
	if existing != null and is_instance_valid(existing.get_ref()):
		return existing.get_ref()
	# A child may acquire its own animation while its parent is already fading.
	# Collect its authored alpha, then let the ancestor own only its parent factor.
	var ancestor := visual.get_parent()
	var parent_controller: Node = null
	while ancestor != null:
		if ancestor.has_meta(&"composited_branch"):
			parent_controller = ancestor.get_meta(&"composited_branch").get_ref()
			if is_instance_valid(parent_controller):
				parent_controller._apply(1.0)
				break
		ancestor = ancestor.get_parent()
	var controller := Branch.new()
	controller.name = "CompositedBranchFade"
	controller._root = weakref(visual)
	var initial := visual.modulate.a
	visual.modulate.a = 1.0
	visual.add_child(controller)
	visual.set_meta(&"composited_branch", weakref(controller))
	controller.refresh()
	controller.opacity = initial
	if is_instance_valid(parent_controller):
		parent_controller.refresh()
	return controller

static func set_opacity(visual: Control, value: float) -> void:
	branch(visual).set("opacity", value)

static func get_opacity(visual: Control) -> float:
	return float(branch(visual).get("opacity"))

static func layout_parent(visual: Control) -> Control:
	if visual.has_meta(&"composited_fade"):
		var group: Control = visual.get_meta(&"composited_fade").get_ref()
		if is_instance_valid(group):
			return group.get_parent_control()
	return visual.get_parent_control()

static func wrap(visual: Control) -> Control:
	var existing: WeakRef = visual.get_meta(&"composited_fade") as WeakRef if visual.has_meta(&"composited_fade") else null
	if existing != null and is_instance_valid(existing.get_ref()):
		return existing.get_ref()
	var parent := visual.get_parent()
	var index := visual.get_index()
	var fade := load("res://scripts/ui/composited_fade.gd").new() as Control
	fade.name = str(visual.name) + "Fade"
	fade.z_index = visual.z_index
	fade.z_as_relative = visual.z_as_relative
	parent.add_child(fade)
	parent.move_child(fade, index)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var anchors := [visual.anchor_left, visual.anchor_top, visual.anchor_right, visual.anchor_bottom]
	var offsets := [visual.offset_left, visual.offset_top, visual.offset_right, visual.offset_bottom]
	visual.reparent(fade._layout_root, false)
	visual.anchor_left = anchors[0]
	visual.anchor_top = anchors[1]
	visual.anchor_right = anchors[2]
	visual.anchor_bottom = anchors[3]
	visual.offset_left = offsets[0]
	visual.offset_top = offsets[1]
	visual.offset_right = offsets[2]
	visual.offset_bottom = offsets[3]
	fade.opacity = visual.modulate.a
	visual.modulate.a = 1.0
	visual.set_meta(&"composited_fade", weakref(fade))
	if parent is FlashStageTextureButton:
		fade.scale = visual.scale
		visual.scale = Vector2.ONE
	fade._prepare_visual(visual)
	return fade

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_group.name = "CompositedVisuals"
	add_child(_group)
	_layout_root.name = "VisualLayout"
	_layout_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_group.add_child(_layout_root)
	resized.connect(_sync_layout)

func _sync_layout() -> void:
	_layout_root.size = size

func add_visual(visual: CanvasItem) -> void:
	_sync_layout()
	_layout_root.add_child(visual)
	_prepare_visual(visual)

func _prepare_visual(node: Node) -> void:
	# CanvasGroup captures only its own Z band. Text effects and icon faces use
	# raised Z indices elsewhere; here their authored child order draws the
	# silhouettes first and the front last, all within the composited band.
	if node is CanvasItem:
		node.z_index = 0
		node.z_as_relative = true
	if !node.child_entered_tree.is_connected(_queue_prepare_visual):
		node.child_entered_tree.connect(_queue_prepare_visual)
	for child: Node in node.get_children():
		_prepare_visual(child)

func _queue_prepare_visual(node: Node) -> void:
	# Run after _ready(), which may assign an effect's normal raised Z index.
	_prepare_late_visual.call_deferred(weakref(node))

func _prepare_late_visual(reference: WeakRef) -> void:
	var node: Node = reference.get_ref()
	if is_instance_valid(node) and _group.is_ancestor_of(node):
		_prepare_visual(node)
