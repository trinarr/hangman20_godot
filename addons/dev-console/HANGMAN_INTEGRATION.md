# Hangman integration

Upstream: https://github.com/cherttov/godot-dev-console/tree/v1.1.1
The GDScript addon and its bundled font are included; the optional C# API is omitted.

Local adjustments: enforced debug-only initialization and calls, synchronized visible getter,
2000-paragraph output limit, portrait-friendly default size, enabled mobile command keyboard
without automatic keyboard opening on touchscreen devices. Upstream licenses are retained.

`DebugLogBridge` registers Godot Logger before game autoloads. It mirrors Godot stdout,
stderr, warnings and errors through a bounded thread-safe queue. The ordinary log remains
intact. Native Android SDK Logcat is not a Godot Logger stream.

Four taps: top-right 18% of viewport width by 10% of height; maximum gap 450 ms,
maximum total 1500 ms; releases within 300 ms, movement within 3% of viewport width.
Touches and real mouse clicks are supported; emulated mouse events are ignored.
Earlier taps keep normal UI behavior; the fourth release opens/closes the console.
Release builds neither register the logger nor create the console UI or handle the gesture.

Smoke tests:
`godot --headless --path . res://tools/tests/developer_console_smoke.tscn`
