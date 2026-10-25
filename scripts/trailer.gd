extends Node
## Scripted trailer and store screenshots, recorded from the real game.
##   Trailer:     godot --path . res://scenes/trailer.tscn --write-movie build/trailer/trailer.avi
##   Screenshots: godot --path . res://scenes/trailer.tscn -- --shots   (saves into build/screenshots/)
## Each shot jumps the level ahead to a feature (a mug, a cliff, a doorway...) and lets a bot play it.

const RUNNER := preload("res://scenes/runner.tscn")
const TITLE := preload("res://scenes/title.tscn")
const SHOP := preload("res://scenes/shop.tscn")
const SHOT_DIR := "res://build/screenshots/"

var _runner: Node
var _bot_on := false
var _hold := 0
var _shots := false
var _caption: Label
var _note: PanelContainer
var _card: ColorRect
var _card_label: Label


class Drawer extends Node2D:
	var fn: Callable
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		fn.call(self, t)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shots = "--shots" in OS.get_cmdline_user_args()
	Game.best = 0
	_build_overlays()
	if _shots:
		_take_screenshots()
	else:
		_play()


# --- trailer timeline -------------------------------------------------------

func _play() -> void:
	await _type_card("you're just a little guy.", 26, 1.2)

	var room := _layer(30)
	var room_art := Drawer.new()
	room_art.fn = func(ci: CanvasItem, t: float):
		ScreenArt.draw_room(ci)
		GuyArt.draw_guy(ci, Vector2(240, 214), Vector2(2, 2), Palette.SALMON, Palette.PEACH, Palette.MINT,
				sin(t * 1.6) * 0.9, fmod(t, 2.2) > 2.08)
	room.add_child(room_art)
	_card.hide()
	_show_caption("the world is very big.", 30, 40, 2.2)
	await _wait(2.4)
	await _type_card("run.", 56, 0.6, false)
	Audio.play("start")
	room.queue_free()

	# A: climbing giant books on the desk
	await _shot_setup(0, 140.0, 11, "party", "classic", _is_kind.bind(GiantObject.Kind.MUG), 300.0)
	_show_caption("climb giant books", 22, 52, 2.4)
	await _wait(3.6)

	# B: grab a dorito, glide off the cliff, land on the landing zone
	await _flash()
	await _shot_ledge(2, 160.0, 12, "shades", "mint")
	_show_caption("grab a dorito...", 22, 52, 1.2)
	await _wait(1.5)
	_show_caption("...and glide!", 22, 52, 1.8)
	await _wait_until(func(): return _runner.player.is_on_floor() and not _runner.player.has_glider, 5.0)
	await _wait(1.4)

	# C: through a doorway into the next room
	await _flash()
	await _shot_setup(0, 150.0, 13, "crown", "lilac", func(c): return c is Doorway, 230.0)
	_show_caption("explore new rooms", 22, 52, 2.4)
	await _wait(3.4)

	# D: bouncing on pillows in the bed
	await _flash()
	await _shot_setup(3, 160.0, 14, "headphones", "sky", _is_kind.bind(GiantObject.Kind.PILLOW), 220.0)
	_show_caption("bounce on pillows", 22, 52, 2.4)
	await _wait(3.4)

	# E: the crumb shop
	await _flash()
	_clear_runner()
	var shop_layer := _layer(20)
	Game.bank = 999
	Game.hat = "party"
	Game.color = "classic"
	var shop := SHOP.instantiate()
	shop_layer.add_child(shop)
	_card.hide()
	_show_caption("dress up your little guy", 22, 214, 2.6)
	var looks := [["party", "classic"], ["tophat", "teal"], ["flower", "bubblegum"], ["chef", "lemon"],
			["crown", "lilac"], ["beanie", "sky"], ["headphones", "mint"]]
	for look in looks:
		shop._preview_hat = look[0]
		shop._preview_color = look[1]
		shop._info.text = "%s\n%s" % [Cosmetics.find(Cosmetics.HATS, look[0]).name,
				Cosmetics.find(Cosmetics.COLORS, look[1]).name]
		for b in shop._grid.get_children():
			if b.get_meta("item").id == look[0]:
				b.grab_focus()
		Audio.play("click", 0.0, 1.2)
		await _wait(0.42)
	await _flash()
	shop_layer.queue_free()

	# end card
	Game.hat = "party"
	var end := _layer(45)
	var end_art := Drawer.new()
	end_art.fn = func(ci: CanvasItem, t: float):
		ScreenArt.draw_room(ci)
		var hop := -absf(sin(t * 4.0)) * 6.0
		GuyArt.draw_guy(ci, Vector2(240, 214 + hop), Vector2(2, 2), Palette.SALMON, Palette.PEACH,
				Palette.MINT, 0.0, fmod(t, 2.5) > 2.38, 0.0, "party")
	end.add_child(end_art)
	var ui := Control.new()
	ui.size = Vector2(480, 270)
	end.add_child(ui)
	ScreenArt.label(ui, "DESK DASH", 50, 18)
	ScreenArt.label(ui, "you're just a little guy. the world is very big. run.", 13, 84, Palette.INK)
	ScreenArt.label(ui, "play free in your browser", 18, 226)
	Audio.duck(false)
	await _wait(4.0)
	_card.show()
	_card_label.text = ""
	_card.modulate.a = 0.0
	_card.get_parent().layer = 99
	await create_tween().tween_property(_card, "modulate:a", 1.0, 0.6).finished
	await _wait(0.3)
	get_tree().quit()


