class_name Fx
## One-shot particle bursts in palette colors.


static func burst(parent: Node, pos: Vector2, color: Color, amount := 8, speed := 60.0,
		spread := 180.0, gravity := 220.0, size := 2.0) -> void:
	if parent == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.5
	p.direction = Vector2.UP
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = size
	p.scale_amount_max = size * 1.5
	p.color = color
	p.z_index = 5
	p.position = pos
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.emitting = true
