extends Node
## Shared, bounded render targets. Only unused slots may be repainted or evicted.
const OUTLINE = preload("res://scripts/ui/colored_icon_outline.gd")
const MAX_BYTES := 4 * 1024 * 1024
const MAX_ENTRIES := 16
const MAX_SIDE := 2048
var entries: Array[Dictionary] = []
var allocated_bytes := 0

static func for_control(control: Control) -> Node:
	# Masks must be children of the consuming viewport, so Godot renders them first.
	var owner_viewport := control.get_viewport()
	var service := owner_viewport.get_node_or_null("IconOutlineMaskCache")
	if service == null:
		service = load("res://scripts/ui/icon_outline_mask_cache.gd").new()
		service.name = "IconOutlineMaskCache"
		owner_viewport.add_child(service)
	return service

func acquire(texture: Texture2D, physical_size: Vector2, width: float) -> Dictionary:
	var key := [texture.get_instance_id(), physical_size, width]
	for entry in entries:
		if entry.key == key:
			entry.users += 1
			entry.used = Engine.get_frames_drawn()
			return entry
	var extent := (physical_size + Vector2.ONE * (width + 1.0) * 2.0) * 2.0
	var required := Vector2i(ceili(extent.x), ceili(extent.y)).max(Vector2i.ONE)
	required = Vector2i(ceili(required.x / 32.0) * 32, ceili(required.y / 32.0) * 32)
	var bytes := required.x * required.y * 4
	if required.x > MAX_SIDE or required.y > MAX_SIDE or bytes > MAX_BYTES:
		return {}
	var slot: Dictionary = {}
	for entry in entries:
		if entry.users == 0 and entry.viewport.size.x >= required.x and entry.viewport.size.y >= required.y:
			slot = entry
			break
	if slot.is_empty():
		while allocated_bytes + bytes > MAX_BYTES or entries.size() >= MAX_ENTRIES:
			var oldest: Dictionary = {}
			for entry in entries:
				if entry.users == 0 and (oldest.is_empty() or entry.used < oldest.used):
					oldest = entry
			if oldest.is_empty():
				return {}
			allocated_bytes -= oldest.bytes
			entries.erase(oldest)
			RenderingServer.free_rid(oldest.canvas_item)
			oldest.viewport.free()
		var viewport := SubViewport.new()
		viewport.size = required
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		var canvas_item := RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(canvas_item, viewport.find_world_2d().canvas)
		var mask_material := ShaderMaterial.new()
		mask_material.shader = OUTLINE.SHADER
		mask_material.set_shader_parameter("colored_outline", true)
		RenderingServer.canvas_item_set_material(canvas_item, mask_material.get_rid())
		slot = {"viewport":viewport, "canvas_item":canvas_item, "bytes":bytes, "material":mask_material}

		entries.append(slot)
		allocated_bytes += bytes
	slot.key = key
	slot.users = 1
	slot.used = Engine.get_frames_drawn()
	# Reuse the slot's private material during animation, avoiding per-frame allocation.
	slot.material.set_shader_parameter("outline_pixels", width * 2.0)
	RenderingServer.canvas_item_clear(slot.canvas_item)
	# Direct commands are ready before this frame's viewport render. A newly resized
	# Control would defer its draw until the next frame and leave UPDATE_ONCE empty.
	RenderingServer.canvas_item_add_texture_rect(slot.canvas_item,
		Rect2(Vector2.ONE * (width + 1.0) * 2.0, physical_size * 2.0), texture.get_rid())
	slot.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	return slot

func release(entry: Dictionary) -> void:
	if !entry.is_empty():
		entry.users = maxi(0, entry.users - 1)
		entry.used = Engine.get_frames_drawn()

func _exit_tree() -> void:
	for entry in entries:
		RenderingServer.free_rid(entry.canvas_item)
		entry.viewport.free()
	entries.clear()
	allocated_bytes = 0
