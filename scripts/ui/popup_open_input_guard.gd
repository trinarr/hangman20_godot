extends Control
## Swallow pointer input until every opening animation owned by this popup ends.
var _pending: Dictionary = {}
var _next_ticket: int = 0
var _building: bool = true

func _ready() -> void:
	name = "PopupOpeningInputGuard"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_parent().child_order_changed.connect(_raise_above_content)
	_raise_above_content()
	call_deferred("_finish_build")

func _raise_above_content() -> void:
	# GUI picking follows sibling order rather than z_index. Builders append
	# the shell and overlays after installing this guard.
	if is_inside_tree() and get_index() != get_parent().get_child_count() - 1:
		move_to_front()

func _exit_tree() -> void:
	if get_parent().child_order_changed.is_connected(_raise_above_content):
		get_parent().child_order_changed.disconnect(_raise_above_content)

func hold(owner: Node) -> int:
	_next_ticket += 1
	var ticket: int = _next_ticket
	_pending[ticket] = true
	owner.tree_exiting.connect(release.bind(ticket), CONNECT_ONE_SHOT)
	return ticket

func wait_for(completion: Signal, owner: Node) -> void:
	completion.connect(release.bind(hold(owner)), CONNECT_ONE_SHOT)

func release(ticket: int) -> void:
	_pending.erase(ticket)
	_try_finish()

func _finish_build() -> void:
	_building = false
	_try_finish()

func _try_finish() -> void:
	if !_building and _pending.is_empty() and is_inside_tree():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		hide()
		queue_free()
