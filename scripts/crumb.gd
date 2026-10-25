class_name Crumb
extends Area2D
## A collectible crumb. Tiny snack for a tiny guy.

const SHAPE := [Vector2(-3, -2), Vector2(0, -4), Vector2(3, -3), Vector2(4, 0),
		Vector2(2, 3), Vector2(-2, 3), Vector2(-4, 1)]

var _t := 0.0
var _taken := false


func _ready() -> void:
	_t = randf() * TAU
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	col.shape = circle
	add_child(col)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta * 3.0
	queue_redraw()


func _draw() -> void:
	var off := Vector2(0, sin(_t) * 2.0)
	var pts := PackedVector2Array()
	for p in SHAPE:
		pts.append(p + off)
	draw_colored_polygon(pts, Palette.PEACH)
	pts.append(pts[0])
	draw_polyline(pts, Palette.INK, 1.0)
	draw_circle(off + Vector2(-1, -1), 1.0, Palette.BUTTER)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Player:
		return
	_taken = true
	Game.crumbs += 1
	Audio.play("crumb", 0.04)
	Fx.burst(get_parent(), global_position, Palette.BUTTER, 8, 60.0, 180.0, 100.0)
	set_deferred("monitoring", false)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "scale", Vector2(2.0, 2.0), 0.2)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(queue_free)
