extends Node
## Renders the game logo (630x500) to res://logo.png using the game's own art. Run this scene once.

const SIZE := Vector2i(630, 500)
const OUT := "res://logo.png"


class Drawer extends Node2D:
	var fn: Callable

	func _draw() -> void:
		fn.call(self)


func _ready() -> void:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var bg := Drawer.new()
	bg.fn = _draw_background
	vp.add_child(bg)

	# the desk scene, drawn with the real game objects at 3x
	var world := Node2D.new()
	world.scale = Vector2(3, 3)
	vp.add_child(world)
	_obj(world, GiantObject.Kind.DESK, Vector2(-5, 135), Vector2(220, 60), Palette.ROSE, Palette.PEACH)
	_obj(world, GiantObject.Kind.BOOK, Vector2(12, 112), Vector2(58, 23), Palette.BLUE, Palette.BUTTER)
	_obj(world, GiantObject.Kind.BOOK, Vector2(17, 93), Vector2(48, 19), Palette.PLUM, Palette.PEACH)
	_obj(world, GiantObject.Kind.BOOK, Vector2(14, 77), Vector2(52, 16), Palette.SAGE, Palette.WHITE)
	_obj(world, GiantObject.Kind.MUG, Vector2(160, 85), Vector2(36, 50), Palette.WHITE, Palette.PINK)
	var tack := Thumbtack.new()
	tack.color = Palette.PINK
	tack.position = Vector2(105, 135)
	world.add_child(tack)
	for p in [Vector2(80, 108), Vector2(92, 98), Vector2(128, 100), Vector2(140, 110)]:
		var c := Crumb.new()
		c.position = p
		world.add_child(c)

	var guy := Drawer.new()
	guy.fn = _draw_guy
	vp.add_child(guy)

	var ui := Control.new()
	ui.size = Vector2(SIZE)
	vp.add_child(ui)
	var title := _label(ui, "DESK DASH", 106, Palette.WHITE, 20, 22)
	title.pivot_offset = title.size / 2.0
	title.rotation_degrees = -4.0
	var title_settings := title.label_settings
	title_settings.shadow_color = Palette.INK
	title_settings.shadow_offset = Vector2(6, 7)
	title_settings.shadow_size = 18
	_label(ui, "a tiny guy. a very big desk.", 34, Palette.INK, 0, 172)

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var err := img.save_png(OUT)
	print("logo saved: ", ProjectSettings.globalize_path(OUT), " err=", err)


func _obj(parent: Node, kind: GiantObject.Kind, pos: Vector2, size: Vector2, fill: Color, accent: Color) -> void:
	var o := GiantObject.new()
	o.kind = kind
	o.size = size
	o.fill = fill
	o.accent = accent
	o.position = pos
	parent.add_child(o)


func _label(parent: Control, text: String, size: int, color: Color, outline: int, y: float) -> Label:
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = outline
	settings.outline_color = Palette.INK
	var l := Label.new()
	l.text = text
	l.label_settings = settings
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(SIZE.x, size * 1.4)
	l.position = Vector2(0, y)
	parent.add_child(l)
	return l


func _draw_background(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, SIZE), Palette.SKY)
	var x := 20.0
	while x < SIZE.x:
		ci.draw_rect(Rect2(x, 0, 12, SIZE.y), Palette.PERI)
		x += 72.0


func _draw_guy(ci: CanvasItem) -> void:
	var feet := Vector2(318, 352)
	GuyArt.draw_guy(ci, feet, Vector2(4.6, 5.4), Palette.SALMON, Palette.PEACH, Palette.MINT, 0.8, false, PI / 2.0)
