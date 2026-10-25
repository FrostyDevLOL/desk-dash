class_name Runner
extends Node2D
## Endless runner: spawns floor segments and obstacles ahead of the little guy.
## The run passes through four zones (desk, bookshelf, kitchen counter, bed) that loop.
## Objects are sized like the real thing next to a ~1.5 cm guy (about 10 px per cm).

const DESK_Y := 210.0
const START_SPEED := 120.0
const MAX_SPEED := 240.0
const SPEED_GAIN := 2.0 # px/s added every second
const CAMERA_LEAD := 100.0
const CM_PER_PX := 0.1
const ZONE_LEN := 3000.0 # px (300 cm) per zone
const SAY_EVERY_CM := 150

const ZONES := [
	{
		"name": "the desk", "floor": GiantObject.Floor.DESK, "door": Color("4c64a8"),
		"spike": Thumbtack.Style.TACK, "roller": Roller.Style.MARBLE, "bounce": "eraser",
		"line": "so many books...",
		"features": ["spikes", "spikes", "spikes", "books", "books", "books", "pencil", "notepad",
				"bounce", "mug", "mug", "roller", "crumbs"],
	},
	{
		"name": "the bookshelf", "floor": GiantObject.Floor.SHELF, "door": Color("945c7c"),
		"spike": Thumbtack.Style.TACK, "roller": Roller.Style.MARBLE, "bounce": "eraser",
		"line": "smells like old paper.",
		"features": ["standing", "standing", "standing", "books", "books", "bookend", "bookend",
				"cactus", "cactus", "roller", "spikes", "crumbs"],
	},
	{
		"name": "the kitchen counter", "floor": GiantObject.Floor.COUNTER, "door": Color("009c8c"),
		"spike": Thumbtack.Style.FORK, "roller": Roller.Style.PEA, "bounce": "marshmallow",
		"line": "everything smells like toast.",
		"features": ["plates", "plates", "board", "board", "sugar", "sugar", "spikes", "spikes",
				"spikes", "roller", "roller", "bounce", "bounce", "crumbs"],
	},
	{
		"name": "the bed", "floor": GiantObject.Floor.BED, "door": Color("9c9cd8"),
		"spike": Thumbtack.Style.PIN, "roller": Roller.Style.BUTTON, "bounce": "pillow",
		"line": "so soft. must not nap.",
		"features": ["bounce", "bounce", "bounce", "phone", "phone", "sock", "sock", "spikes",
				"spikes", "spikes", "roller", "roller", "books", "crumbs"],
	},
]
## Features that only appear once the run has sped up a bit (difficulty 0..1).
const MIN_DIFFICULTY := {"mug": 0.12, "roller": 0.2, "cactus": 0.08}

const THOUGHTS := [
	"i'm just a little guy.",
	"my legs are so small...",
	"why is everything so big?",
	"is that a crumb?!",
	"i believe in me.",
	"tiny steps. big world.",
	"don't step on me please",
]
const BOOK_COLORS := [["BLUE", "BUTTER"], ["PLUM", "PEACH"], ["SAGE", "WHITE"], ["VIOLET", "BUTTER"],
		["SALMON", "WHITE"], ["TEAL", "MINT"], ["NAVY", "PEACH"], ["ROSE", "BUTTER"], ["SLATE", "MIST"]]
const TACK_COLORS := ["PINK", "TEAL", "VIOLET", "BUTTER"]
const DEATH_SOUNDS := {"bonk": "bonk", "ouch": "ouch", "fall": "fall"}

var speed := START_SPEED
## Set false before adding to the tree to skip the "let's go" line (used by the trailer).
var say_intro := true
## [world_x, zone] pairs, read by the background to paint each zone's wall.
var zone_starts: Array = []

var _next_x := -300.0
var _segments := 0
var _start_x := 0.0
var _alive := true
var _next_say_cm := SAY_EVERY_CM
var _last_zone := -1
var _shown_zone := 0 # index into zone_starts of the zone the player is in
var _cliff_zone := -1 # zone count (not wrapped) that last got its cliff
var _pending_gap := 0.0 # the big drop after a cliff, used by the next segment
var _pads: Array[LandingPad] = []
const LANDING_BONUS := 10

