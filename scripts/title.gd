extends Node2D
## Main menu.

var _t := 0.0
var _rotate_notice: Control
var _colors: Array


func _ready() -> void:
	Audio.duck(false)
	_colors = Game.body_colors()
	var touch := Game.touch
	var ui := Control.new()
	ui.size = Vector2(480, 270)
	add_child(ui)
	ScreenArt.label(ui, "DESK DASH", 44, 18)
	ScreenArt.label(ui, "you're just a little guy. the world is very big. run.", 13, 78, Palette.INK)
	var stats := "crumb jar: %d" % Game.bank
	if Game.best > 0:
		stats = "best %d      " % Game.best + stats
	ScreenArt.label(ui, stats, 13, 96, Palette.INK)
	var entries := [["run!", _start], ["shop", Game.go_to_shop], [Audio.sound_label(), Audio.toggle_mute]]
	if not OS.has_feature("web"):
		entries.append(["quit", get_tree().quit])
	var buttons := ScreenArt.button_row(ui, 226, entries)
	buttons[2].add_to_group("sound_buttons")
	buttons[0].grab_focus()
	var hint := "tap to jump    hold to go higher" if touch else "space: jump (hold to go higher)    esc pause    m mute"
	ScreenArt.label(ui, hint, 11, 252, Palette.WHITE)

	# phones held upright get a tiny letterboxed game; suggest turning sideways
	_rotate_notice = ColorRect.new()
	_rotate_notice.color = Palette.INK
	_rotate_notice.size = Vector2(480, 270)
	_rotate_notice.visible = false
	ui.add_child(_rotate_notice)
	ScreenArt.label(_rotate_notice, "turn your phone sideways", 30, 105)
	ScreenArt.label(_rotate_notice, "the desk is very wide.", 16, 145, Palette.MIST)


func _start() -> void:
	Audio.play("start")
	Game.start_game()


func _process(delta: float) -> void:
	_t += delta
	var win := DisplayServer.window_get_size()
	_rotate_notice.visible = win.y > win.x
	queue_redraw()


func _draw() -> void:
	ScreenArt.draw_room(self)
	var breathe := 1.0 + sin(_t * 2.5) * 0.05
	GuyArt.draw_guy(self, Vector2(240, 214), Vector2(2.0 / breathe, 2.0 * breathe), _colors[0], _colors[1],
			Palette.MINT, sin(_t * 0.7) * 0.6, fmod(_t, 3.2) < 0.12, 0.0, Game.hat)
