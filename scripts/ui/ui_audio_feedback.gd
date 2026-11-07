extends AudioStreamPlayer
## Shared sound policy and original UI sounds; owned by the active screen.
const SOUND_SETTING_INDEX: int = 3
const CLICK_SOUND: AudioStream = preload("res://audio/Click.wav")
const POPUP_OPEN_SOUND: AudioStream = preload("res://audio/Popup_Open.wav")

static func enabled() -> bool:
	return GameState.settings.size() > SOUND_SETTING_INDEX and int(GameState.settings[SOUND_SETTING_INDEX]) == 2

static func play_stream(player: AudioStreamPlayer, stream: AudioStream) -> void:
	if !enabled() or player == null or stream == null:
		return
	player.stream = stream
	player.play()

func play_click() -> void:
	play_stream(self, CLICK_SOUND)

func play_popup_open() -> void:
	play_stream(self, POPUP_OPEN_SOUND)
