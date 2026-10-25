class_name Player
extends CharacterBody2D
## The little guy. Runs on his own; you only jump. Origin is at his feet.
##
## Jumping: he rises at a steady speed for as long as jump is held (up to MAX_RISE_TIME),
## then gravity takes over and he arcs back down. Tap for a hop, hold for a big jump.

signal died(reason: String)
signal glide_started
signal glide_ended

const JUMP_VELOCITY := -210.0 # rise speed while jump is held
const MAX_RISE_TIME := 0.2 # how long holding keeps him rising (max jump ~68 px, a tap ~27 px)
const BOUNCE_VELOCITY := -440.0
const GRAVITY_UP := 850.0
const GRAVITY_DOWN := 1300.0
const APEX_GRAVITY_SCALE := 0.55 # a little hang time at the top of the arc
const APEX_SPEED := 45.0
const MAX_FALL := 400.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const STEP_UP := 9.0 # walks straight over anything this low (pencils, plates, phones)
const TRAIL_EVERY := 0.035
const TRAIL_LEN := 9
# dorito hang glider: hold jump to glide flatter, let go to sink faster
const GLIDE_FALL := 120.0
const GLIDE_FALL_HOLD := 24.0
const GLIDE_SPEED := 1.15
const GLIDE_MIN_DROP := 40.0 # only glide over ground at least this far below where he last stood
const DORITO := preload("res://sprites/dorito.png")

var run_speed := 120.0
var kill_y := 100000.0
## Picked up from a chip bag; used up when he lands from a glide.
var has_glider := false

var _coyote := 0.0
var _buffer := 0.0
var _jump_time := -1.0 # time spent rising in the current jump, -1 when not rising
var _was_on_floor := true
var _dead := false
var _squash := Vector2.ONE
var _leg_phase := 0.0
var _blink := false
var _blink_timer := 2.0
var _ground_gap := 0.0 # height above the surface below, for the shadow
var _trail: Array[Vector2] = []
var _trail_timer := 0.0
var _gliding := false
var _last_floor_y := 0.0
var _body := Palette.SALMON
var _belly := Palette.PEACH
var _hat := "none"


func _ready() -> void:
	var colors: Array = Game.body_colors()
	_body = colors[0]
	_belly = colors[1]
	_hat = Game.hat


func _physics_process(delta: float) -> void:
	if _dead:
		return
	# glide once he's actually off a drop (the surface below is well under where he last stood,
	# or there's nothing below at all), not when hopping around on the ledge
	if is_on_floor():
		_last_floor_y = global_position.y
	var over_drop := _ground_gap < 0.0 or global_position.y + _ground_gap > _last_floor_y + GLIDE_MIN_DROP
	if has_glider and not is_on_floor() and velocity.y >= 0.0 and _jump_time < 0.0 and (_gliding or over_drop):
		if not _gliding:
			_gliding = true
			Audio.play("whoosh")
			glide_started.emit()
		var target := GLIDE_FALL_HOLD if Input.is_action_pressed("jump") else GLIDE_FALL
		velocity.y = move_toward(velocity.y, target, 700.0 * delta)
		velocity.x = run_speed * GLIDE_SPEED
	else:
		var g := GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN
		if absf(velocity.y) < APEX_SPEED and not is_on_floor():
			g *= APEX_GRAVITY_SCALE
		velocity.y = minf(velocity.y + g * delta, MAX_FALL)
		velocity.x = run_speed

	_coyote = COYOTE_TIME if is_on_floor() else _coyote - delta
	_buffer = JUMP_BUFFER if Input.is_action_just_pressed("jump") else _buffer - delta
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
		_jump_time = 0.0
		_squash = Vector2(0.7, 1.35)
		Audio.play("jump", 0.05)
		Fx.burst(get_parent(), global_position, Palette.WHITE, 5, 30.0, 70.0, 0.0)
	if _jump_time >= 0.0:
		# keep rising while held; on release (or at the limit) gravity takes over for the arc
		_jump_time += delta
		if Input.is_action_pressed("jump") and _jump_time < MAX_RISE_TIME and not is_on_ceiling():
			velocity.y = JUMP_VELOCITY
		else:
			_jump_time = -1.0

	var fall_speed := velocity.y
	move_and_slide()

	if _check_bounce():
		return

	if _gliding and is_on_floor():
		# touchdown: snack time
		_gliding = false
		has_glider = false
		Audio.play("crunch")
		Fx.burst(get_parent(), global_position + Vector2(0, -4), Palette.PEACH, 14, 70.0, 160.0, 250.0, 2.5)
		Fx.burst(get_parent(), global_position + Vector2(0, -4), Palette.SALMON, 8, 60.0, 160.0, 250.0, 2.0)
		glide_ended.emit()
	if is_on_floor() and not _was_on_floor:
		var k := clampf(fall_speed / 700.0, 0.1, 0.4)
		_squash = Vector2(1.0 + k, 1.0 - k)
		if fall_speed > 200.0:
			Fx.burst(get_parent(), global_position, Palette.WHITE, 6, 35.0, 80.0, 0.0)
	_was_on_floor = is_on_floor()

	if is_on_wall() and not _try_step_up():
		# below floor level means he fell into a gap and hit the far side
		die("fall" if global_position.y > kill_y - 80.0 else "bonk")
	elif global_position.y > kill_y:
		die("fall")
	_update_ground_gap()


