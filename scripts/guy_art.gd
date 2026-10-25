class_name GuyArt
## Draws a little guy (optionally wearing a hat from the crumb shop). Origin is at his feet.


static func draw_guy(ci: CanvasItem, origin: Vector2, squash: Vector2, body: Color, belly: Color,
		sprout: Color, look := 0.0, blink := false, leg_phase := 0.0, hat := "none") -> void:
	ci.draw_set_transform(origin, 0.0, squash)
	var ink := Palette.INK
	# legs
	var step := sin(leg_phase) * 1.5
	ci.draw_rect(Rect2(-4.0 + step, -3.0, 3.0, 3.0), ink)
	ci.draw_rect(Rect2(1.0 - step, -3.0, 3.0, 3.0), ink)
	# sprout
	ci.draw_line(Vector2(0, -14), Vector2(0.5, -17.5), ink, 1.0)
	ci.draw_circle(Vector2(2.3, -18.2), 1.9, ink)
	ci.draw_circle(Vector2(2.3, -18.2), 1.2, sprout)
	ci.draw_circle(Vector2(-1.4, -17.4), 1.6, ink)
	ci.draw_circle(Vector2(-1.4, -17.4), 0.9, sprout)
	# body
	ci.draw_circle(Vector2(0, -8), 6.6, ink)
	ci.draw_circle(Vector2(0, -8), 5.6, body)
	ci.draw_circle(Vector2(0, -5.6), 2.8, belly)
	# face
	var ex := look * 1.6
	ci.draw_circle(Vector2(-4.0 + ex, -7.2), 1.0, Palette.PINK)
	ci.draw_circle(Vector2(4.0 + ex, -7.2), 1.0, Palette.PINK)
	if blink:
		ci.draw_rect(Rect2(-3.2 + ex, -9.4, 2.0, 0.8), ink)
		ci.draw_rect(Rect2(1.2 + ex, -9.4, 2.0, 0.8), ink)
	else:
		ci.draw_rect(Rect2(-2.9 + ex, -10.8, 1.4, 2.6), ink)
		ci.draw_rect(Rect2(1.5 + ex, -10.8, 1.4, 2.6), ink)
	_draw_hat(ci, hat, ex)
	ci.draw_set_transform(Vector2.ZERO)


static func _poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color) -> void:
	ci.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, Palette.INK, 0.8)