# --- screenshots ------------------------------------------------------------

func _take_screenshots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_card.hide()

	# 1: main menu, wearing a party hat
	Game.hat = "party"
	Game.bank = 128
	var title_layer := _layer(20)
	var title := TITLE.instantiate()
	title_layer.add_child(title)
	await _wait(0.6)
	for b in title.find_children("*", "Button", true, false):
		if b.text == "quit":
			b.hide()
	await _wait(0.3)
	await _save_shot("1-title.png")
	title_layer.queue_free()

	# 2: climbing books toward a mug on the desk
	await _shot_setup(0, 140.0, 11, "party", "classic", _is_kind.bind(GiantObject.Kind.MUG), 300.0)
	# up on the books, leaping for the mug
	await _wait_until(func(): return _runner.player.position.y < Runner.DESK_Y - 66.0, 6.0)
	await _freeze_shot("2-climb.png")

	# 3: gliding on a dorito toward the landing zone
	await _shot_ledge(2, 160.0, 12, "shades", "mint")
	await _wait_until(func(): return _runner.player._gliding, 6.0)
	await _wait(1.0) # out over the drop
	await _freeze_shot("3-glide.png")

	# 4: a doorway from the kitchen into the bed
	await _shot_setup(2, 150.0, 15, "crown", "lilac", func(c): return c is Doorway, 230.0)
	var door := _first(func(c): return c is Doorway)
	await _wait_until(func(): return _runner.player.position.x > door.position.x - 75.0, 4.0)
	await _freeze_shot("4-doorway.png")

	# 5: the crumb shop
	_clear_runner()
	Game.bank = 186
	Game.hat = "party"
	Game.color = "classic"
	Game.owned = ["hat:none", "color:classic", "hat:party", "hat:bow", "color:mint"]
	var shop_layer := _layer(20)
	var shop := SHOP.instantiate()
	shop_layer.add_child(shop)
	await _wait(0.5)
	for b in shop._grid.get_children():
		if b.get_meta("item").id == "tophat":
			b.grab_focus()
	shop._preview_color = "teal"
	await _wait(0.4)
	await _save_shot("5-shop.png")
	get_tree().quit()


func _save_shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(SHOT_DIR + file)
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)


func _freeze_shot(file: String) -> void:
	get_tree().paused = true
	await RenderingServer.frame_post_draw
	await _save_shot(file)
	get_tree().paused = false


# --- shot setup -------------------------------------------------------------

