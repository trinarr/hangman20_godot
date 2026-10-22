extends Node
const MODEL = preload("res://scripts/core/tournament_model.gd")
const PROMPT = preload("res://scripts/ui/tournament_finish_popup.gd")
class TestUI extends "res://scripts/main_portrait.gd":
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false
	func _should_auto_resume_guided_single_player() -> bool:
		return false
var now := 1800000000
var checks := 0
var failures := 0

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
	elif OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for _i in range(6):
		await get_tree().process_frame

func make_tournament(rank: int, expired: bool = true) -> void:
	var state := MODEL.create(now, "ru", GameState.GAME_DESIGN.get_value("tournament"), 777)
	var final_rows := MODEL.standings(state, int(state.ends_at))
	state.player_stars = int(final_rows[rank - 1].stars) + 1 if rank < 10 else 0
	GameState.tournament_state = state
	if expired:
		now = int(state.ends_at)

func run() -> void:
	GameState.tournament_time_source = func(): return now
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.single_player = {}
	GameState.tournament_state = {}
	GameState.player_name = "TournamentPlayer"
	var main := TestUI.new()
	add_child(main)
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Idle tournament has no automatic popup")
	make_tournament(1, false)
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Active tournament has no finish popup")
	now = int(GameState.tournament_state.ends_at)
	var watcher: Node = main.content.get_node("TournamentFinishPrompt")
	watcher.present_if_needed()
	check(is_instance_valid(watcher.popup), "Tournament finishing while Home is open presents its reward")
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).size() == 1, "Home reentry removes the old popup and presents one unclaimed reward")
	main._show_leaderboard_screen()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Leaving Home cancels popup and its pending animation")
	make_tournament(10)
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "No prize means no blocking popup")
	for dimensions: Vector2i in [Vector2i(960,1600), Vector2i(690,1536)]:
		get_window().size = dimensions
		for language: String in ["ru", "en"]:
			Database.interface_language = language
			TranslationServer.set_locale(language)
			for rank in [1, 2, 3]:
				make_tournament(rank)
				main.show_menu()
				await settle()
				watcher = main.content.get_node("TournamentFinishPrompt")
				var popup: CanvasLayer = watcher.popup
				check(is_instance_valid(popup), "Prize winner sees automatic popup")
				if !is_instance_valid(popup):
					continue
				await get_tree().create_timer(0.9).timeout
				check(popup.stage.open_bounce_complete, "Popup entrance settles")
				check(main._portrait_handle_modal_back_request(), "Back is consumed by the mandatory popup")
				var click := InputEventMouseButton.new()
				click.button_index = MOUSE_BUTTON_LEFT
				click.pressed = true
				popup.dimmer.gui_input.emit(click)
				check(is_instance_valid(watcher.popup), "Dimmer input cannot dismiss the popup")
				var action_count := 0
				for child: Node in popup.stage.get_children():
					if child is FlashStageTextureButton:
						action_count += 1
				check(action_count == 1, "Claim is the only popup button; there is no close button")
				var result: Control = popup.find_child("TournamentFinishPlayerResult", true, false)
				check(result.find_child("PlayerName", true, false).text == GameState.player_name, "Result row uses own profile name")
				check(result.find_child("PlayerRankMedal", true, false).get_meta("rank") == rank, "Result row shows the final place")
				var snapshot := GameState.get_tournament_snapshot()
				var previous_bottom := 0.0
				for place in range(1, 4):
					var card: Control = result if place == rank else popup.find_child("TournamentFinishPlace%d" % place, true, false)
					check(card != null and int(card.get_meta("rank")) == place, "All three prize places have a result card")
					check(card.get_global_rect().position.y > previous_bottom, "Prize cards are ordered without overlaps")
					previous_bottom = card.get_global_rect().end.y
					var face: Panel = card.find_child("CardFace", true, false)
					var expected_color: Color = PROMPT.ROW.PALETTE.BUTTON_SELECTED_ACCENT if place == rank else PROMPT.ROW.PALETTE.PRESS_HIGHLIGHT
					check(face.get_theme_stylebox("panel").bg_color == PROMPT.ROW.CARD.face_style(expected_color).bg_color, "Only the player's card uses the shared leaderboard highlight")
					var expected: Dictionary = snapshot.rows[place - 1]
					check(card.find_child("PlayerScore", true, false).value == main._grouped_counter_text(int(expected.stars)), "Each card shows its final score")
				var amount: Label = popup.find_child("TournamentFinishAmount", true, false)
				check((amount == null) == (rank == 1), "Only coin rewards show an amount below the art")
				if amount != null:
					check(amount.text == "x%d" % int(GameState.get_tournament_snapshot().reward), "Coin amount matches the earned prize")
					var coin: Control = popup.find_child("TournamentFinishReward", true, false)
					var amount_rect: Rect2 = amount.get_parent().stage_rect
					var panel: Control = popup.find_child("TournamentFinishDescriptionPanel", true, false)
					check(amount_rect.position.y < coin.stage_rect.end.y, "Counter touches the coin art with the reward-chain overlap")
					check(is_equal_approx((coin.stage_rect.position.y + amount_rect.end.y) * 0.5, panel.stage_rect.get_center().y), "Complete coin and counter block is vertically centered")
				else:
					check(popup.find_child("TournamentFinishReward", true, false).stage_rect.size.is_equal_approx(Vector2.ONE * 115.2 * 0.95), "Gift retains its additional five-percent reduction")
				var description: Label = popup.find_child("TournamentFinishDescription", true, false)
				check(description.text == tr("TOURNAMENT_FINISH_PROMPT"), "Description is localized")
				check(result.get_global_rect().position.y > description.get_global_rect().end.y, "Result row follows description")
				check(watcher.claim_button.get_global_rect().position.y > result.get_global_rect().end.y, "Only claim action follows the result row")
				var before := GameState.get_soft_currency()
				var reward := int(GameState.get_tournament_snapshot().reward)
				check(!bool(GameState.tournament_state.claimed), "Showing the popup does not pay the prize")
				await capture("tournament_finish_%dx%d_%s_rank%d" % [dimensions.x,dimensions.y,language,rank])
				GameState._save_batch_depth = 1
				watcher._claim()
				GameState._save_batch_depth = 0
				check(!bool(GameState.tournament_state.claimed) and watcher._error.text != "", "Failed claim retains the popup for retry")
				watcher._claim()
				watcher._claim()
				await settle()
				check(GameState.get_soft_currency() == before + reward and GameState.tournament_state.claimed, "Rapid claim persists exactly one payment")
				check(is_instance_valid(main._portrait_tournament_reward), "Claim opens the existing prize presentation")
				check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Claim removes the mandatory popup")
				main.show_menu()
				await settle()
				check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Claimed prize never prompts again")
	make_tournament(2)
	GameState.save_game()
	GameState.tournament_state = {}
	GameState.load_game()
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).size() == 1, "Unclaimed finish survives a save reload")
	GameState.accepted_legal_documents_version = 0
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Required legal consent takes priority over the prize prompt")
	main._remove_legal_consent_popup()
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	main._check_startup_guided_resume()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).size() == 1, "Prize prompt resumes once legal consent is complete")
	main.queue_free()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Destroying Home also removes its popup")
	GameState.tournament_time_source = Callable()
	print("TOURNAMENT_FINISH_POPUP checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func capture(filename: String) -> void:
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(directory.path_join(filename + ".png")) == OK, "Save GPU preview")
