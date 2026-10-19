extends Node
## Two portraits shared by all rows; no per-row character scene or viewport.
const AVATAR = preload("res://scripts/ui/profile_avatar_button.gd")
const CHARACTER = preload("res://scripts/ui/profile_character_preview.gd")
const PROFILE = preload("res://scripts/core/player_profile.gd")
var _textures: Dictionary = {}

func _ready() -> void:
	for character_id: int in [1, 2]:
		var viewport := SubViewport.new()
		viewport.name = "LeaderboardPortrait%d" % character_id
		viewport.disable_3d = true
		viewport.transparent_bg = true
		viewport.world_2d = World2D.new()
		viewport.size = Vector2i(256, 256)
		viewport.size_2d_override = Vector2i(103, 103)
		viewport.size_2d_override_stretch = true
		add_child(viewport)
		var character := CHARACTER.new()
		viewport.add_child(character)
		character.show_character(character_id)
		character.fit_portrait(Rect2(0, 0, 103, 103))
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		_textures[character_id] = viewport.get_texture()

func create_avatar(entry: Dictionary, side: float) -> Button:
	var appearance := PROFILE.resolve_appearance(entry)
	var avatar := AVATAR.new()
	avatar.name = "PlayerAvatar"
	avatar.portrait_enabled = false
	avatar.frame_shadow_enabled = false
	avatar.size = Vector2.ONE * side
	avatar.configure_profile_appearance(side)
	avatar.frame_color = PROFILE.FRAME_COLORS[appearance.frame_id - 1]
	avatar.avatar_texture = _textures[appearance.character_id]
	avatar.disabled = true
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.set_meta("character_id", appearance.character_id)
	avatar.set_meta("frame_id", appearance.frame_id)
	return avatar
