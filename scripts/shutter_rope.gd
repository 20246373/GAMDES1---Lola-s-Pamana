extends Area2D
## The shutter rope. At 6 PM the shutter is down, and clicking the rope raises
## it to open the store (5.4). With a customer at the grille, drag the rope
## down, click it twice, or press refuse to drop the shutter (Table 21). The
## second click confirms, so a costly Refuse is never a slip.
## Emits decision_made (Table 22).

signal decision_made(decision: String)

const TOP := -290.0
const PULL_TO_ACT := 55.0

@onready var shutter: Node2D = $Shutter

var shutter_down := true
var _dragging := false
var _drag_start := 0.0
var _pull := 0.0
var _time := 0.0
var _armed := 0.0
var _store_open := false
var highlight: Highlight


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_dragging = true
		_drag_start = get_global_mouse_position().y


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		_pull = clampf(get_global_mouse_position().y - _drag_start, 0.0, 90.0)
	elif event.is_action_released("interact"):
		_dragging = false
		var pulled := _pull >= PULL_TO_ACT
		_pull = 0.0
		if shutter_down:
			# Opening is safe, so a click is enough.
			decision_made.emit("open")
		elif pulled or _armed > 0.0:
			_disarm()
			decision_made.emit("refuse")
		else:
			# First click: ask for a second click to confirm.
			_armed = 3.0
			highlight.warn = true
			highlight.set_label("Click again to refuse")
			Sfx.play(self, "click", -4.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("refuse"):
		decision_made.emit("open" if shutter_down else "refuse")


func _disarm() -> void:
	_armed = 0.0
	if highlight:
		highlight.warn = false
		_update_label()


func _update_label() -> void:
	if not highlight:
		return
	if shutter_down and not _store_open:
		highlight.set_label("Open the store [R]")
	elif shutter_down:
		highlight.set_label("Shutter is down")
	else:
		highlight.set_label("Refuse: click twice [R]")


func raise_shutter() -> void:
	_disarm()
	if not shutter_down:
		return
	shutter_down = false
	_store_open = true
	_update_label()
	Sfx.play(self, "shutter", -8.0, "SFX", 1.2)
	shutter.move_to(0.0, 0.9)
	queue_redraw()


func drop_shutter() -> void:
	shutter_down = true
	_disarm()
	Sfx.play(self, "shutter")
	shutter.move_to(1.0, 0.25)


func _process(delta: float) -> void:
	_time += delta
	if _armed > 0.0:
		_armed -= delta
		if _armed <= 0.0:
			_disarm()
	if shutter_down or _dragging or _pull != 0.0:
		queue_redraw()


func _ready() -> void:
	highlight = Highlight.new()
	highlight.rect = Rect2(-20, -28, 40, 56)
	add_child(highlight)
	highlight.watch(self)
	_update_label()
	queue_redraw()


func _draw() -> void:
	# The rope sways gently while it waits to be pulled (5.4).
	var sway := sin(_time * 1.6) * (6.0 if shutter_down else 2.0)
	var handle := Vector2(sway, _pull)
	draw_line(Vector2(0, TOP), handle + Vector2(0, -18), Color(0.72, 0.62, 0.42), 4.0)
	draw_line(Vector2(1, TOP), handle + Vector2(1, -18), Color(0.45, 0.36, 0.22), 1.5)
	draw_rect(Rect2(handle + Vector2(-9, -18), Vector2(18, 36)), Color(0.45, 0.28, 0.14))
	draw_rect(Rect2(handle + Vector2(-9, -18), Vector2(18, 36)), Color(0.18, 0.1, 0.05), false, 2.0)
	if shutter_down:
		draw_arc(handle, 26 + sin(_time * 3.0) * 3, 0, TAU, 32, Color(1, 0.85, 0.5, 0.35), 2.0)
