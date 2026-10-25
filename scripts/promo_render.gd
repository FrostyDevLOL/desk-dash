extends Node
## Renders itch.io promo images (social, wide cover, favicon, transparent logo) into build/promo/.
## Run this scene once; it quits when done.

const OUT_DIR := "res://build/promo/"


class Drawer extends Node2D:
	var fn: Callable

	func _draw() -> void:
		fn.call(self)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await _render(Vector2i(1200, 630), _build_social, "social-1200x630.png")
	await _render(Vector2i(2100, 900), _build_wide, "wide-cover-2100x900.png")
	await _render(Vector2i(512, 512), _build_favicon, "favicon-512.png")
	await _render(Vector2i(1400, 420), _build_logo, "logo-transparent.png", true)
	await _render(Vector2i(1920, 1080), _build_embed, "embed-bg-1920x1080.png")
	get_tree().quit()


func _render(size: Vector2i, build: Callable, file: String, transparent := false) -> void:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = transparent
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	build.call(vp, Vector2(size))
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	if transparent:
		# trim to the artwork with a little breathing room
		var used := img.get_used_rect().grow(24).intersection(Rect2i(Vector2i.ZERO, size))
		img = img.get_region(used)
	var path := ProjectSettings.globalize_path(OUT_DIR + file)
	img.save_png(path)
	print("saved ", path, " ", img.get_size())
	vp.queue_free()


# --- compositions ---------------------------------------------------------

func _build_social(vp: SubViewport, size: Vector2) -> void:
	_background(vp, size, 12.0, 72.0)
	var w := _world(vp, 3.0)
	_obj(w, GiantObject.Kind.DESK, Vector2(-5, 172), Vector2(420, 60), Palette.ROSE, Palette.PEACH)
	_obj(w, GiantObject.Kind.BOOK, Vector2(14, 148), Vector2(62, 24), Palette.BLUE, Palette.BUTTER)
	_obj(w, GiantObject.Kind.BOOK, Vector2(19, 128), Vector2(52, 20), Palette.PLUM, Palette.PEACH)
	_obj(w, GiantObject.Kind.BOOK, Vector2(16, 111), Vector2(56, 17), Palette.SAGE, Palette.WHITE)
	_obj(w, GiantObject.Kind.MUG, Vector2(330, 117), Vector2(40, 55), Palette.WHITE, Palette.PINK)
	_tack(w, Vector2(200, 172), Palette.PINK)
	for p in [Vector2(150, 140), Vector2(165, 128), Vector2(235, 128), Vector2(250, 140)]:
		_crumb(w, p)
	_guy(vp, Vector2(600, 452), Vector2(5.0, 5.8))
	var ui := _ui(vp, size)
	_title(ui, "DESK DASH", 150, Rect2(0, 18, size.x, 200), HORIZONTAL_ALIGNMENT_CENTER, -3.0)
	_text(ui, "a tiny guy. a very big desk.", 40, Palette.INK, 0, Rect2(0, 205, size.x, 60))


func _build_wide(vp: SubViewport, size: Vector2) -> void:
	_background(vp, size, 16.0, 96.0)
	var w := _world(vp, 4.0)
	_obj(w, GiantObject.Kind.DESK, Vector2(-5, 185), Vector2(540, 60), Palette.ROSE, Palette.PEACH)
	_obj(w, GiantObject.Kind.BOOK, Vector2(300, 161), Vector2(60, 24), Palette.TEAL, Palette.MINT)
	_obj(w, GiantObject.Kind.BOOK, Vector2(305, 141), Vector2(50, 20), Palette.VIOLET, Palette.BUTTER)
	_obj(w, GiantObject.Kind.MUG, Vector2(455, 130), Vector2(42, 55), Palette.WHITE, Palette.PINK)
	_tack(w, Vector2(400, 185), Palette.PINK)
	_tack(w, Vector2(412, 185), Palette.TEAL)
	for p in [Vector2(376, 152), Vector2(387, 141), Vector2(426, 141), Vector2(437, 152)]:
		_crumb(w, p)
	_guy(vp, Vector2(1625, 640), Vector2(6.6, 7.6))
	var ui := _ui(vp, size)
	_title(ui, "DESK DASH", 220, Rect2(90, 150, 1100, 300), HORIZONTAL_ALIGNMENT_LEFT, -3.0)
	_text(ui, "a tiny guy. a very big desk.", 54, Palette.INK, 0, Rect2(110, 455, 1100, 80),
			HORIZONTAL_ALIGNMENT_LEFT)
	_text(ui, "play free in your browser", 42, Palette.WHITE, 12, Rect2(110, 540, 1100, 70),
			HORIZONTAL_ALIGNMENT_LEFT)


func _build_favicon(vp: SubViewport, size: Vector2) -> void:
	_background(vp, size, 12.0, 72.0)
	var desk := Drawer.new()
	desk.fn = func(ci: CanvasItem):
		ci.draw_rect(Rect2(0, 436, size.x, 76), Palette.INK)
		ci.draw_rect(Rect2(0, 452, size.x, 60), Palette.ROSE)
		ci.draw_rect(Rect2(0, 440, size.x, 10), Palette.PEACH)
	vp.add_child(desk)
	_guy(vp, Vector2(256, 444), Vector2(20, 20), 0.0, 0.0)


