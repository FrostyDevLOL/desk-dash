class_name Doorway
extends Node2D
## A little doorway the guy runs through when the run moves into a new zone: a wooden frame,
## the door swung open, a welcome mat, and a sign naming the zone ahead.
## Origin is the middle of the doorway, on the floor. Pure decoration (no collision).

const FONT := preload("res://fonts/GochiHand-Regular.ttf")
const OPENING := Vector2(44, 62)
const POST := 6.0

var zone_name := ""
var door_color := Color("4c64a8")


func _draw() -> void:
	var ink := Palette.INK
	var half := OPENING.x / 2.0
	var top := -OPENING.y

	# wooden trim running up the wall where the two rooms meet
	var trim_bottom := top - POST - 4.0
	draw_rect(Rect2(-6, trim_bottom - 400.0, 12, 400.0), ink)
	draw_rect(Rect2(-5, trim_bottom - 400.0, 10, 400.0), Palette.PEACH)
	draw_line(Vector2(-2, trim_bottom - 400.0), Vector2(-2, trim_bottom), Palette.ROSE, 1.0)

	# the opening itself, a little darker so it reads as a way through
	draw_rect(Rect2(-half, top, OPENING.x, OPENING.y), Color(Palette.INK, 0.18))

	# the door, swung open toward us on its hinges (left side)
	var hinge_x := -half - POST
	var door := PackedVector2Array([
		Vector2(hinge_x, top), Vector2(hinge_x - 22, top + 6),
		Vector2(hinge_x - 22, -2), Vector2(hinge_x, 0)])
	draw_colored_polygon(door, door_color)
	var outline := door.duplicate()
	outline.append(door[0])
	draw_polyline(outline, ink, 1.0)
	draw_line(Vector2(hinge_x - 5, top + 10), Vector2(hinge_x - 17, top + 13), Color(ink, 0.35), 1.0)
	draw_line(Vector2(hinge_x - 5, -14), Vector2(hinge_x - 17, -12), Color(ink, 0.35), 1.0)
	draw_circle(Vector2(hinge_x - 18, top + OPENING.y * 0.55), 1.6, ink)
	draw_circle(Vector2(hinge_x - 18, top + OPENING.y * 0.55), 1.0, Palette.BUTTER)

	# frame: two posts and a lintel
	for x in [-half - POST, half]:
		draw_rect(Rect2(x, top - POST, POST, OPENING.y + POST), ink)
		draw_rect(Rect2(x + 1, top - POST + 1, POST - 2, OPENING.y + POST - 1), Palette.PEACH)
	draw_rect(Rect2(-half - POST - 3, top - POST - 4, OPENING.x + POST * 2 + 6, 6), ink)
	draw_rect(Rect2(-half - POST - 2, top - POST - 3, OPENING.x + POST * 2 + 4, 4), Palette.ROSE)

	# welcome mat just past the doorway
	draw_rect(Rect2(-14, -2, 34, 3), ink)
	draw_rect(Rect2(-13, -1.5, 32, 2), Palette.SALMON)

	# sign hanging above: "the bookshelf ->"
	if zone_name != "":
		var text := zone_name + "  >"
		var size := 11
		var w := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 12.0
		var sign := Rect2(-w / 2.0, top - POST - 26, w, 16)
		draw_line(Vector2(sign.position.x + 6, sign.end.y), Vector2(-half + 4, top - POST - 4), ink, 1.0)
		draw_line(Vector2(sign.end.x - 6, sign.end.y), Vector2(half - 4, top - POST - 4), ink, 1.0)
		draw_rect(sign.grow(1.0), ink)
		draw_rect(sign, Palette.BUTTER)
		draw_string(FONT, Vector2(sign.position.x + 6, sign.end.y - 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				size, ink)
