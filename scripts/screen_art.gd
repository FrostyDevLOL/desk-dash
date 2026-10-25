class_name ScreenArt
## Shared UI bits: labels, buttons, speech bubbles and the title-screen room (480x270, no camera).

static var _theme: Theme


static func label(parent: Node, text: String, size: int, y: float, color := Palette.WHITE) -> Label:
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	if color == Palette.INK:
		settings.outline_size = 0
	else:
		settings.outline_size = maxi(4, size / 4)
		settings.outline_color = Palette.INK
	var l := Label.new()
	l.text = text
	l.label_settings = settings
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(480, size * 1.5)
	l.position = Vector2(0, y)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


## Theme for buttons: sticky-note colored, ink outline.
static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	var states := {"normal": Palette.WHITE, "hover": Palette.BUTTER, "pressed": Palette.PEACH,
			"focus": Palette.BUTTER, "disabled": Palette.MIST}
	for state in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[state]
		sb.border_color = Palette.PINK if state == "focus" else Palette.INK
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 1
		sb.content_margin_bottom = 3
		_theme.set_stylebox(state, "Button", sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		_theme.set_color(c, "Button", Palette.INK)
	_theme.set_font_size("font_size", "Button", 15)
	return _theme


## A row of buttons centered horizontally at y. Each entry is [text, callable].
## Returns the buttons; the first one is a good default focus.
static func button_row(parent: Control, y: float, entries: Array) -> Array[Button]:
	var row := HBoxContainer.new()
	row.theme = theme()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.position = Vector2(0, y)
	row.size = Vector2(480, 26)
	parent.add_child(row)
	var buttons: Array[Button] = []
	for e in entries:
		var b := Button.new()
		b.text = e[0]
		b.pressed.connect(func():
			Audio.play("click")
			e[1].call())
		row.add_child(b)
		buttons.append(b)
	return buttons


static func make_bubble(text: String) -> PanelContainer:
	var bubble := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.WHITE
	style.border_color = Palette.INK
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(2)
	style.content_margin_left = 5
	style.content_margin_right = 5
	bubble.add_theme_stylebox_override("panel", style)
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Palette.INK)
	l.add_theme_font_size_override("font_size", 12)
	bubble.add_child(l)
	bubble.z_index = 20
	return bubble


static func draw_room(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 480, 270), Palette.SKY)
	var x := 12.0
	while x < 480.0:
		ci.draw_rect(Rect2(x, 0, 6, 270), Palette.PERI)
		x += 48.0
	# desk
	ci.draw_rect(Rect2(-2, 214, 484, 60), Palette.INK)
	ci.draw_rect(Rect2(-1, 222, 482, 50), Palette.ROSE)
	ci.draw_rect(Rect2(-1, 215, 482, 6), Palette.PEACH)
	# a giant mug on the right, partly off screen
	ci.draw_arc(Vector2(476, 140), 26.0, -PI / 2.0, PI / 2.0, 20, Palette.INK, 10.0)
	ci.draw_arc(Vector2(476, 140), 26.0, -PI / 2.0, PI / 2.0, 20, Palette.WHITE, 7.0)
	ci.draw_rect(Rect2(380, 90, 100, 125), Palette.INK)
	ci.draw_rect(Rect2(381, 91, 98, 123), Palette.WHITE)
	ci.draw_rect(Rect2(381, 91, 98, 7), Palette.ROSE)
	GuyArt.draw_heart(ci, Vector2(430, 150), 16.0, Palette.PINK)
	# a tall book on the left
	ci.draw_rect(Rect2(20, 60, 50, 155), Palette.INK)
	ci.draw_rect(Rect2(21, 61, 48, 153), Palette.NAVY)
	ci.draw_rect(Rect2(21, 72, 48, 5), Palette.BUTTER)
	ci.draw_rect(Rect2(21, 196, 48, 5), Palette.BUTTER)
