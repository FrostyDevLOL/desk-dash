class_name ChipBag
extends Area2D
## A bag of Chipitos waiting at the top of a cliff. Run into it to grab a dorito hang glider.
## Origin sits on the surface.

signal picked

const TEXTURE := preload("res://sprites/chip_bag.png")
const HEIGHT := 58.0

var _t := 0.0
var _taken := false


func _ready() -> void:
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	# tall enough that he can't jump over it by accident
	rect.size = Vector2(30, 120)
	col.shape = rect
	col.position = Vector2(0, -60)
	add_child(col)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := HEIGHT * TEXTURE.get_width() / TEXTURE.get_height()
	var wobble := sin(_t * 3.0) * 0.04
	draw_set_transform(Vector2(0, 0), wobble, Vector2.ONE)
	draw_texture_rect(TEXTURE, Rect2(-w / 2.0, -HEIGHT, w, HEIGHT), false)
	draw_set_transform(Vector2.ZERO)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Player:
		return
	_taken = true
	body.has_glider = true
	Audio.play("crunch")
	Fx.burst(get_parent(), global_position + Vector2(0, -30), Palette.PEACH, 16, 90.0, 180.0, 200.0, 2.5)
	picked.emit()
	set_deferred("monitoring", false)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "scale", Vector2(1.4, 0.6), 0.12)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)
