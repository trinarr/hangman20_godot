extends Node

class TestUI extends "res://scripts/main_portrait.gd":
	func _ready() -> void:
		_build_root()
		_clear()

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
	elif OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func settle() -> void:
	for _i in range(6):
		await get_tree().process_frame

func coin_button(counters: Control) -> BaseButton:
	for child: Node in counters.get_children():
		if child is BaseButton:
			return child
	return null

func capture(suffix: String) -> void:
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	get_viewport().get_texture().get_image().save_png(directory.path_join(suffix + ".png"))

func run() -> void:
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = false
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		GameState.interface_language = language
		for size: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = Vector2i.ONE
			get_window().size = size
			GameState.ads_unlocked = true
			GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.UNKNOWN
			GameState.ad_region_rule = "unknown"
			var subscriptions := ConsentRegion.changed.get_connections().size()
			var main := TestUI.new()
			add_child(main)
			main.show_menu()
			await settle()
			main._home_logo_reveal.freeze_entrance()
			main._sync_home_button_entrance(1.0, 1.0, main._home_start_buttons)
			main._finish_home_button_entrance(main._home_start_buttons)
			var counters: Control = main._portrait_top_bar_content.get_node("HomeResourceCounters")
			var coin: Control = counters.get_node("CurrencyCounterVisual")
			check(!coin.has_node("ResourceAddBadgeVisual"), "Startup waits for regional permission")
			# Reproduce a successful asynchronous region lookup after Home was built.
			GameState.ad_region_rule = "automatic"
			ConsentRegion.changed.emit()
			await settle()
			coin = counters.get_node("CurrencyCounterVisual")
			check(coin.has_node("ResourceAddBadgeVisual"), "Delayed permission adds the green plus without reopening Home")
			var button := coin_button(counters)
			check(button != null and !button.disabled, "Delayed permission enables the coin counter")
			await capture("home_coins_%s_%d" % [language, size.x])
			if button != null:
				for pressed: bool in [true, false]:
					var event := InputEventMouseButton.new()
					event.button_index = MOUSE_BUTTON_LEFT
					event.pressed = pressed
					event.position = button.get_global_rect().get_center()
					get_viewport().push_input(event)
					await get_tree().process_frame
				await settle()
				check(get_tree().get_nodes_in_group(&"coin_refill_popup").size() == 1, "Real counter click opens exactly one coin popup")
				await get_tree().create_timer(0.6).timeout
				await capture("coin_popup_%s_%d" % [language, size.x])
				main._close_coin_store()
				await settle()
				check(coin_button(counters) != null, "Closing coin popup preserves the Home counter")
			GameState.ad_region_rule = "unknown"
			ConsentRegion.changed.emit()
			await settle()
			check(!counters.get_node("CurrencyCounterVisual").has_node("ResourceAddBadgeVisual"), "Expired regional permission removes the plus")
			GameState.ad_region_rule = "automatic"
			GameState.ads_unlocked = false
			ConsentRegion.changed.emit()
			GameState.ads_unlocked = true
			GameState.ads_became_available.emit()
			await settle()
			check(counters.get_node("CurrencyCounterVisual").has_node("ResourceAddBadgeVisual"), "Ads unlock also refreshes Home counters")
			main.queue_free()
			await settle()
			check(ConsentRegion.changed.get_connections().size() == subscriptions, "Leaving Home disconnects the permission listener")
	print("HOME_RESOURCE_COUNTERS checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
