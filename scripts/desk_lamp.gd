extends PointLight2D
## The dim desk lamp. It always lights the grille (8.2). It flickers when a
## warning plays (Table 22) and dims briefly for street events in quiet gaps.

var base_energy := 1.25
var _tween: Tween


var _low := false


func _ready() -> void:
	energy = base_energy
	material = Glow.add_material()
	_apply_quality()


func _process(_delta: float) -> void:
	if Settings.low_graphics != _low:
		_apply_quality()
	if _low and _tween and _tween.is_running():
		queue_redraw()


## Low graphics swaps the 2D light for a glow, which costs far less.
func _apply_quality() -> void:
	_low = Settings.low_graphics
	enabled = not _low
	queue_redraw()


func _draw() -> void:
	if not _low:
		return
	var a := clampf(energy / base_energy, 0.0, 1.2)
	Glow.draw(self, Vector2.ZERO, 300.0, Color(1.0, 0.8, 0.5, 0.22 * a))
	Glow.draw(self, Vector2(-300, 70), 190.0, Color(1.0, 0.8, 0.5, 0.12 * a))


func _on_warning_played(_sound: String, _caption: String) -> void:
	flicker()


func flicker() -> void:
	_kill()
	Sfx.play(self, "buzz", -8.0)
	_tween = create_tween()
	var low := 0.55 if Settings.reduced_scares else 0.15
	var steps := 3 if Settings.reduced_scares else 6
	for i in steps:
		_tween.tween_property(self, "energy", low, 0.05)
		_tween.tween_property(self, "energy", base_energy, 0.07)
	_tween.tween_property(self, "energy", base_energy, 0.1)
	_tween.tween_callback(queue_redraw)


func dim(seconds: float = 1.0) -> void:
	_kill()
	_tween = create_tween()
	_tween.tween_property(self, "energy", base_energy * 0.4, 0.3)
	_tween.tween_interval(seconds)
	_tween.tween_property(self, "energy", base_energy, 0.4)


func _kill() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	energy = base_energy
