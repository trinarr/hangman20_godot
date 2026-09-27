extends Node
# godot --headless --path . res://tools/tests/developer_console_smoke.tscn
var failed: int = 0
var checks: int = 0
func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	check(DevConsole._console_ready, "real addon initialized")
	check(not DevConsole.visible, "console starts hidden")
	check(DevConsole._console.layer > 510, "console above legal/settings popups")
	print("[HomeBuild] smoke build=1ms")
	print("[HomeTransition] smoke transition")
	print("[Difficulty] test difficulty")
	print("[b]literal BBCode[/b]")
	printerr("Console stderr test")
	push_warning("Console warning test")
	var worker := Thread.new()
	worker.start(func() -> void: print("Worker thread log"))
	worker.wait_to_finish()
	await get_tree().process_frame
	DebugLogBridge._process(0.0)
	var output: String = DevConsole._console.output_rtl.get_parsed_text()
	for marker: String in ["[HomeBuild]", "[HomeTransition]", "[Difficulty]", "[b]literal BBCode[/b]", "Console stderr test", "Console warning test", "Worker thread log"]:
		check(marker in output, "mirrored: " + marker)
	check(DebugLogBridge._logger.take_batch().is_empty(), "rendering logs does not log recursively")
	var rect: Rect2 = get_viewport().get_visible_rect()
	var corner: Vector2 = rect.position + rect.size * Vector2(0.96, 0.04)
	for i: int in range(3):
		DebugLogBridge._record_tap(corner, 1000 + i * 150)
	check(not DevConsole.visible, "three taps do not open")
	DebugLogBridge._record_tap(corner, 1450)
	check(DevConsole.visible, "four quick taps open")
	DevConsole._console.close_btn.pressed.emit()
	check(not DevConsole.visible, "close button synchronizes public visibility")
	for i: int in range(4):
		DebugLogBridge._record_tap(corner, 3000 + i * 600)
	check(not DevConsole.visible, "slow taps rejected")
	DebugLogBridge._reset_taps()
	for i: int in range(3):
		DebugLogBridge._record_tap(corner, 6000 + i * 100)
	DebugLogBridge._record_tap(rect.get_center(), 6350)
	DebugLogBridge._record_tap(corner, 6400)
	check(not DevConsole.visible, "tap outside resets sequence")
	DebugLogBridge._reset_taps()
	for i: int in range(2):
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = corner
		touch.pressed = true
		DebugLogBridge._input(touch)
		touch.pressed = false
		DebugLogBridge._input(touch)
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.device = -1
		mouse.position = corner
		mouse.pressed = true
		DebugLogBridge._input(mouse)
		mouse.pressed = false
		DebugLogBridge._input(mouse)
	check(DebugLogBridge._tap_count == 2 and not DevConsole.visible, "emulated mouse does not double-count touch")
	DebugLogBridge._reset_taps()
	var probe := DebugLogBridge.ConsoleLogger.new()
	for i: int in range(2200):
		probe._log_message(str(i), false)
	check(probe._pending.size() == 2048, "pending logs bounded")
	var batch: Array[Dictionary] = probe.take_batch()
	check("Skipped 152" in str(batch.back()["text"]), "overflow explicitly reported")
	for i: int in range(2010):
		DevConsole.print_line("bounded output %d" % i)
	check(DevConsole._console.output_rtl.get_paragraph_count() <= 2000, "console history bounded")
	print("CONSOLE TESTS: %d checks, %d failures" % [checks, failed])
	get_tree().quit(1 if failed else 0)
