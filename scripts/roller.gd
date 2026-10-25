class_name Roller
extends Area2D
## Something round rolling toward the little guy (marble, pea, button). Jump over it.
## It starts rolling once it's on screen and pops when it reaches stop_x.

enum Style { MARBLE, PEA, BUTTON }

const RADIUS := {Style.MARBLE: 6.0, Style.PEA: 5.0, Style.BUTTON: 6.5}

@export var style := Style.MARBLE
@export var roll_speed := 70.0
var stop_x := -INF

var _rolling := false
var _angle := 0.0
var _done := false


func _ready() -> void:
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS[style] - 1.0
	col.shape = circle
	add_child(col)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if not _rolling:
		var cam := get_viewport().get_camera_2d()
		if cam and position.x < cam.get_screen_center_position().x + 250.0:
			_rolling = true
		return
	position.x -= roll_speed * delta
	_angle -= roll_speed * delta / RADIUS[style]
	queue_redraw()
	if position.x <= stop_x:
		_done = true
		set_deferred("monitoring", false)
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
		tw.tween_property(self, "modulate:a", 0.0, 0.15)
		tw.chain().tween_callback(queue_free)


func _draw() -> void:
	var r: float = RADIUS[style]
	var ink := Palette.INK
	draw_circle(Vector2.ZERO, r, ink)
	match style:
		Style.MARBLE:
			draw_circle(Vector2.ZERO, r - 1.0, Palette.SKY)
			var swirl := Vector2(cos(_angle), sin(_angle)) * (r - 2.5)
			draw_line(-swirl, swirl, Palette.BLUE, 1.5)
			draw_circle(Vector2(-r * 0.35, -r * 0.35), 1.2, Palette.WHITE)
		Style.PEA:
			draw_circle(Vector2.ZERO, r - 1.0, Palette.MINT)
			var spot := Vector2(cos(_angle), sin(_angle)) * (r - 2.5)
			draw_circle(spot, 1.0, Palette.SAGE)
			draw_circle(Vector2(-r * 0.3, -r * 0.35), 0.9, Palette.WHITE)
		Style.BUTTON:
			draw_circle(Vector2.ZERO, r - 1.0, Palette.PINK)
			draw_arc(Vector2.ZERO, r - 2.2, 0, TAU, 16, Palette.PLUM, 1.0)
			for i in 4:
				var a := _angle + TAU * i / 4.0 + PI / 4.0
				draw_circle(Vector2(cos(a), sin(a)) * 1.6, 0.8, ink)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.die()
