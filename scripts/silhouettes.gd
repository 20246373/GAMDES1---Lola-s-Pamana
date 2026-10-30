extends Node2D
## Refused entities linger at the edge of the window until dawn. One
## silhouette per point of Presence, so the count shows without a meter (M8).
## Listens to presence_changed (Table 22).

const SPOTS := [Vector2(330, 411), Vector2(1035, 411), Vector2(430, 411)]

var _alpha: Array = [0.0, 0.0, 0.0]
var _count := 0
var _time := 0.0


func _ready() -> void:
	GameState.presence_changed.connect(_on_presence_changed)
	_count = GameState.presence
	for i in SPOTS.size():
		_alpha[i] = 0.85 if i < _count else 0.0


func _on_presence_changed(value: int) -> void:
	if value > _count:
		Sfx.play(self, "footsteps", -12.0)
	_count = value
	for i in SPOTS.size():
		var target := 0.85 if i < value else 0.0
		var t := create_tween()
		t.tween_method(func(a): _alpha[i] = a, _alpha[i], target, 1.5)


func _process(delta: float) -> void:
	_time += delta
	for a in _alpha:
		if a > 0.01:
			queue_redraw()
			return


func _draw() -> void:
	for i in SPOTS.size():
		if _alpha[i] <= 0.01:
			continue
		var base: Vector2 = SPOTS[i] + Vector2(sin(_time * 0.6 + i) * 4, 0)
		var c := Color(0.0, 0.0, 0.02, _alpha[i])
		draw_circle(base + Vector2(0, -235), 32, c)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-70, 0), base + Vector2(-58, -185), base + Vector2(-28, -205),
			base + Vector2(28, -205), base + Vector2(58, -185), base + Vector2(70, 0)]), c)
		draw_circle(base + Vector2(-10, -240), 2.5, Color(0.9, 0.85, 0.7, _alpha[i] * 0.5))
		draw_circle(base + Vector2(10, -240), 2.5, Color(0.9, 0.85, 0.7, _alpha[i] * 0.5))
