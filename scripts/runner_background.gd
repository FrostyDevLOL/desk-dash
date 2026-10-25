extends Node2D
## Endless wall behind the run, scrolling at half speed. Each zone has its own wall; where two
## zones meet, each is drawn on its own layer clipped to its part of the screen.

const PARALLAX := 0.5
const DECOR_SPACING := 420.0
const LAYERS := 3

@export var camera: Camera2D

var _layers: Array[ZoneLayer] = []
var _clips: Array[Control] = []


class ZoneLayer extends Node2D:
	var zone := 0
	var scroll := 0.0

	func _box(rect: Rect2, color: Color) -> void:
		draw_rect(rect, Palette.INK)
		draw_rect(rect.grow(-2.0), color)

	## Cheap repeatable "random" for decor, so it doesn't change frame to frame.
	func _hash(i: int, salt := 0) -> float:
		return fposmod(sin(i * 12.9898 + salt * 78.233) * 43758.5453, 1.0)

	func _draw() -> void:
		match zone:
			0: _draw_desk_wall()
			1: _draw_shelf_wall()
			2: _draw_kitchen_wall()
			3: _draw_bed_wall()

	func _decor_slots() -> Array:
		var first := floori(scroll / DECOR_SPACING)
		var out := []
		for i in range(first, first + 3):
			out.append([i, i * DECOR_SPACING - scroll + 60.0])
		return out

	func _draw_desk_wall() -> void:
		draw_rect(Rect2(0, 0, 480, 270), Palette.SKY)
		var x := -fposmod(scroll, 48.0)
		while x < 480.0:
			draw_rect(Rect2(x, 0, 6, 270), Palette.PERI)
			x += 48.0
		for slot in _decor_slots():
			var sx: float = slot[1]
			match posmod(slot[0], 3):
				0:
					var win := Rect2(sx, 40, 140, 110)
					_box(win.grow(6.0), Palette.WHITE)
					draw_rect(win, Palette.BUTTER)
					draw_circle(win.position + Vector2(100, 35), 18.0, Palette.WHITE)
					for c in [Vector2(30, 80), Vector2(48, 72), Vector2(66, 82)]:
						draw_circle(win.position + c, 12.0, Palette.WHITE)
					draw_rect(Rect2(win.position.x + 67, win.position.y, 6, win.size.y), Palette.WHITE)
					draw_rect(Rect2(win.position.x, win.position.y + 52, win.size.x, 6), Palette.WHITE)
				1:
					var pic := Rect2(sx + 20, 60, 80, 64)
					_box(pic.grow(5.0), Palette.ROSE)
					draw_rect(pic, Palette.MINT)
					draw_rect(Rect2(pic.position.x, pic.end.y - 16, pic.size.x, 16), Palette.SAGE)
					GuyArt.draw_guy(self, pic.position + Vector2(40, 52), Vector2(1.6, 1.6), Palette.SALMON,
							Palette.PEACH, Palette.MINT)
				2:
					var poster := Rect2(sx + 30, 30, 70, 90)
					_box(poster, Palette.LILAC)
					GuyArt.draw_heart(self, poster.get_center() + Vector2(0, -8), 18.0, Palette.PINK)

	func _draw_shelf_wall() -> void:
		draw_rect(Rect2(0, 0, 480, 270), Palette.PLUM)
		var x := -fposmod(scroll, 64.0)
		while x < 480.0:
			draw_line(Vector2(x, 0), Vector2(x, 270), Palette.ROSE, 1.0)
			x += 64.0
		# the shelf above, with a row of books on it
		var spine_x := -fposmod(scroll, 22.0) - 22.0
		var idx := floori(scroll / 22.0) - 1
		while spine_x < 480.0:
			var h := 34.0 + _hash(idx) * 22.0
			var colors := [Palette.BLUE, Palette.SAGE, Palette.BUTTER, Palette.SALMON, Palette.TEAL, Palette.LILAC]
			var c: Color = colors[int(_hash(idx, 1) * colors.size())]
			if _hash(idx, 2) > 0.12:
				draw_rect(Rect2(spine_x, 92 - h, 20, h), Palette.INK)
				draw_rect(Rect2(spine_x + 1, 93 - h, 18, h - 2), c)
				draw_rect(Rect2(spine_x + 1, 98 - h, 18, 2), Palette.PEACH)
			spine_x += 22.0
			idx += 1
		draw_rect(Rect2(0, 92, 480, 12), Palette.INK)
		draw_rect(Rect2(0, 93, 480, 9), Palette.ROSE)
		draw_line(Vector2(0, 95), Vector2(480, 95), Palette.PEACH, 1.0)

	func _draw_kitchen_wall() -> void:
		draw_rect(Rect2(0, 0, 480, 270), Palette.WHITE)
		var x := -fposmod(scroll, 24.0)
		while x < 480.0:
			draw_line(Vector2(x, 0), Vector2(x, 270), Palette.MIST, 1.0)
			x += 24.0
		for y in range(0, 270, 24):
			draw_line(Vector2(0, y), Vector2(480, y), Palette.MIST, 1.0)
		draw_rect(Rect2(0, 132, 480, 8), Palette.TEAL)
		for slot in _decor_slots():
			var sx: float = slot[1]
			if posmod(slot[0], 2) == 0:
				var win := Rect2(sx, 26, 120, 86)
				_box(win.grow(6.0), Palette.SAGE)
				draw_rect(win, Palette.SKY)
				draw_circle(win.position + Vector2(30, 28), 12.0, Palette.WHITE)
				draw_circle(win.position + Vector2(44, 32), 10.0, Palette.WHITE)
				draw_rect(Rect2(win.position.x + 57, win.position.y, 6, win.size.y), Palette.SAGE)
			else:
				var c := Vector2(sx + 70, 70)
				draw_circle(c, 30.0, Palette.INK)
				draw_circle(c, 27.0, Palette.BUTTER)
				for h in 12:
					var a := TAU * h / 12.0
					draw_rect(Rect2(c + Vector2(cos(a), sin(a)) * 22.0 - Vector2(1, 1), Vector2(2, 2)), Palette.INK)
				draw_line(c, c + Vector2(0, -17), Palette.INK, 2.0)
				draw_line(c, c + Vector2(12, 4), Palette.INK, 2.0)

	func _draw_bed_wall() -> void:
		draw_rect(Rect2(0, 0, 480, 270), Palette.VIOLET)
		var base := floori(scroll / 30.0) - 1
		for i in range(base, base + 19):
			var sx := i * 30.0 - scroll
			if _hash(i) > 0.45:
				var sy := 10.0 + _hash(i, 3) * 150.0
				draw_rect(Rect2(sx, sy, 2, 2), Palette.BUTTER)
		# fairy lights strung along the top
		var pts := PackedVector2Array()
		var lx := -fposmod(scroll, 40.0) - 40.0
		var li := floori(scroll / 40.0) - 1
		while lx < 520.0:
			pts.append(Vector2(lx, 24.0 + (8.0 if li % 2 == 0 else 0.0)))
			lx += 40.0
			li += 1
		draw_polyline(pts, Palette.INK, 1.0)
		var bulbs := [Palette.PINK, Palette.BUTTER, Palette.MINT, Palette.SKY]
		for j in pts.size():
			draw_circle(pts[j] + Vector2(0, 3), 2.5, Palette.INK)
			draw_circle(pts[j] + Vector2(0, 3), 1.8, bulbs[posmod(li - pts.size() + j, bulbs.size())])
		for slot in _decor_slots():
			if posmod(slot[0], 2) == 0:
				var win := Rect2(slot[1], 46, 110, 90)
				_box(win.grow(6.0), Palette.PERI)
				draw_rect(win, Palette.NAVY)
				draw_circle(win.position + Vector2(72, 32), 14.0, Palette.BUTTER)
				draw_circle(win.position + Vector2(79, 27), 12.0, Palette.NAVY)
				for p in [Vector2(20, 20), Vector2(40, 60), Vector2(90, 70), Vector2(25, 75)]:
					draw_rect(Rect2(win.position + p, Vector2(2, 2)), Palette.WHITE)


func _ready() -> void:
	# each zone's wall sits in a clipping box covering its part of the screen
	for i in LAYERS:
		var clip := Control.new()
		clip.clip_contents = true
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(clip)
		var l := ZoneLayer.new()
		clip.add_child(l)
		_clips.append(clip)
		_layers.append(l)


func _process(_delta: float) -> void:
	position = camera.get_screen_center_position() - Vector2(240, 135)
	var starts: Array = get_parent().zone_starts
	var scroll := position.x * PARALLAX
	var used := 0
	for i in starts.size():
		var x0: float = clampf(starts[i][0] - position.x, 0.0, 480.0)
		var x1: float = 480.0 if i + 1 >= starts.size() else clampf(starts[i + 1][0] - position.x, 0.0, 480.0)
		if x1 <= x0 or used >= LAYERS:
			continue
		var layer := _layers[used]
		var clip := _clips[used]
		layer.zone = starts[i][1]
		layer.scroll = scroll
		clip.visible = true
		clip.position = Vector2(x0, 0)
		clip.size = Vector2(x1 - x0, 270)
		layer.position = Vector2(-x0, 0) # keep drawing in screen space
		layer.queue_redraw()
		used += 1
	for j in range(used, LAYERS):
		_clips[j].visible = false