func _build_logo(vp: SubViewport, size: Vector2) -> void:
	_guy(vp, Vector2(190, 352), Vector2(12, 12), 0.6, 0.0)
	var ui := _ui(vp, size)
	_title(ui, "DESK DASH", 210, Rect2(300, 40, 1080, 340), HORIZONTAL_ALIGNMENT_LEFT, 0.0)


## Behind itch's "Run game" button: the desk scene, centre kept clear for the button.
func _build_embed(vp: SubViewport, size: Vector2) -> void:
	_background(vp, size, 16.0, 96.0)
	var w := _world(vp, 4.0)
	_obj(w, GiantObject.Kind.DESK, Vector2(-5, 210), Vector2(500, 70), Palette.ROSE, Palette.PEACH)
	_obj(w, GiantObject.Kind.BOOK, Vector2(16, 30), Vector2(40, 180), Palette.NAVY, Palette.BUTTER)
	_obj(w, GiantObject.Kind.BOOK, Vector2(60, 186), Vector2(70, 24), Palette.TEAL, Palette.MINT)
	_obj(w, GiantObject.Kind.BOOK, Vector2(66, 166), Vector2(58, 20), Palette.PLUM, Palette.PEACH)
	_obj(w, GiantObject.Kind.MUG, Vector2(380, 150), Vector2(48, 60), Palette.WHITE, Palette.PINK)
	_obj(w, GiantObject.Kind.PENCIL, Vector2(250, 200), Vector2(90, 10), Palette.BUTTER, Palette.PEACH)
	_tack(w, Vector2(215, 210), Palette.PINK)
	for p in [Vector2(150, 175), Vector2(165, 165), Vector2(180, 160), Vector2(275, 185), Vector2(295, 185)]:
		_crumb(w, p)
	# the little guy waits at the start line, left of the play button
	_guy(vp, Vector2(150 * 4.0 + 120, 210 * 4.0), Vector2(7, 7), 0.8, 0.0)


# --- building blocks ------------------------------------------------------

func _background(vp: SubViewport, size: Vector2, stripe: float, spacing: float) -> void:
	var bg := Drawer.new()
	bg.fn = func(ci: CanvasItem):
		ci.draw_rect(Rect2(Vector2.ZERO, size), Palette.SKY)
		var x := spacing * 0.3
		while x < size.x:
			ci.draw_rect(Rect2(x, 0, stripe, size.y), Palette.PERI)
			x += spacing
	vp.add_child(bg)


func _world(vp: SubViewport, scale: float) -> Node2D:
	var w := Node2D.new()
	w.scale = Vector2(scale, scale)
	vp.add_child(w)
	return w


func _ui(vp: SubViewport, size: Vector2) -> Control:
	var ui := Control.new()
	ui.size = size
	vp.add_child(ui)
	return ui


func _obj(parent: Node, kind: GiantObject.Kind, pos: Vector2, size: Vector2, fill: Color, accent: Color) -> void:
	var o := GiantObject.new()
	o.kind = kind
	o.size = size
	o.fill = fill
	o.accent = accent
	o.position = pos
	parent.add_child(o)


func _tack(parent: Node, pos: Vector2, color: Color) -> void:
	var t := Thumbtack.new()
	t.color = color
	t.position = pos
	parent.add_child(t)


func _crumb(parent: Node, pos: Vector2) -> void:
	var c := Crumb.new()
	c.position = pos
	parent.add_child(c)


## leg_phase 0 = standing (two legs), PI/2 = mid-stride (legs together, reads as a jump).
func _guy(vp: SubViewport, feet: Vector2, scale: Vector2, look := 0.8, leg_phase := PI / 2.0) -> void:
	var g := Drawer.new()
	g.fn = func(ci: CanvasItem):
		GuyArt.draw_guy(ci, feet, scale, Palette.SALMON, Palette.PEACH, Palette.MINT, look, false, leg_phase)
	vp.add_child(g)


func _text(parent: Control, text: String, size: int, color: Color, outline: int, rect: Rect2,
		align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = outline
	settings.outline_color = Palette.INK
	var l := Label.new()
	l.text = text
	l.label_settings = settings
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = rect.position
	l.size = rect.size
	parent.add_child(l)
	return l


func _title(parent: Control, text: String, size: int, rect: Rect2, align: HorizontalAlignment, tilt: float) -> void:
	var l := _text(parent, text, size, Palette.WHITE, int(size * 0.15), rect, align)
	l.label_settings.shadow_color = Palette.INK
	l.label_settings.shadow_offset = Vector2(size * 0.05, size * 0.06)
	l.label_settings.shadow_size = int(size * 0.15)
	l.pivot_offset = rect.size / 2.0
	l.rotation_degrees = tilt