func _clear_runner() -> void:
	_bot_on = false
	Input.action_release("jump")
	if _runner and is_instance_valid(_runner):
		_runner.queue_free()
	_runner = null


## A fresh run in the given zone, fast-forwarded so the guy is `offset` px before the first
## object that matches `find`.
func _shot_setup(zone: int, speed: float, seed_val: int, hat: String, color: String, find: Callable,
		offset: float) -> void:
	await _fresh_runner(zone, speed, seed_val, hat, color)
	var target := _advance_to(find)
	_place(Vector2(target.position.x - offset, Runner.DESK_Y))
	_bot_on = true


## Starts him on top of a cliff ledge, just before the chip bag.
func _shot_ledge(zone: int, speed: float, seed_val: int, hat: String, color: String) -> void:
	await _fresh_runner(zone, speed, seed_val, hat, color)
	var bag := _advance_to(func(c): return c is ChipBag)
	_place(Vector2(bag.position.x - 45.0, bag.position.y - 0.5))
	_bot_on = true


func _fresh_runner(zone: int, speed: float, seed_val: int, hat: String, color: String) -> void:
	_clear_runner()
	await get_tree().process_frame
	Game.debug_start_zone = zone
	Game.hat = hat
	Game.color = color
	seed(seed_val)
	_runner = RUNNER.instantiate()
	_runner.say_intro = false
	add_child(_runner)
	_runner.speed = speed
	for l in _runner.find_children("*", "Label", true, false):
		if l.text.begins_with("tap") or l.text.begins_with("space") or l.text.begins_with("best"):
			l.hide()
	_card.hide()


func _advance_to(find: Callable) -> Node:
	get_tree().paused = true
	var x: float = _runner.camera.position.x
	while x < 30000.0:
		var hit := _first(find)
		if hit:
			return hit
		x += 300.0
		_runner.camera.position.x = x
		_runner._fill_ahead()
	return null


func _first(find: Callable) -> Node:
	if _runner == null:
		return null
	for c in _runner.world.get_children():
		if find.call(c) and c.position.x > _runner.player.position.x + 100.0:
			return c
	return null


func _place(pos: Vector2) -> void:
	var p: Player = _runner.player
	p.position = pos
	p.velocity = Vector2.ZERO
	_runner._update_camera()
	_runner.camera.reset_smoothing()
	_runner._cleanup()
	# don't replay every zone banner / thought we skipped past
	var starts: Array = _runner.zone_starts
	for i in starts.size():
		if starts[i][0] <= pos.x:
			_runner._shown_zone = i
	Game.distance_cm = int((pos.x - _runner._start_x) * Runner.CM_PER_PX)
	_runner._next_say_cm = Game.distance_cm + 120
	get_tree().paused = false


func _is_kind(c: Node, kind: GiantObject.Kind) -> bool:
	return c is GiantObject and c.kind == kind


# --- bot --------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if not _bot_on or _runner == null or not is_instance_valid(_runner) or get_tree().paused:
		return
	var p: Player = _runner.player
	if p._dead:
		return
	# gliding: hold to stay up, let go near the landing zone to sink onto it
	if p.has_glider and not p.is_on_floor():
		var pad_x := INF
		for pad in _runner._pads:
			if is_instance_valid(pad) and pad.position.x > p.position.x - 50.0:
				pad_x = minf(pad_x, pad.position.x)
		if p.position.x < pad_x - 240.0:
			Input.action_press("jump")
		else:
			Input.action_release("jump")
		return
	if _hold > 0:
		_hold -= 1
		if _hold == 0:
			Input.action_release("jump")
		return
	if not p.is_on_floor():
		return
	var feet: float = p.position.y
	var lead: float = _runner.speed * 0.2 + 6.0
	var need := false
	var supported := false
	for c in _runner.world.get_children():
		if c is GiantObject or c is LandingPad:
			var left: float = c.position.x
			var w: float = c.size.x if c is GiantObject else LandingPad.SIZE.x
			if c is GiantObject and not c.solid:
				continue
			if absf(c.position.y - feet) < 2.0 and p.position.x + lead >= left and p.position.x + lead <= left + w:
				supported = true
			if c.position.y < feet - 9.5 and c.position.y > feet - 70.0:
				var dx: float = left - p.position.x
				if dx > 0 and dx < lead:
					need = true
		elif c is Thumbtack:
			var dx: float = c.position.x - 8.0 - p.position.x
			if dx > 0 and dx < lead and absf(c.position.y - feet) < 2.0:
				need = true
		elif c is Roller:
			var dx: float = c.position.x - p.position.x
			if dx > 0 and dx < (_runner.speed + c.roll_speed) * 0.2 + 6.0:
				need = true
	if not supported and not p.has_glider:
		var below := false
		for c in _runner.world.get_children():
			if c is GiantObject and c.kind == GiantObject.Kind.DESK and p.position.x + lead >= c.position.x \
					and p.position.x + lead <= c.position.x + c.size.x:
				below = true
		if not below:
			need = true
	if need:
		Input.action_press("jump")
		_hold = 20


