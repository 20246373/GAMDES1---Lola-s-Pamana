extends Node2D
## The roll-down shutter outside the store. When it is down it closes off the
## whole street view. Drawn in screen space, and only redrawn while it moves.

const WINDOW := Rect2(262, 0, 842, 412)

## 0 is fully up, 1 is fully down.
var amount := 1.0
var _tween: Tween


func move_to(target: float, seconds: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "amount", target, seconds).set_trans(Tween.TRANS_QUAD)
	_tween.tween_callback(queue_redraw)


func _process(_delta: float) -> void:
	if _tween and _tween.is_running():
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if amount <= 0.001:
		return
	draw_set_transform(-global_position, 0.0, Vector2.ONE)
	var h := WINDOW.size.y * amount
	var r := Rect2(WINDOW.position, Vector2(WINDOW.size.x, h))
	draw_rect(r, Color(0.32, 0.33, 0.36))
	var y := r.position.y + 6.0
	while y < r.end.y:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(0.2, 0.21, 0.24), 3.0)
		draw_line(Vector2(r.position.x, y + 4), Vector2(r.end.x, y + 4), Color(0.45, 0.46, 0.5), 1.0)
		y += 16.0
	draw_rect(Rect2(Vector2(r.position.x, r.end.y - 10), Vector2(r.size.x, 10)), Color(0.18, 0.18, 0.2))
	if amount > 0.95:
		# The CLOSE side of Lola's sign hangs on the shutter at 6 PM.
		var plate := Rect2(Vector2(WINDOW.get_center().x - 70, WINDOW.end.y - 120), Vector2(140, 46))
		draw_rect(plate, Color(0.92, 0.9, 0.82))
		draw_rect(plate, Color(0.2, 0.15, 0.1), false, 2.0)
		draw_string(ThemeDB.fallback_font, plate.position + Vector2(24, 32), "CLOSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.55, 0.12, 0.1))