var _hud_dist: Label
var _hud_crumbs: Label
var _pause_menu: Control
var _pause_buttons: Array[Button] = []
var _pause_button: Button
var _banner: PanelContainer
var _banner_label: Label
var _over: Control
var _touch := Game.touch

@onready var world: Node2D = $World
@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera


func _ready() -> void:
	# the runner keeps listening for the pause key while the world is frozen
	process_mode = Node.PROCESS_MODE_ALWAYS
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.process_mode = Node.PROCESS_MODE_PAUSABLE

	Game.reset_run()
	Audio.duck(false)
	player.position = Vector2(60, DESK_Y)
	_start_x = player.position.x
	player.kill_y = DESK_Y + 90.0
	player.run_speed = speed
	player.died.connect(_on_player_died)
	player.glide_ended.connect(_on_glide_ended)
	_build_hud()
	_update_camera()
	camera.reset_smoothing()
	_fill_ahead()
	if say_intro:
		_say.call_deferred("ok. let's go, little guy.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _alive:
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and not get_tree().paused:
		Game.start_game()
	elif _alive and not get_tree().paused:
		_handle_pointer_jump(event)


## Tap / click anywhere (except the pause button corner) to jump; hold for a bigger jump.
func _handle_pointer_jump(event: InputEvent) -> void:
	var pressed: bool
	var pos: Vector2
	if event is InputEventScreenTouch:
		pressed = event.pressed
		pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		pos = event.position
	else:
		return
	if pressed and pos.x > 430.0 and pos.y < 36.0:
		return
	if pressed:
		Input.action_press("jump")
	else:
		Input.action_release("jump")


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if _alive:
		speed = minf(speed + SPEED_GAIN * delta, MAX_SPEED)
		player.run_speed = speed
		Game.distance_cm = maxi(Game.distance_cm, int((player.position.x - _start_x) * CM_PER_PX))
		if Game.distance_cm >= _next_say_cm:
			_next_say_cm += SAY_EVERY_CM
			_say(THOUGHTS.pick_random())
		_check_zone_entry()
		_update_camera()
		_fill_ahead()
		_cleanup()
	_hud_dist.text = "%d cm" % Game.distance_cm
	_hud_crumbs.text = "crumbs %d" % Game.crumbs


func _update_camera() -> void:
	camera.position = Vector2(player.position.x + CAMERA_LEAD, 135)


func _difficulty() -> float:
	return inverse_lerp(START_SPEED, MAX_SPEED, speed)


func _zone_at(x: float) -> int:
	return (int(maxf(0.0, x - _start_x) / ZONE_LEN) + Game.debug_start_zone) % ZONES.size()


func _check_zone_entry() -> void:
	if _shown_zone + 1 >= zone_starts.size():
		return
	if player.position.x < zone_starts[_shown_zone + 1][0]:
		return
	_shown_zone += 1
	var z: Dictionary = ZONES[zone_starts[_shown_zone][1]]
	_show_banner(z.name)
	Audio.play("zone")
	_say(z.line)


# --- spawning -------------------------------------------------------------

func _fill_ahead() -> void:
	while _next_x < camera.position.x + 400.0:
		_spawn_segment()


func _cleanup() -> void:
	var left := camera.position.x - 300.0
	for c in world.get_children():
		var right: float = c.position.x + (c.size.x if c is GiantObject else 30.0)
		if right < left:
			c.queue_free()


func _spawn_segment() -> void:
	var d := _difficulty()
	var z := _zone_at(_next_x + 80.0)
	var zone_count := int(maxf(0.0, _next_x + 80.0 - _start_x) / ZONE_LEN)
	var into_zone := _next_x - _start_x - zone_count * ZONE_LEN
	# one big cliff in the middle of every zone
	if _segments > 0 and _pending_gap == 0.0 and z == _last_zone and zone_count != _cliff_zone \
			and into_zone > 1300.0 and into_zone < ZONE_LEN - 900.0:
		_cliff_zone = zone_count
		_build_cliff(z, d)
		return
	var gap := 0.0
	var landing := false
	var entering := false
	if _segments == 0:
		zone_starts.append([-INF, z])
	elif _pending_gap > 0.0:
		landing = true
		gap = _pending_gap
		_pending_gap = 0.0
		_build_drop(_next_x, gap)
		if z != _last_zone:
			_doorway(_next_x + gap + 26.0, z)
			zone_starts.append([_next_x + gap + 26.0, z])
	elif z != _last_zone:
		# a doorway marks the way into each new zone
		_doorway(_next_x, z)
		zone_starts.append([_next_x, z])
		entering = true
	elif randf() < lerpf(0.35, 0.65, d):
		gap = randf_range(34.0, speed * 0.42)
		_crumb_arc(_next_x, gap)
	_last_zone = z
	_next_x += gap

	var length := 900.0 if _segments == 0 else randf_range(320.0, 620.0)
	_obj(GiantObject.Kind.DESK, Vector2(_next_x, DESK_Y), Vector2(length, 200), Palette.ROSE, Palette.PEACH,
			{"floor_style": ZONES[z].floor})

	# the first segment gives a couple of seconds of free running; after a drop, keep the
	# landing pad clear
	var x := _next_x + 60.0
	if _segments == 0:
		x = _next_x + 650.0
	elif landing:
		x = _next_x + LandingPad.SIZE.x + 120.0
	elif entering:
		x = _next_x + 140.0 # a clear stretch to walk into the new room
	var end := _next_x + length - 40.0
	var min_space := speed * 0.65 + 10.0
	while true:
		var w := _spawn_feature(x, end, d, z)
		if w <= 0.0:
			break
		x += w + randf_range(min_space, min_space + 120.0)

	_next_x += length
	_segments += 1


## A staircase up to a high ledge with a bag of Chipitos on top. The next segment starts after
## a drop far too wide to jump: grab a dorito and glide across.
func _build_cliff(z: int, d: float) -> void:
	var run_up := 160.0
	# depth of each stair grows with speed, so there's always about the same time to land
	# before the next hop
	var step := maxf(100.0, speed * 0.85)
	var ledge := 150.0
	var length := run_up + step * 4.0 + ledge
	_obj(GiantObject.Kind.DESK, Vector2(_next_x, DESK_Y), Vector2(length, 200), Palette.ROSE, Palette.PEACH,
			{"floor_style": ZONES[z].floor})
	var x0 := _next_x + run_up
	var top := DESK_Y
	for i in 4:
		var h := 27.0
		top -= h
		var pos := Vector2(x0 + step * i, top)
		var size := Vector2(length - run_up - step * i, h)
		if z == 2:
			_obj(GiantObject.Kind.BOX, pos, size, Palette.PEACH, Palette.BUTTER)
		else:
			_book(pos, size)
		_crumb(Vector2(pos.x + 28.0, top - 12.0))
	var bag := ChipBag.new()
	bag.position = Vector2(x0 + step * 3.0 + 60.0, top)
	bag.picked.connect(func(): _show_banner("hold to glide!" if _touch else "hold jump to glide!", 205.0))
	world.add_child(bag)
	_next_x += length
	_pending_gap = lerpf(380.0, 520.0, d)
	_segments += 1


## The big drop after a cliff: clouds far below, a trail of crumbs along the glide, and a
## landing zone at the far side.
func _build_drop(x: float, gap: float) -> void:
	_obj(GiantObject.Kind.CLOUDS, Vector2(x, DESK_Y + 8.0), Vector2(gap, 60), Palette.WHITE, Palette.MIST,
			{"solid": false})
	var pad := LandingPad.new()
	pad.position = Vector2(x + gap, DESK_Y - LandingPad.SIZE.y)
	world.add_child(pad)
	_pads.append(pad)
	for i in 8:
		var t := (i + 0.5) / 8.0
		# roughly where a held glide flies from the ledge
		_crumb(Vector2(x + 30.0 + (gap - 60.0) * t, lerpf(DESK_Y - 112.0, DESK_Y - 55.0, t)))


## Places one obstacle/feature starting at x. Returns its width, or 0 if nothing fit before end.
func _spawn_feature(x: float, end: float, d: float, z: int) -> float:
	var zone: Dictionary = ZONES[z]
	var choices: Array = zone.features.filter(func(f): return d >= MIN_DIFFICULTY.get(f, 0.0))
	for attempt in 3:
		var w := _build(choices.pick_random(), x, end, d, zone)
		if w > 0.0:
			return w
	return 0.0


func _build(feature: String, x: float, end: float, d: float, zone: Dictionary) -> float:
	var room := end - x
	match feature:
		"spikes":
			var style: Thumbtack.Style = zone.spike
			var sw: float = Thumbtack.WIDTHS[style]
			var n := clampi(randi_range(1, 1 + int(d * 2.5)), 1, 3)
			if n * sw > room:
				return 0.0
			for i in n:
				_spike(Vector2(x + sw / 2.0 + i * sw, DESK_Y), style)
			_crumb(Vector2(x + n * sw / 2.0, DESK_Y - 48.0))
			return n * sw
		"cactus":
			if room < 18.0:
				return 0.0
			_spike(Vector2(x + 9.0, DESK_Y), Thumbtack.Style.CACTUS)
			_crumb(Vector2(x + 9.0, DESK_Y - 62.0))
			return 18.0
		"pencil":
			if room < 185.0:
				return 0.0
			_obj(GiantObject.Kind.PENCIL, Vector2(x, DESK_Y - 7.0), Vector2(170, 7), Palette.BUTTER, Palette.PEACH)
			for i in 4:
				_crumb(Vector2(x + 30.0 + i * 36.0, DESK_Y - 18.0))
			return 185.0
		"books":
			return _book_stack(x, room, d)
		"mug":
			# a two-book staircase up to a tall mug: hop, hop, then leap onto the mug
			if room < 215.0:
				return 0.0
			_book(Vector2(x, DESK_Y - 26.0), Vector2(118, 26))
			_book(Vector2(x + 8.0, DESK_Y - 52.0), Vector2(92, 26))
			_obj(GiantObject.Kind.MUG, Vector2(x + 122.0, DESK_Y - 84.0), Vector2(72, 84), Palette.WHITE,
					[Palette.PINK, Palette.LILAC, Palette.TEAL, Palette.SALMON].pick_random())
			for i in 3:
				_crumb(Vector2(x + 136.0 + i * 22.0, DESK_Y - 96.0))
			return 215.0
		"notepad":
			if room < 76.0:
				return 0.0
			_obj(GiantObject.Kind.NOTEPAD, Vector2(x, DESK_Y - 14.0), Vector2(76, 14),
					[Palette.BUTTER, Palette.PINK, Palette.MINT].pick_random(), Palette.WHITE)
			_crumb(Vector2(x + 25.0, DESK_Y - 26.0))
			_crumb(Vector2(x + 51.0, DESK_Y - 26.0))
			return 76.0
		"bounce":
			return _bounce_pad(x, room, zone.bounce)
		"roller":
			if room < 230.0:
				return 0.0
			var r := Roller.new()
			r.style = zone.roller
			r.roll_speed = lerpf(55.0, 95.0, d)
			r.position = Vector2(x + 230.0, DESK_Y - Roller.RADIUS[r.style])
			r.stop_x = x
			world.add_child(r)
			return 230.0
		"standing":
			return _standing_books(x, room)
		"bookend":
			if room < 30.0:
				return 0.0
			_obj(GiantObject.Kind.BOOKEND, Vector2(x, DESK_Y - 46.0), Vector2(10, 46), Palette.SLATE, Palette.PERI)
			_crumb(Vector2(x + 5.0, DESK_Y - 66.0))
			return 30.0
		"plates":
			if room < 140.0:
				return 0.0
			var n := randi_range(1, 3)
			for i in n:
				var pw := 140.0 - i * 14.0
				_obj(GiantObject.Kind.PLATE, Vector2(x + i * 7.0, DESK_Y - 7.0 * (i + 1)), Vector2(pw, 7),
						Palette.WHITE, [Palette.SKY, Palette.PINK, Palette.MINT].pick_random())
			_crumb(Vector2(x + 70.0, DESK_Y - 7.0 * n - 14.0))
			return 140.0
		"board":
			if room < 200.0:
				return 0.0
			_obj(GiantObject.Kind.BOARD, Vector2(x, DESK_Y - 13.0), Vector2(200, 13), Palette.PEACH, Palette.ROSE)
			for i in 3:
				_crumb(Vector2(x + 40.0 + i * 50.0, DESK_Y - 25.0))
			return 200.0
		"sugar":
			var rows := 4 if d > 0.5 and randf() < 0.5 else 3
			var cube := 18.0
			if rows * cube > room:
				return 0.0
			for row in rows:
				var count := rows - row
				for c in count:
					_obj(GiantObject.Kind.SUGAR, Vector2(x + row * cube / 2.0 + c * cube, DESK_Y - cube * (row + 1)),
							Vector2(cube, cube), Palette.WHITE, Palette.MIST)
			_crumb(Vector2(x + rows * cube / 2.0, DESK_Y - cube * rows - 12.0))
			return rows * cube
		"phone":
			if room < 130.0:
				return 0.0
			_obj(GiantObject.Kind.PHONE, Vector2(x, DESK_Y - 8.0), Vector2(130, 8), Palette.INK, Palette.SKY)
			for i in 3:
				_crumb(Vector2(x + 30.0 + i * 35.0, DESK_Y - 20.0))
			return 130.0
		"sock":
			if room < 70.0:
				return 0.0
			var socks := [[Palette.TEAL, Palette.BUTTER], [Palette.PINK, Palette.WHITE], [Palette.SAGE, Palette.MINT]]
			var c: Array = socks.pick_random()
			_obj(GiantObject.Kind.SOCK, Vector2(x, DESK_Y - 16.0), Vector2(70, 16), c[0], c[1])
			_crumb(Vector2(x + 35.0, DESK_Y - 28.0))
			return 70.0
		_:
			if room < 80.0:
				return 0.0
			for i in 5:
				_crumb(Vector2(x + i * 20.0, DESK_Y - 14.0 - sin(i / 4.0 * PI) * 26.0))
			return 80.0
	return 0.0


## 1-3 lying books, each smaller one stacked on the last: a little staircase to run across.
func _book_stack(x: float, room: float, d: float) -> float:
	var w := minf(randf_range(150.0, 220.0), room)
	if w < 120.0:
		return 0.0
	var n := 1
	if randf() < 0.5 + d * 0.3:
		n += 1
	if n == 2 and randf() < d * 0.7:
		n += 1
	var bx := x
	var bw := w
	var top := DESK_Y
	for i in n:
		var h := randf_range(24.0, 30.0) if i == 0 else randf_range(22.0, 27.0)
		top -= h
		_book(Vector2(bx, top), Vector2(bw, h))
		var shrink := randf_range(35.0, 60.0)
		bx += randf_range(8.0, shrink - 8.0)
		bw -= shrink
		if bw < 50.0:
			break
	for i in 3:
		_crumb(Vector2(bx - 10.0 + i * 22.0, top - 12.0))
	return w


## A row of upright books of different heights, reached from a lying book.
func _standing_books(x: float, room: float) -> float:
	if room < 160.0:
		return 0.0
	_book(Vector2(x, DESK_Y - 26.0), Vector2(46, 26))
	var bx := x + 46.0
	var h := randf_range(46.0, 52.0)
	var count := randi_range(4, 7)
	for i in count:
		var bw := randf_range(18.0, 26.0)
		if bx + bw > x + room:
			break
		_book(Vector2(bx, DESK_Y - h), Vector2(bw, h))
		if i % 2 == 1:
			_crumb(Vector2(bx + bw / 2.0, DESK_Y - h - 12.0))
		bx += bw
		h = clampf(h + randf_range(-14.0, 14.0), 38.0, 70.0)
	return bx - x


## Something squishy that launches him high, with a trail of crumbs up in the air.
func _bounce_pad(x: float, room: float, pad: String) -> float:
	var size := {"eraser": Vector2(34, 12), "marshmallow": Vector2(30, 20), "pillow": Vector2(140, 26)}[pad] as Vector2
	if room < size.x + 60.0:
		return 0.0
	var kinds := {"eraser": GiantObject.Kind.ERASER, "marshmallow": GiantObject.Kind.MARSHMALLOW,
			"pillow": GiantObject.Kind.PILLOW}
	var fill := {"eraser": Palette.PINK, "marshmallow": Palette.WHITE, "pillow": Palette.PERI}[pad] as Color
	var acc := {"eraser": Palette.MIST, "marshmallow": Palette.PINK, "pillow": Palette.LILAC}[pad] as Color
	_obj(kinds[pad], Vector2(x, DESK_Y - size.y), size, fill, acc, {"bouncy": true})
	var top := DESK_Y - size.y
	for t: float in [0.15, 0.3, 0.45, 0.6]:
		var h := 440.0 * t - 425.0 * t * t
		_crumb(Vector2(x + size.x / 2.0 + speed * t, top - h - 8.0))
	return size.x + 60.0


func _doorway(x: float, z: int) -> void:
	var door := Doorway.new()
	door.position = Vector2(x, DESK_Y)
	door.zone_name = ZONES[z].name
	door.door_color = ZONES[z].door
	world.add_child(door)


func _crumb_arc(x: float, gap: float) -> void:
	for i in 3:
		var t := (i + 1) / 4.0
		_crumb(Vector2(x + gap * t, DESK_Y - 22.0 - sin(t * PI) * 22.0))


func _obj(kind: GiantObject.Kind, pos: Vector2, size: Vector2, fill: Color, accent: Color, extra := {}) -> void:
	var o := GiantObject.new()
	o.kind = kind
	o.size = size
	o.fill = fill
	o.accent = accent
	o.position = pos
	for k in extra:
		o.set(k, extra[k])
	world.add_child(o)


func _book(pos: Vector2, size: Vector2) -> void:
	var c: Array = BOOK_COLORS.pick_random()
	_obj(GiantObject.Kind.BOOK, pos, size, _color(c[0]), _color(c[1]))


func _color(name: String) -> Color:
	return Palette.get_script().get_script_constant_map()[name]


func _spike(pos: Vector2, style: Thumbtack.Style) -> void:
	var t := Thumbtack.new()
	t.style = style
	t.color = _color(TACK_COLORS.pick_random())
	t.position = pos
	world.add_child(t)


func _crumb(pos: Vector2) -> void:
	var c := Crumb.new()
	c.position = pos
	world.add_child(c)


# --- talking --------------------------------------------------------------

func _say(text: String) -> void:
	if not _alive:
		return
	var bubble := ScreenArt.make_bubble(text)
	bubble.modulate.a = 0.0
	player.add_child(bubble)
	await get_tree().process_frame
	bubble.reset_size()
	bubble.position = Vector2(-bubble.size.x / 2.0, -30.0 - bubble.size.y)
	var tw := bubble.create_tween()
	tw.tween_property(bubble, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.8)
	tw.tween_property(bubble, "modulate:a", 0.0, 0.3)
	tw.tween_callback(bubble.queue_free)
	# little-guy babble: one blip per word
	for word in text.split(" ", false):
		if not _alive or not is_instance_valid(bubble):
			return
		Audio.play("blip", 0.0, randf_range(1.0, 1.5))
		await get_tree().create_timer(0.09, false).timeout


# --- HUD, zone banner, pause, game over ------------------------------------

func _full_rect_control(parent: Node) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


func _panel(parent: Control, rect: Rect2) -> void:
	var outer := ColorRect.new()
	outer.color = Palette.INK
	outer.position = rect.position - Vector2(2, 2)
	outer.size = rect.size + Vector2(4, 4)
	parent.add_child(outer)
	var inner := ColorRect.new()
	inner.color = Palette.WHITE
	inner.position = rect.position
	inner.size = rect.size
	parent.add_child(inner)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := _full_rect_control(layer)
	_hud_dist = ScreenArt.label(root, "", 30, -4)
	_hud_crumbs = ScreenArt.label(root, "", 18, 4)
	_hud_crumbs.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_crumbs.size.x = 436 if _touch else 472
	var best := ScreenArt.label(root, "best %d" % Game.best, 16, 5)
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	best.position.x = 8
	if _touch:
		_pause_button = Button.new()
		_pause_button.theme = ScreenArt.theme()
		_pause_button.text = "II"
		_pause_button.position = Vector2(444, 5)
		_pause_button.size = Vector2(30, 24)
		_pause_button.focus_mode = Control.FOCUS_NONE
		_pause_button.pressed.connect(func(): _set_paused(true))
		root.add_child(_pause_button)
	var hint_text := "tap to jump    hold to go higher" if _touch \
			else "space to jump    hold it to go higher    esc: pause"
	var hint := ScreenArt.label(root, hint_text, 13, 248)
	var tw := hint.create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(hint, "modulate:a", 0.0, 1.0)

	# sticky-note banner announcing each zone
	_banner = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.BUTTER
	style.border_color = Palette.INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 2
	style.shadow_color = Color(Palette.INK, 0.35)
	style.shadow_offset = Vector2(3, 3)
	_banner.add_theme_stylebox_override("panel", style)
	_banner.rotation_degrees = -2.5
	_banner.modulate.a = 0.0
	root.add_child(_banner)
	_banner_label = Label.new()
	_banner_label.add_theme_color_override("font_color", Palette.INK)
	_banner_label.add_theme_font_size_override("font_size", 24)
	_banner.add_child(_banner_label)

	_pause_menu = _full_rect_control(layer)
	_pause_menu.visible = false
	var dim := ColorRect.new()
	dim.color = Color(Palette.INK, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_menu.add_child(dim)
	_panel(_pause_menu, Rect2(55, 78, 370, 114))
	ScreenArt.label(_pause_menu, "paused", 28, 84, Palette.INK)
	ScreenArt.label(_pause_menu, "the little guy is taking a breather", 12, 122, Palette.INK)
	_pause_buttons = ScreenArt.button_row(_pause_menu, 152, [
		["keep running", _set_paused.bind(false)],
		[Audio.sound_label(), Audio.toggle_mute],
		["main menu", Game.go_to_title],
	])
	_pause_buttons[1].add_to_group("sound_buttons")

	_over = _full_rect_control(layer)
	_over.visible = false


func _show_banner(text: String, y := 48.0) -> void:
	_banner_label.text = text
	_banner.reset_size()
	_banner.size = _banner.get_combined_minimum_size()
	_banner.position = Vector2(240 - _banner.size.x / 2.0, y)
	_banner.pivot_offset = _banner.size / 2.0
	_banner.scale = Vector2(0.8, 0.8)
	var tw := _banner.create_tween()
	tw.set_parallel()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.15)
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(2.0)
	tw.chain().tween_property(_banner, "modulate:a", 0.0, 0.3)


func _on_glide_ended() -> void:
	for pad in _pads:
		if is_instance_valid(pad) and pad.contains(player.position):
			Game.crumbs += LANDING_BONUS
			Audio.play("newbest")
			Fx.burst(world, player.position + Vector2(0, -10), Palette.BUTTER, 24, 110.0, 180.0, 160.0, 2.5)
			_show_banner("nice landing! +%d crumbs" % LANDING_BONUS, 205.0)
			return


func _set_paused(on: bool) -> void:
	get_tree().paused = on
	_pause_menu.visible = on
	Audio.duck(on)
	Audio.play("pause", 0.0, 1.0 if on else 1.3)
	if on:
		_pause_buttons[0].grab_focus()


func _on_player_died(reason: String) -> void:
	_alive = false
	Input.action_release("jump")
	if _pause_button:
		_pause_button.hide()
	Audio.play(DEATH_SOUNDS.get(reason, "bonk"))
	Audio.duck(true)
	var new_best := Game.submit_score()
	var titles := {"bonk": "bonk!", "fall": "whoooops", "ouch": "ouch! pointy."}
	_panel(_over, Rect2(90, 34, 300, 202))
	ScreenArt.label(_over, titles.get(reason, "oh no"), 30, 34, Palette.SALMON)
	ScreenArt.label(_over, "(he was just a little guy)", 12, 74, Palette.INK)
	ScreenArt.label(_over, "%d cm  +  %d crumbs" % [Game.distance_cm, Game.crumbs], 14, 92, Palette.INK)
	ScreenArt.label(_over, "score %d" % Game.score(), 22, 110, Palette.INK)
	ScreenArt.label(_over, "new best!" if new_best else "best %d" % Game.best, 14, 140,
			Palette.TEAL if new_best else Palette.INK)
	ScreenArt.label(_over, "crumb jar: %d" % Game.bank, 13, 160, Palette.PLUM)
	var buttons := ScreenArt.button_row(_over, 190, [["run again", Game.start_game], ["shop", Game.go_to_shop],
			["menu", Game.go_to_title]])
	for b in buttons:
		b.disabled = true
	_over.modulate.a = 0.0
	_over.visible = true
	await get_tree().create_timer(0.6).timeout
	Audio.play("newbest" if new_best else "gameover")
	_over.create_tween().tween_property(_over, "modulate:a", 1.0, 0.25)
	# short delay so a held jump doesn't instantly restart
	await get_tree().create_timer(0.4).timeout
	for b in buttons:
		b.disabled = false
	buttons[0].grab_focus()
