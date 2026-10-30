extends Sprite2D
## The street seen through the iron grille, with drifting fog and the
## cosmetic shadow that crosses during quiet gaps (5.3 and 6.4).
## Only the part behind the window is drawn, which saves work on slow GPUs.

const WINDOW := Rect2(264, 6, 838, 405)

var fog_enabled := true
var _time := 0.0
var _shadow := -1.0
var _shadow_dir := 1.0


func _process(delta: float) -> void:
	_time += delta
	var moving := false
	if _shadow >= 0.0:
		_shadow += delta / 3.2
		moving = true
		if _shadow > 1.0:
			_shadow = -1.0
	if moving or (fog_enabled and not Settings.low_graphics):
		queue_redraw()


func shadow_pass(left_to_right: bool = true) -> void:
	_shadow = 0.0
	_shadow_dir = 1.0 if left_to_right else -1.0


func _draw() -> void:
	# Draw in screen pixels even though the sprite is scaled.
	draw_set_transform(-position / scale, 0.0, Vector2.ONE / scale)
	var fog := 0 if (Settings.low_graphics or not fog_enabled) else 2
	for i in fog:
		var y := WINDOW.position.y + 300 + i * 60 + sin(_time * 0.3 + i) * 12
		var x := WINDOW.position.x - 200 + fmod(_time * (12 + i * 7) + i * 420, WINDOW.size.x + 400)
		Glow.draw(self, Vector2(x, y), 220.0, Color(0.8, 0.82, 0.9, 0.16))
	if _shadow >= 0.0:
		var x := lerpf(WINDOW.position.x - 80, WINDOW.end.x + 80, _shadow if _shadow_dir > 0 else 1.0 - _shadow)
		var base := Vector2(x, WINDOW.end.y + 10)
		var c := Color(0, 0, 0, 0.75)
		draw_circle(base + Vector2(0, -250), 30, c)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-55, 0), base + Vector2(-45, -200), base + Vector2(-20, -222),
			base + Vector2(20, -222), base + Vector2(45, -200), base + Vector2(55, 0)]), c)