## Landing on something bouncy (eraser, marshmallow, pillow) launches him.
func _check_bounce() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var obj := c.get_collider()
		if c.get_normal().y < -0.7 and obj is GiantObject and obj.bouncy:
			velocity.y = BOUNCE_VELOCITY
			_jump_time = -1.0
			_squash = Vector2(0.6, 1.5)
			obj.squish()
			Audio.play("boing", 0.05)
			Fx.burst(get_parent(), global_position, Palette.WHITE, 8, 50.0, 90.0, 0.0)
			_was_on_floor = false
			return true
	return false


## If he only just clipped the top corner of a ledge, pop him up onto it.
func _try_step_up() -> bool:
	var up := Vector2(0, -STEP_UP)
	if test_move(global_transform, up):
		return false
	if test_move(global_transform.translated(up), Vector2(2, 0)):
		return false
	global_position += up
	return true


func _update_ground_gap() -> void:
	if is_on_floor():
		_ground_gap = 0.0
		return
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 300))
	q.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	_ground_gap = hit.position.y - global_position.y if hit else -1.0


func _process(delta: float) -> void:
	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-12.0 * delta))
	if not _dead and is_on_floor():
		_leg_phase += delta * run_speed * 0.17
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink = not _blink
		_blink_timer = 0.12 if _blink else randf_range(1.5, 4.0)
	# arc trail while airborne
	_trail_timer -= delta
	if not _dead and not is_on_floor() and _trail_timer <= 0.0:
		_trail_timer = TRAIL_EVERY
		_trail.push_front(global_position + Vector2(0, -8))
		if _trail.size() > TRAIL_LEN:
			_trail.pop_back()
	elif is_on_floor() and not _trail.is_empty() and _trail_timer <= 0.0:
		_trail_timer = TRAIL_EVERY
		_trail.pop_back()
	queue_redraw()


func _draw() -> void:
	if _dead:
		return
	for i in _trail.size():
		var a := 0.35 * (1.0 - float(i) / TRAIL_LEN)
		draw_circle(_trail[i] - global_position, 2.2 - i * 0.15, Color(Palette.WHITE, a))
	if _ground_gap > 1.0:
		var w := lerpf(6.5, 2.5, clampf(_ground_gap / 110.0, 0.0, 1.0))
		draw_set_transform(Vector2(0, _ground_gap), 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, w, Color(Palette.INK, 0.4))
		draw_set_transform(Vector2.ZERO)
	if has_glider and not _gliding:
		# carrying the dorito on his back until he needs it
		draw_set_transform(Vector2(-6, -9), -0.5, Vector2.ONE)
		draw_texture_rect(DORITO, Rect2(-9, -4.5, 18, 9), false)
		draw_set_transform(Vector2.ZERO)
	if _gliding:
		# riding the dorito: feet on the middle of its slope, nose dipping as he sinks
		var tilt := clampf(velocity.y / 260.0, -0.05, 0.25)
		draw_set_transform(Vector2.ZERO, tilt, Vector2.ONE)
		draw_texture_rect(DORITO, Rect2(-17, -8.6, 34, 17.3), false)
		draw_set_transform(Vector2.ZERO)
	GuyArt.draw_guy(self, Vector2.ZERO, _squash, _body, _belly, Palette.MINT, 0.6, _blink, _leg_phase, _hat)


func die(reason := "ouch") -> void:
	if _dead:
		return
	_dead = true
	_gliding = false
	has_glider = false
	velocity = Vector2.ZERO
	_trail.clear()
	Fx.burst(get_parent(), global_position + Vector2(0, -8), _body, 16, 90.0, 180.0, 300.0)
	queue_redraw()
	died.emit(reason)