static func _draw_hat(ci: CanvasItem, hat: String, ex: float) -> void:
	var ink := Palette.INK
	match hat:
		"bow":
			_poly(ci, PackedVector2Array([Vector2(3.6, -13.6), Vector2(0.6, -16.2), Vector2(0.6, -11.6)]), Palette.PINK)
			_poly(ci, PackedVector2Array([Vector2(3.6, -13.6), Vector2(6.6, -16.2), Vector2(6.6, -11.6)]), Palette.PINK)
			ci.draw_circle(Vector2(3.6, -13.8), 1.1, ink)
			ci.draw_circle(Vector2(3.6, -13.8), 0.6, Palette.PLUM)
		"party":
			_poly(ci, PackedVector2Array([Vector2(-4.4, -13.0), Vector2(4.4, -13.0), Vector2(0.4, -23.5)]), Palette.BUTTER)
			ci.draw_line(Vector2(-2.6, -15.8), Vector2(2.9, -15.8), Palette.PINK, 1.0)
			ci.draw_line(Vector2(-1.4, -19.0), Vector2(1.8, -19.0), Palette.PINK, 1.0)
			ci.draw_circle(Vector2(0.4, -23.6), 1.6, ink)
			ci.draw_circle(Vector2(0.4, -23.6), 1.0, Palette.PINK)
		"beanie":
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				pts.append(Vector2(cos(a) * 6.4, -11.0 + sin(a) * 6.4))
			_poly(ci, pts, Palette.TEAL)
			ci.draw_rect(Rect2(-6.7, -12.0, 13.4, 2.4), ink)
			ci.draw_rect(Rect2(-6.2, -11.6, 12.4, 1.6), Palette.MINT)
			ci.draw_circle(Vector2(0, -17.8), 1.9, ink)
			ci.draw_circle(Vector2(0, -17.8), 1.3, Palette.WHITE)
		"flower":
			var c := Vector2(0.5, -18.6)
			for i in 5:
				var a := TAU * i / 5.0 - PI / 2.0
				ci.draw_circle(c + Vector2(cos(a), sin(a)) * 1.9, 1.6, ink)
			for i in 5:
				var a := TAU * i / 5.0 - PI / 2.0
				ci.draw_circle(c + Vector2(cos(a), sin(a)) * 1.9, 1.1, Palette.PINK)
			ci.draw_circle(c, 1.2, ink)
			ci.draw_circle(c, 0.8, Palette.BUTTER)
		"shades":
			ci.draw_rect(Rect2(-4.3 + ex, -11.4, 3.8, 3.0), ink)
			ci.draw_rect(Rect2(0.7 + ex, -11.4, 3.8, 3.0), ink)
			ci.draw_line(Vector2(-0.6 + ex, -10.6), Vector2(0.8 + ex, -10.6), ink, 0.8)
			ci.draw_rect(Rect2(-3.6 + ex, -10.9, 1.0, 0.8), Palette.WHITE)
			ci.draw_rect(Rect2(1.4 + ex, -10.9, 1.0, 0.8), Palette.WHITE)
		"chef":
			for p in [Vector2(-2.9, -19.2), Vector2(2.9, -19.2), Vector2(0, -20.8)]:
				ci.draw_circle(p, 3.3, ink)
			for p in [Vector2(-2.9, -19.2), Vector2(2.9, -19.2), Vector2(0, -20.8)]:
				ci.draw_circle(p, 2.6, Palette.WHITE)
			ci.draw_rect(Rect2(-4.6, -17.6, 9.2, 4.6), ink)
			ci.draw_rect(Rect2(-3.9, -17.0, 7.8, 3.4), Palette.WHITE)
		"tophat":
			ci.draw_rect(Rect2(-6.2, -14.8, 12.4, 2.0), ink)
			ci.draw_rect(Rect2(-4.0, -23.0, 8.0, 8.6), ink)
			ci.draw_rect(Rect2(-4.0, -16.8, 8.0, 1.6), Palette.ROSE)
		"headphones":
			var arc := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				arc.append(Vector2(cos(a) * 7.2, -9.5 + sin(a) * 7.2))
			ci.draw_polyline(arc, ink, 2.2)
			ci.draw_polyline(arc, Palette.SLATE, 1.0)
			ci.draw_rect(Rect2(-8.6, -11.0, 3.2, 5.0), ink)
			ci.draw_rect(Rect2(-8.0, -10.4, 2.0, 3.8), Palette.PINK)
			ci.draw_rect(Rect2(5.4, -11.0, 3.2, 5.0), ink)
			ci.draw_rect(Rect2(6.0, -10.4, 2.0, 3.8), Palette.PINK)
		"crown":
			_poly(ci, PackedVector2Array([Vector2(-4.6, -13.4), Vector2(4.6, -13.4), Vector2(4.6, -19.2),
					Vector2(2.3, -16.4), Vector2(0, -20.4), Vector2(-2.3, -16.4), Vector2(-4.6, -19.2)]), Palette.BUTTER)
			ci.draw_circle(Vector2(0, -15.2), 0.9, Palette.PINK)


static func draw_heart(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var r := size * 0.5
	ci.draw_circle(center + Vector2(-r * 0.9, -r * 0.3), r, color)
	ci.draw_circle(center + Vector2(r * 0.9, -r * 0.3), r, color)
	ci.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-r * 1.85, 0.0),
		center + Vector2(r * 1.85, 0.0),
		center + Vector2(0.0, r * 2.0),
	]), color)
