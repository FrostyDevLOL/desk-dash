class_name Thumbtack
extends Area2D
## Something pointy. Origin sits on the surface. Each zone has its own style.

enum Style { TACK, FORK, PIN, CACTUS }

## Width each style takes up, used when laying out obstacles.
const WIDTHS := {Style.TACK: 12.0, Style.FORK: 16.0, Style.PIN: 9.0, Style.CACTUS: 18.0}

@export var style := Style.TACK
@export var color := Color("dc94d4")


func _ready() -> void:
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	match style:
		Style.FORK:
			rect.size = Vector2(12, 12)
		Style.PIN:
			rect.size = Vector2(6, 13)
		Style.CACTUS:
			rect.size = Vector2(14, 30)
		_:
			rect.size = Vector2(8, 7)
	col.shape = rect
	col.position = Vector2(0, -rect.size.y / 2.0)
	add_child(col)
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var ink := Palette.INK
	match style:
		Style.TACK:
			draw_line(Vector2(0, -3), Vector2(0, -11), ink, 2.0)
			draw_line(Vector2(0, -3), Vector2(0, -10.5), Palette.MIST, 1.0)
			draw_rect(Rect2(-5, -4, 10, 4), ink)
			draw_rect(Rect2(-4, -3, 8, 2), color)
			draw_rect(Rect2(-2, -6, 4, 3), ink)
			draw_rect(Rect2(-1, -5, 2, 2), color)
		Style.FORK:
			# an upturned fork: four silver tines
			draw_rect(Rect2(-7, -4, 14, 4), ink)
			draw_rect(Rect2(-6, -3, 12, 2), Palette.MIST)
			for i in 4:
				var x := -5.5 + i * 3.6
				draw_line(Vector2(x, -3), Vector2(x, -13), ink, 2.0)
				draw_line(Vector2(x, -3), Vector2(x, -12.5), Palette.WHITE, 1.0)
		Style.PIN:
			# a sewing pin sticking up out of the blanket
			draw_line(Vector2(0, 0), Vector2(0, -13), ink, 2.0)
			draw_line(Vector2(0, -1), Vector2(0, -12.5), Palette.MIST, 1.0)
			draw_circle(Vector2(0, -2), 3.0, ink)
			draw_circle(Vector2(0, -2), 2.2, color)
		Style.CACTUS:
			draw_rect(Rect2(-8, -8, 16, 8), ink)
			draw_rect(Rect2(-7, -7, 14, 7), Palette.ROSE)
			draw_rect(Rect2(-8, -9, 16, 2), ink)
			var body := StyleBoxFlat.new()
			body.bg_color = Palette.SAGE
			body.border_color = ink
			body.set_border_width_all(1)
			body.set_corner_radius_all(4)
			draw_style_box(body, Rect2(-4, -30, 8, 22))
			draw_style_box(body, Rect2(-9, -24, 5, 9))
			draw_style_box(body, Rect2(4, -27, 5, 9))
			for p in [Vector2(-1, -26), Vector2(1, -20), Vector2(-1, -14), Vector2(-7, -21), Vector2(6, -24)]:
				draw_rect(Rect2(p, Vector2(1, 1)), Palette.WHITE)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.die()
