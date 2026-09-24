extends RefCounted

# Local debug output only; no file writes, network traffic or gameplay data.
# Compare the first and repeated visit to the same destination on the device.
static var _active_build = null
var _build_sections: Dictionary = {}

var _enabled: bool = OS.is_debug_build()
var _route: String
var _started_usec: int = 0
var _last_frame_usec: int = 0
var _longest_frame_usec: int = 0
var _longest_frame_phase: String = ""
var _phase: String = "setup"
var _build_usec: int = 0
var _build_started_usec: int = 0
var _finished: bool = false

static func section_start() -> int:
	if _active_build == null:
		return 0
	return Time.get_ticks_usec()

static func section_end(name: StringName, started_usec: int) -> void:
	if started_usec == 0 or _active_build == null:
		return
	_active_build.add_section(name, Time.get_ticks_usec() - started_usec)

func add_section(name: StringName, elapsed_usec: int) -> void:
	var entry: Vector2i = _build_sections.get(name, Vector2i.ZERO)
	_build_sections[name] = entry + Vector2i(elapsed_usec, 1)

func begin(route: String) -> void:
	if !_enabled:
		return
	_route = route
	_started_usec = Time.get_ticks_usec()
	_last_frame_usec = _started_usec

func sample_frame() -> void:
	if !_enabled or _started_usec == 0:
		return
	var now: int = Time.get_ticks_usec()
	var elapsed: int = now - _last_frame_usec
	if elapsed > _longest_frame_usec:
		_longest_frame_usec = elapsed
		_longest_frame_phase = _phase
	_last_frame_usec = now

func phase(value: String) -> void:
	if _enabled:
		_phase = value

func begin_build() -> void:
	if _enabled:
		_phase = "build / first draw"
		_build_sections.clear()
		_active_build = self
		_build_started_usec = Time.get_ticks_usec()

func end_build() -> void:
	if _enabled:
		_build_usec = Time.get_ticks_usec() - _build_started_usec
		if _active_build == self:
			_active_build = null

func finish() -> void:
	if _active_build == self:
		_active_build = null
	if !_enabled or _finished or _started_usec == 0:
		return
	_finished = true
	print("[HomeTransition] %s | build=%.1f ms | longest_frame=%.1f ms (%s) | total=%.1f ms" % [
		_route, float(_build_usec) / 1000.0, float(_longest_frame_usec) / 1000.0,
		_longest_frame_phase, float(Time.get_ticks_usec() - _started_usec) / 1000.0
	])
	if !_build_sections.is_empty():
		var sections := PackedStringArray()
		for name: StringName in _build_sections:
			var entry: Vector2i = _build_sections[name]
			sections.append("%s=%.1f ms (%d)" % [name, float(entry.x) / 1000.0, entry.y])
		print("[HomeBuild] %s | %s" % [_route, " | ".join(sections)])
