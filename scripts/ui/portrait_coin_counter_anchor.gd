extends RefCounted
## Resolve the authored counter position in the live modal stack, without
## overwriting the screen HUD's active rectangle or retaining freed popups.
const GROUP := &"portrait_coin_counter_anchor"
const RECT := &"portrait_coin_counter_rect"

static func register(visual: Control, rect: Rect2) -> void:
	visual.set_meta(RECT, rect)
	visual.add_to_group(GROUP)

static func _layer_index(node: Node) -> int:
	while node != null:
		if node is CanvasLayer:
			return node.layer
		node = node.get_parent()
	return 0

static func find_under(popup_root: Control, fallback: Rect2) -> Rect2:
	var top_layer := _layer_index(popup_root)
	var best: Control
	var best_layer := 0
	for candidate: Node in popup_root.get_tree().get_nodes_in_group(GROUP):
		var visual := candidate as Control
		if visual == null or !visual.is_visible_in_tree() or popup_root.is_ancestor_of(visual):
			continue
		var live := true
		var ancestor: Node = visual
		while ancestor != null:
			if ancestor.is_queued_for_deletion() or (ancestor is CanvasLayer and !ancestor.visible) \
				or (ancestor is CanvasItem and !ancestor.is_visible_in_tree()):
				live = false
				break
			ancestor = ancestor.get_parent()
		var layer_index := _layer_index(visual)
		var rect: Variant = visual.get_meta(RECT, null)
		if !live or layer_index >= top_layer or !(rect is Rect2) or !rect.has_area():
			continue
		if best == null or layer_index >= best_layer:
			best = visual
			best_layer = layer_index
	return best.get_meta(RECT) if best != null else fallback
