extends SceneTree

const WORD = preload("res://scripts/models/word_data.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
var checks: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var database: Node = root.get_node("Database")
	var session: Node = root.get_node("GameSession")
	var revision: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/word_hint_revision_20261004.json"))
	var count: int = 0
	for language: String in ["ru", "en"]:
		database.load_languages(language, language)
		for row: Dictionary in revision.changes:
			if row.language != language:
				continue
			count += 1
			var text: String = database.normalize_loaded_word(row.answer)
			var ref: Dictionary = database.resolve_saved_word(int(row.theme_id), text, row.id)
			check(!ref.is_empty() and ref.id == row.id, "Stable identity did not resolve: " + row.id)
			check(ref.hint == row.new_hint, "Runtime hint differs: " + row.id)
			var word: RefCounted = WORD.new(text, database.get_word_difficulty(database.get_theme_index_by_id(int(row.theme_id)), int(ref.index)), database.get_theme_index_by_id(int(row.theme_id)), int(ref.index), row.id)
			session.start_round(word)
			check(session.get_word_hint() == row.new_hint, "New round uses old hint: " + row.id)
			# Existing paid/unlocked hints are snapshots of the current round.
			var saved: Dictionary = session.to_save_data()
			saved.word_hint_text = row.hint
			saved.comment_hint_unlocked = true
			saved.open_hint_used = true
			saved.mistakes = 1
			check(session.restore_from_save_data(saved), "Old round did not restore: " + row.id)
			check(session.word_data.id == row.id and session.mistakes == 1 and session.comment_hint_unlocked and session.open_hint_used,
				"Paid hint or progress lost: " + row.id)
			check(session.get_word_hint() == row.hint, "Existing round snapshot changed: " + row.id)
			saved.erase("word_hint_text")
			check(session.restore_from_save_data(saved) and session.get_word_hint() == row.new_hint,
				"Missing saved hint did not fall back to current database: " + row.id)
			var label := Label.new()
			label.add_theme_font_override("font", FONTS.question_comment_font())
			label.add_theme_font_size_override("font_size", 25)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.size = Vector2(348.0, 202.0)
			label.text = row.new_hint
			root.add_child(label)
			check(label.get_minimum_size().y <= 202.0, "Comment popup overflow: " + row.id)
			label.free()
	check(count == 190, "Wrong hint revision quota")
	print("WORD_HINT_REVISION checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