# --- overlays ---------------------------------------------------------------

func _layer(layer: int) -> CanvasLayer:
	var l := CanvasLayer.new()
	l.layer = layer
	add_child(l)
	return l


func _build_overlays() -> void:
	var card_layer := _layer(40)
	_card = ColorRect.new()
	_card.color = Palette.INK
	_card.size = Vector2(480, 270)
	card_layer.add_child(_card)
	_card_label = ScreenArt.label(_card, "", 26, 110)
	# captions sit on a little sticky note so they read over any background
	var cap_layer := _layer(60)
	_note = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.BUTTER
	style.border_color = Palette.INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 0
	style.content_margin_bottom = 2
	style.shadow_color = Color(Palette.INK, 0.35)
	style.shadow_offset = Vector2(3, 3)
	_note.add_theme_stylebox_override("panel", style)
	_note.modulate.a = 0.0
	_note.rotation_degrees = -2.5
	cap_layer.add_child(_note)
	_caption = Label.new()
	_caption.add_theme_color_override("font_color", Palette.INK)
	_note.add_child(_caption)


func _type_card(text: String, size: int, hold: float, blips := true) -> void:
	_card.show()
	_card.modulate.a = 1.0
	_card_label.label_settings.font_size = size
	_card_label.size.y = size * 1.5
	_card_label.position.y = 135 - size * 0.75
	_card_label.text = text
	_card_label.visible_characters = 0
	for i in text.length():
		_card_label.visible_characters = i + 1
		if blips and (i == 0 or text[i - 1] == " "):
			Audio.play("blip", 0.0, 1.0 + (i % 3) * 0.15)
		await _wait(0.05)
	await _wait(hold)


## A quick dip to ink between shots.
func _flash() -> void:
	_card_label.text = ""
	_card.modulate.a = 0.0
	_card.show()
	await create_tween().tween_property(_card, "modulate:a", 1.0, 0.12).finished
	_card.modulate.a = 1.0
	# the caller sets up the next shot while the screen is dark; it hides the card itself
	create_tween().tween_interval(0.0)


func _show_caption(text: String, size: int, y: float, hold: float) -> void:
	if _shots:
		return
	_caption.text = text
	_caption.add_theme_font_size_override("font_size", size)
	_note.reset_size()
	_note.size = _note.get_combined_minimum_size()
	_note.position = Vector2(240 - _note.size.x / 2.0, y)
	_note.pivot_offset = _note.size / 2.0
	_note.scale = Vector2(0.8, 0.8)
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(_note, "modulate:a", 1.0, 0.15)
	tw.tween_property(_note, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(hold)
	tw.chain().tween_property(_note, "modulate:a", 0.0, 0.3)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _wait_until(cond: Callable, timeout: float) -> void:
	var t := 0.0
	while t < timeout and not cond.call():
		await get_tree().process_frame
		t += get_process_delta_time()
