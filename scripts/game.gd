extends Node
## Run state, saved progress (best score, crumb bank, unlocks), scene flow and fades.

const TITLE_SCENE := "res://scenes/title.tscn"
const RUNNER_SCENE := "res://scenes/runner.tscn"
const SHOP_SCENE := "res://scenes/shop.tscn"
const SAVE_PATH := "user://save.cfg"
const CRUMB_POINTS := 5

var crumbs := 0
var distance_cm := 0
var best := 0
## True on phones/tablets: shows tap hints and the on-screen pause button.
var touch := false

# saved progress
var bank := 0
var owned: Array = ["hat:none", "color:classic"]
var hat := "none"
var color := "classic"

## Debug: start runs in a later zone (0 = desk). Not saved.
var debug_start_zone := 0

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _switching := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RenderingServer.set_default_clear_color(Palette.SKY)
	touch = DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") \
			or OS.has_feature("web_ios")
	_load()
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Palette.INK
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_fade_layer.add_child(_fade_rect)


func _input(event: InputEvent) -> void:
	# some browsers only reveal a touchscreen once it's used
	if event is InputEventScreenTouch and not touch:
		touch = true


func start_game() -> void:
	change_scene(RUNNER_SCENE)


func go_to_title() -> void:
	change_scene(TITLE_SCENE)


func go_to_shop() -> void:
	change_scene(SHOP_SCENE)


func reset_run() -> void:
	crumbs = 0
	distance_cm = 0


func score() -> int:
	return distance_cm + crumbs * CRUMB_POINTS


## Records the finished run: banks its crumbs and checks the best score.
## Returns true if it's a new best.
func submit_score() -> bool:
	bank += crumbs
	var new_best := score() > best
	if new_best:
		best = score()
	save()
	return new_best


# --- cosmetics ------------------------------------------------------------

func body_colors() -> Array:
	var c: Dictionary = Cosmetics.find(Cosmetics.COLORS, color)
	return [c.body, c.belly]


func is_owned(kind: String, id: String) -> bool:
	return "%s:%s" % [kind, id] in owned


## Buys (if needed and affordable) and equips an item. Returns false if too expensive.
func buy_or_equip(kind: String, item: Dictionary) -> bool:
	if not is_owned(kind, item.id):
		if bank < item.cost:
			return false
		bank -= item.cost
		owned.append("%s:%s" % [kind, item.id])
	if kind == "hat":
		hat = item.id
	else:
		color = item.id
	save()
	return true


# --- saving ---------------------------------------------------------------

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "best", best)
	cfg.set_value("shop", "bank", bank)
	cfg.set_value("shop", "owned", owned)
	cfg.set_value("shop", "hat", hat)
	cfg.set_value("shop", "color", color)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	best = cfg.get_value("scores", "best", 0)
	bank = cfg.get_value("shop", "bank", 0)
	owned = cfg.get_value("shop", "owned", owned)
	hat = cfg.get_value("shop", "hat", "none")
	color = cfg.get_value("shop", "color", "classic")


func change_scene(path: String) -> void:
	if _switching:
		return
	_switching = true
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", 1.0, 0.3)
	await tw.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	tw = create_tween()
	tw.tween_property(_fade_rect, "modulate:a", 0.0, 0.3)
	await tw.finished
	_switching = false
