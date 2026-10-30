extends Area2D
## The cash drawer. Left-click it or press serve to hand over the item and
## take payment (Table 21). Emits decision_made (Table 22).

signal decision_made(decision: String)

const SIZE := Vector2(150, 58)

## Lit by the desk lamp on Night 1's first customer (5.4).
var highlight_first := false
var _open := 0.0
var _time := 0.0


var highlight: Highlight


func _ready() -> void:
	highlight = Highlight.new()
	highlight.rect = Rect2(-SIZE / 2, SIZE).grow(4)
	highlight.label = "Serve [S]"
	add_child(highlight)
	highlight.watch(self)


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		decision_made.emit("serve")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("serve"):
		decision_made.emit("serve")


## Called by the counter when a Serve is accepted.
func play_open() -> void:
	highlight_first = false
	Sfx.play(self, "coin")
	var t := create_tween()
	t.tween_property(self, "_open", 1.0, 0.18)
	t.tween_interval(0.5)
	t.tween_property(self, "_open", 0.0, 0.25)


var _drawn_open := -1.0
var _drawn_highlight := false


func _process(delta: float) -> void:
	_time += delta
	if highlight_first or highlight_first != _drawn_highlight or _open != _drawn_open:
		_drawn_open = _open
		_drawn_highlight = highlight_first
		queue_redraw()


func _draw() -> void:
	var r := Rect2(-SIZE / 2, SIZE)
	if highlight_first:
		var a := 0.25 + 0.2 * sin(_time * 4.0)
		draw_rect(r.grow(8), Color(1.0, 0.85, 0.5, a))
	# Tray, drawn sliding out toward the player when open.
	var tray := Rect2(r.position + Vector2(8, SIZE.y - 6 + 22 * _open), Vector2(SIZE.x - 16, 18 + 10 * _open))
	if _open > 0.01:
		draw_rect(tray, Color(0.3, 0.22, 0.14))
		for i in 4:
			draw_rect(Rect2(tray.position + Vector2(8 + i * 32, 4), Vector2(26, 10)), Color(0.85, 0.7, 0.4) if i % 2 == 0 else Color(0.7, 0.75, 0.75))
	draw_rect(r, Color(0.32, 0.21, 0.12))
	draw_rect(r, Color(0.12, 0.08, 0.05), false, 3.0)
	draw_rect(Rect2(r.position + Vector2(10, 8), Vector2(SIZE.x - 20, 10)), Color(0.15, 0.1, 0.06))
	draw_rect(Rect2(Vector2(-22, 10), Vector2(44, 8)), Color(0.75, 0.6, 0.3))
	draw_string(ThemeDB.fallback_font, Vector2(-30, -4), "CASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.75, 0.55))
