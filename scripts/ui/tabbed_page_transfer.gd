extends RefCounted
## Explicit handoff from the temporary fade viewport to the native UI canvas.
const META := &"tabbed_page_transfer"

static func active(node: Node) -> bool:
	while node != null:
		if node.has_meta(META):
			return true
		node = node.get_parent()
	return false

static func finish(page: Control, destination: Node) -> void:
	# Stage widgets detach their old viewport handlers on exit. Capture only
	# this page's subscriptions and reconnect them to the native viewport.
	var handlers: Array[Callable] = []
	for connection: Dictionary in page.get_viewport().size_changed.get_connections():
		var callback: Callable = connection.callable
		var target := callback.get_object()
		if target is Node and (target == page or page.is_ancestor_of(target)):
			handlers.append(callback)
	page.set_meta(META, true)
	page.reparent(destination, false)
	page.remove_meta(META)
	for callback: Callable in handlers:
		if callback.is_valid():
			if !page.get_viewport().size_changed.is_connected(callback):
				page.get_viewport().size_changed.connect(callback)
			callback.call()
