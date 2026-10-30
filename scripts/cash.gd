extends Sprite2D
## The customer's payment on the counter. Placeholder drawing until the cash
## art exists: bills for 20, 50, and 100, and coins for 10.

var amount := 0


func set_money(value: int) -> void:
	amount = value
	queue_redraw()


func _draw() -> void:
	if amount <= 0:
		return
	if amount < 20:
		for i in int(amount / 5.0):
			var p := Vector2(-18 + i * 12, 4 - (i % 2) * 3)
			draw_circle(p, 8, Color(0.75, 0.68, 0.4))
			draw_arc(p, 8, 0, TAU, 16, Color(0.4, 0.33, 0.15), 1.5)
		return
	var colors := {20: Color(0.95, 0.6, 0.25), 50: Color(0.85, 0.3, 0.3), 100: Color(0.55, 0.45, 0.85)}
	var col: Color = colors.get(amount, Color(0.6, 0.8, 0.5))
	var rect := Rect2(Vector2(-38, -16), Vector2(76, 32))
	draw_rect(rect.grow(1), Color(0.15, 0.12, 0.08))
	draw_rect(rect, col)
	draw_rect(rect.grow(-5), col.darkened(0.2), false, 1.5)
	draw_circle(Vector2(-16, 0), 7, col.lightened(0.3))
	draw_string(ThemeDB.fallback_font, Vector2(2, 7), str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.1, 0.08, 0.05))
