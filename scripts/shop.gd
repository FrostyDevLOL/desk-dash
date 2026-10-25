extends Node2D
## Crumb shop: spend crumbs from your runs on hats and colors for the little guy.

var _tab := "hat"
var _t := 0.0
var _preview_hat := "none"
var _preview_color := "classic"
var _grid: GridContainer
var _info: Label
var _jar: Label
var _tab_buttons := {}
var _back: Button


func _ready() -> void:
	Audio.duck(false)
	_preview_hat = Game.hat
	_preview_color = Game.color
	var ui := Control.new()
	ui.size = Vector2(480, 270)
	ui.theme = ScreenArt.theme()
	add_child(ui)
	ScreenArt.label(ui, "crumb shop", 30, -2)
	_jar = ScreenArt.label(ui, "", 16, 6)
	_jar.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_jar.size.x = 470
	_info = ScreenArt.label(ui, "", 13, 52, Palette.INK)
	_info.size.x = 180
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var tabs := HBoxContainer.new()
	tabs.position = Vector2(190, 44)
	tabs.size = Vector2(280, 26)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	ui.add_child(tabs)
	for kind in ["hat", "color"]:
		var b := Button.new()
		b.text = "hats" if kind == "hat" else "colors"
		b.toggle_mode = true
		b.pressed.connect(func():
			Audio.play("click")
			_show_tab(kind))
		tabs.add_child(b)
		_tab_buttons[kind] = b

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.position = Vector2(184, 76)
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	ui.add_child(_grid)

	_back = Button.new()
	_back.text = "back"
	_back.position = Vector2(10, 238)
	_back.pressed.connect(func():
		Audio.play("click")
		Game.go_to_title())
	ui.add_child(_back)

	_show_tab("hat")


func _show_tab(kind: String) -> void:
	_tab = kind
	for k in _tab_buttons:
		_tab_buttons[k].button_pressed = k == kind
	for c in _grid.get_children():
		c.queue_free()
	var list: Array = Cosmetics.HATS if kind == "hat" else Cosmetics.COLORS
	var first: Button
	for item in list:
		var b := Button.new()
		b.custom_minimum_size = Vector2(92, 31)
		b.add_theme_font_size_override("font_size", 11)
		b.set_meta("item", item)
		b.pressed.connect(_on_item_pressed.bind(b))
		b.focus_entered.connect(_preview.bind(item))
		b.mouse_entered.connect(_preview.bind(item))
		_grid.add_child(b)
		if first == null:
			first = b
	_refresh_labels()
	first.grab_focus()


func _refresh_labels() -> void:
	_jar.text = "crumbs: %d" % Game.bank
	for b in _grid.get_children():
		if b.is_queued_for_deletion():
			continue
		var item: Dictionary = b.get_meta("item")
		var equipped: bool = (Game.hat if _tab == "hat" else Game.color) == item.id
		var status: String
		if equipped:
			status = "wearing"
		elif Game.is_owned(_tab, item.id):
			status = "wear"
		else:
			status = "%d crumbs" % item.cost
		b.text = "%s\n%s" % [item.name, status]
		b.modulate.a = 1.0 if Game.is_owned(_tab, item.id) or Game.bank >= item.cost else 0.6


func _preview(item: Dictionary) -> void:
	if _tab == "hat":
		_preview_hat = item.id
	else:
		_preview_color = item.id
	var line: String = item.name
	if not Game.is_owned(_tab, item.id):
		line += "\n%d crumbs" % item.cost
		if Game.bank < item.cost:
			line += "\n(need %d more)" % (item.cost - Game.bank)
	_info.text = line


func _on_item_pressed(b: Button) -> void:
	var item: Dictionary = b.get_meta("item")
	var was_owned := Game.is_owned(_tab, item.id)
	if Game.buy_or_equip(_tab, item):
		Audio.play("click" if was_owned else "buy")
		if not was_owned:
			Fx.burst(self, Vector2(90, 150), Palette.BUTTER, 14, 80.0, 180.0, 120.0, 2.5)
	else:
		Audio.play("bonk", 0.0, 1.4)
		var tw := b.create_tween()
		for dx in [4.0, -4.0, 2.0, 0.0]:
			tw.tween_property(b, "position:x", b.position.x + dx, 0.04)
	_preview(item)
	_refresh_labels()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 480, 270), Palette.SKY)
	var x := 12.0
	while x < 480.0:
		draw_rect(Rect2(x, 0, 6, 270), Palette.PERI)
		x += 48.0
	draw_rect(Rect2(-2, 218, 484, 60), Palette.INK)
	draw_rect(Rect2(-1, 226, 482, 50), Palette.ROSE)
	draw_rect(Rect2(-1, 219, 482, 6), Palette.PEACH)
	# a little spotlight under the preview
	draw_set_transform(Vector2(90, 219), 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, 40.0, Color(Palette.BUTTER, 0.6))
	draw_set_transform(Vector2.ZERO)
	var c: Dictionary = Cosmetics.find(Cosmetics.COLORS, _preview_color)
	var breathe := 1.0 + sin(_t * 2.5) * 0.04
	GuyArt.draw_guy(self, Vector2(90, 219), Vector2(4.0 / breathe, 4.0 * breathe), c.body, c.belly,
			Palette.MINT, sin(_t * 0.8) * 0.5, fmod(_t, 3.0) < 0.12, 0.0, _preview_hat)
