class_name LandingPad
extends StaticBody2D
## A runway on the far side of a cliff drop, with a LANDING ZONE sign stuck in it on a toothpick.
## Touching down here from a glide earns bonus crumbs. Origin is the top-left corner of the pad.

const PAD := preload("res://sprites/landing_pad.png")
const SIGN := preload("res://sprites/landing_sign.png")
const SIZE := Vector2(240, 12)
const SIGN_HEIGHT := 72.0


func _ready() -> void:
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	col.shape = rect
	col.position = SIZE / 2.0
	add_child(col)


func contains(point: Vector2) -> bool:
	return point.x >= position.x - 4.0 and point.x <= position.x + SIZE.x + 4.0 \
			and absf(point.y - position.y) < 3.0


func _draw() -> void:
	# sign first so the pad's top edge covers the toothpick where it's stuck in
	var w: float = SIGN_HEIGHT * SIGN.get_width() / SIGN.get_height()
	draw_texture_rect(SIGN, Rect2(SIZE.x - w - 6.0, -SIGN_HEIGHT + 8.0, w, SIGN_HEIGHT), false)
	draw_texture_rect(PAD, Rect2(Vector2.ZERO, SIZE), false)
