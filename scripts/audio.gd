extends Node
## Music and sound effects. M toggles mute.

const SFX := ["jump", "crumb", "bonk", "ouch", "fall", "gameover", "newbest", "start", "click", "blip", "pause",
		"boing", "buy", "zone", "crunch", "whoosh"]
const MUSIC_DB := -14.0
const SFX_DB := -14.0
## Extra per-sound trim in dB, for the ones that play a lot or hit hard.
const SFX_TRIM := {"jump": -3.0, "blip": -4.0, "crumb": -2.0, "bonk": -2.0, "click": -2.0}
const VOICES := 6

var muted := false

var _streams := {}
var _music: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in SFX:
		_streams[name] = load("res://audio/%s.wav" % name)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		add_child(p)
		_voices.append(p)
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://audio/music.wav")
	_music.volume_db = MUSIC_DB
	_music.finished.connect(_music.play)
	add_child(_music)
	_music.play()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		toggle_mute()


func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	get_tree().call_group("sound_buttons", "set", "text", sound_label())


## Text for on-screen sound toggle buttons (put them in the "sound_buttons" group).
func sound_label() -> String:
	return "sound: off" if muted else "sound: on"


## Plays a sound effect. pitch_jitter randomizes pitch by up to that fraction.
func play(name: String, pitch_jitter := 0.0, pitch := 1.0) -> void:
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	p.stream = _streams[name]
	p.volume_db = SFX_DB + SFX_TRIM.get(name, 0.0)
	p.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	p.play()


## Muffles the music (pause / game over) or brings it back.
func duck(on: bool) -> void:
	create_tween().tween_property(_music, "volume_db", MUSIC_DB - 10.0 if on else MUSIC_DB, 0.3)
