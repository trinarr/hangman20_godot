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

	var _items: Array[Dictionary] = []
	var _watched: Array[WeakRef] = []
	var _root: WeakRef
	var _collecting := false
	var _refresh_pending := false

	func _apply(value: float) -> void:
		for entry: Dictionary in _items:
			var item: Object = entry.reference.get_ref()
			if !is_instance_valid(item):
				continue
			if entry.grouped:
				item.set_parent_opacity(float(entry.alpha) * value)
			else:
				item.self_modulate.a = float(entry.alpha) * value

	func _restore(entry: Dictionary) -> void:
		var item: Object = entry.reference.get_ref()
		if !is_instance_valid(item):
			return
		if entry.grouped:
			item.set_parent_opacity(1.0)
		else:
			item.modulate.a = float(entry.modulate_alpha)
			item.self_modulate.a = float(entry.self_alpha)

	func _unwatch(node: Node) -> void:
		if node.child_entered_tree.is_connected(_queue_refresh):
			node.child_entered_tree.disconnect(_queue_refresh)
		if node.child_exiting_tree.is_connected(_child_exiting):
			node.child_exiting_tree.disconnect(_child_exiting)

	func _release_all() -> void:
		for entry: Dictionary in _items:
			_restore(entry)
		_items.clear()
		for reference: WeakRef in _watched:
			var node: Node = reference.get_ref()
			if is_instance_valid(node):
				_unwatch(node)
		_watched.clear()

	func _release_subtree(subtree: Node) -> void:
		for index in range(_items.size() - 1, -1, -1):
			var entry: Dictionary = _items[index]
			var visual: Node = entry.visual.get_ref()
			if !is_instance_valid(visual) or visual == subtree or subtree.is_ancestor_of(visual):
				_restore(entry)
				_items.remove_at(index)
		for index in range(_watched.size() - 1, -1, -1):
			var node: Node = _watched[index].get_ref()
			if !is_instance_valid(node) or node == subtree or subtree.is_ancestor_of(node):
				if is_instance_valid(node):
					_unwatch(node)
				_watched.remove_at(index)

	func _enter_tree() -> void:
		refresh()

	func _exit_tree() -> void:
		_collecting = true
		_release_all()
		_refresh_pending = false
		_collecting = false

	func refresh() -> void:
		# Restore LOCAL authored alpha, not the previously flattened ancestor factor.
		_collecting = true
		_refresh_pending = false
		_release_all()
		var root: Control = _root.get_ref()
		if is_instance_valid(root):
			_collect(root, 1.0, true)
		_apply(opacity * _parent_opacity)
		_collecting = false

	func _group_entry(controller: Node, visual: Node, inherited_alpha: float) -> void:
		_items.append({"reference":weakref(controller), "visual":weakref(visual), "alpha":inherited_alpha, "grouped":true})

	func _collect(node: Node, inherited_alpha: float, is_root: bool = false) -> void:
		if node is Control and !is_root:
			if node.get_script() == load("res://scripts/ui/composited_fade.gd"):
				_group_entry(node, node, inherited_alpha)
				return
			if node.has_meta(&"composited_branch"):
				var nested: Node = node.get_meta(&"composited_branch").get_ref()
				if is_instance_valid(nested):
					_group_entry(nested, node, inherited_alpha)
					return
			var existing: WeakRef = node.get_meta(&"composited_fade") as WeakRef if node.has_meta(&"composited_fade") else null
			if existing != null and is_instance_valid(existing.get_ref()):
				var group: Node = existing.get_ref()
				_group_entry(group, group, inherited_alpha)
				return
			if node is Label or (node is Button and !node.text.is_empty()):
				var group: Control = load("res://scripts/ui/composited_fade.gd").wrap(node)
				_group_entry(group, group, inherited_alpha)
				return
		if node is CanvasItem:
			var local_alpha: float = node.modulate.a
			var self_alpha: float = node.self_modulate.a
			inherited_alpha *= local_alpha
			node.modulate.a = 1.0
			_items.append({"reference":weakref(node), "visual":weakref(node), "modulate_alpha":local_alpha, "self_alpha":self_alpha, "alpha":self_alpha * inherited_alpha, "grouped":false})
		node.child_entered_tree.connect(_queue_refresh)
		node.child_exiting_tree.connect(_child_exiting)
		_watched.append(weakref(node))
		for child: Node in node.get_children():
			if child != self:
				_collect(child, inherited_alpha)

	func _child_exiting(child: Node) -> void:
		if _collecting:
			return
		# Run while the old ancestry is intact, before a new owner can collect it.
		_release_subtree(child)
		_queue_refresh(child)

	func _queue_refresh(_child: Node) -> void:
		if _collecting or _refresh_pending:
			return
		_refresh_pending = true
		refresh.call_deferred()

static func _release_from_ancestor(visual: Control) -> Node:
	var ancestor := visual.get_parent()
	while ancestor != null:
		if ancestor.has_meta(&"composited_branch"):
			var controller: Node = ancestor.get_meta(&"composited_branch").get_ref()
			if is_instance_valid(controller):
				if controller._collecting:
					return null
				controller._release_subtree(visual)
				return controller
		ancestor = ancestor.get_parent()
	return null

static func branch(visual: Control) -> Node:
	if visual is Label or visual is Button:
		return load("res://scripts/ui/composited_fade.gd").wrap(visual)
	var existing: WeakRef = visual.get_meta(&"composited_branch") as WeakRef if visual.has_meta(&"composited_branch") else null
	if existing != null and is_instance_valid(existing.get_ref()):
		return existing.get_ref()
	var parent_controller := _release_from_ancestor(visual)
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
	var parent_controller := _release_from_ancestor(visual)
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
	if is_instance_valid(parent_controller):
		parent_controller.refresh()
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
