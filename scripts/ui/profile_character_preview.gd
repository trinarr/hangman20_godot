extends Node2D
## Authored character pose shared by cropped avatars and the profile editor.
const POSES := [preload("res://symbols/_______192.tscn"), preload("res://symbols/_______94.tscn")]
var character_id := 1
var body: Node2D
var bounds := Rect2()

func show_character(value: int) -> void:
	character_id = clampi(value, 1, 2)
	if is_instance_valid(body):
		body.free()
	body = POSES[character_id - 1].instantiate() as Node2D
	add_child(body)
	_freeze(body)
	var player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null:
		player.animation_finished.connect(_on_reaction_finished)
	bounds = Rect2()
	for node: Node in body.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if _visible_pose(sprite) and sprite.texture != null:
			var rect: Rect2 = (body.get_global_transform().affine_inverse() * sprite.get_global_transform()) * sprite.get_rect()
			bounds = rect if !bounds.has_area() else bounds.merge(rect)

func play_correct_letter() -> void:
	# Lucky's changing poses start at frame 7; preceding frames hold one image.
	# Skip that idle span and restore frame zero immediately after the reaction.
	var player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null and player.has_animation("default"):
		var backwards := character_id == 1
		player.play_section("default", 7.0 / 24.0 if backwards else 5.5 / 24.0, 9.5 / 24.0, -1.0, -1.0 if backwards else 1.0, backwards)
		player.advance(0.0)

func _on_reaction_finished(_animation: StringName) -> void:
	if character_id == 1:
		# Reverse playback of discrete texture tracks can retain the last crossed key.
		# Apply frame zero explicitly, including the authored sprite transforms.
		_freeze(body)

func fit_full_body(rect: Rect2, size_factor: float = 1.0) -> void:
	if !bounds.has_area():
		return
	var fit := minf(rect.size.x / bounds.size.x, rect.size.y / bounds.size.y) * size_factor
	body.scale = Vector2.ONE * fit
	body.position = rect.get_center() - bounds.get_center() * fit

func head_center() -> Vector2:
	var fraction := Vector2(0.38, 0.165) if character_id == 1 else Vector2(0.46, 0.30)
	return bounds.position + bounds.size * fraction

func portrait_span() -> float:
	var zoom := 0.9 if character_id == 1 else 1.3 * 1.15
	return maxf(bounds.size.x * 0.70, bounds.size.y * (0.34 if character_id == 1 else 0.72)) / zoom

func fit_portrait(rect: Rect2, appearance_scale: float = 1.0) -> void:
	if !bounds.has_area():
		return
	var fit := minf(rect.size.x, rect.size.y) / portrait_span()
	body.scale = Vector2.ONE * fit
	body.position = rect.get_center() - head_center() * fit
	if character_id == 2:
		body.position.y += 15.0 * appearance_scale

func displayed_head_center() -> Vector2:
	return body.transform * head_center()

func displayed_portrait_span() -> float:
	return portrait_span() * body.scale.x

func _visible_pose(node: CanvasItem) -> bool:
	var current: Node = node
	while current != self:
		if current is CanvasItem and !(current as CanvasItem).visible:
			return false
		current = current.get_parent()
	return true

func _freeze(node: Node) -> void:
	if node is AnimationPlayer:
		var player := node as AnimationPlayer
		if player.has_animation("default"):
			player.play("default")
			player.seek(0.0, true)
			player.stop(true)
	for child: Node in node.get_children():
		_freeze(child)
