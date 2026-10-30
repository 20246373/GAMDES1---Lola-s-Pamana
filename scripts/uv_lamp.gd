extends PointLight2D
## The UV lamp. Hold the uv_lamp action, the right mouse button or Space, and
## the beam follows the cursor. Clicking and holding the interact action on
## something that can be scanned works the same way, which is easier on a
## touchpad. It drains 2% battery per second and goes dark at 0% (M1).
## Listens to resource_changed so the bulb dims with the battery (Table 22).

@onready var beam: Area2D = $Beam

## Set by the counter once the store opens.
var active := false:
	set(value):
		active = value
		if beam:
			beam.active = value
		queue_redraw()
var _bulb := 1.0
var _was_on := false
var _click_hold := false


func _ready() -> void:
	enabled = false
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = m
	GameState.resource_changed.connect(_on_resource_changed)
	_bulb = GameState.battery / GameState.MAX_BATTERY


## _input runs before the GUI and the counter tools, so a press that starts on
## a face, cash, or the open ledger page turns the lamp on.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and active and _over_scan_spot():
		_click_hold = true
	elif event.is_action_released("interact"):
		_click_hold = false


func _over_scan_spot() -> bool:
	var at := get_global_mouse_position()
	for n in get_tree().get_nodes_in_group("uv_target"):
		if n.has_method("uv_spot_at") and n.uv_spot_at(at) != "":
			return true
	return false


func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	var held := Input.is_action_pressed("uv_lamp") or _click_hold
	var on := active and held and GameState.battery > 0.0
	enabled = on and not Settings.low_graphics
	beam.lit = on
	if on:
		GameState.drain_battery(GameState.BATTERY_DRAIN_PER_SECOND * delta)
	if on != _was_on:
		Sfx.play(self, "click", -10.0)
		_was_on = on
	energy = lerpf(0.5, 1.7, _bulb)


func _on_resource_changed(resource: String, value: float, _delta: float) -> void:
	if resource != "battery":
		return
	_bulb = value / GameState.MAX_BATTERY
	queue_redraw()
	if value <= 0.0:
		Sfx.play(self, "error", -6.0)


func _draw() -> void:
	if not active:
		return
	# The cursor glows violet, and the bulb dims as the battery drops (5.4).
	var a := 0.35 + 0.6 * _bulb
	draw_circle(Vector2.ZERO, 5, Color(0.75, 0.5, 1.0, a))
	draw_arc(Vector2.ZERO, 10, 0, TAU, 24, Color(0.8, 0.6, 1.0, 0.3 + 0.6 * _bulb), 2.0)
	if GameState.battery <= 0.0:
		draw_line(Vector2(-8, -8), Vector2(8, 8), Color(0.8, 0.8, 0.8, 0.9), 2.0)
