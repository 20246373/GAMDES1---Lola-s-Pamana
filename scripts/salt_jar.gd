extends Area2D
## The salt jar on the counter. Left-click it or press banish to lay a salt
## barrier (Table 21). It uses 1 Salt. Emits decision_made (Table 22).
## The jar level drops one scoop per Banish, out of 6 (5.4).

signal decision_made(decision: String)

## Inside of the jar in the background art, in local space.
const JAR := Rect2(-42, -38, 84, 112)
## The old salt line on the windowsill, relative to this node.
const SILL_FROM := Vector2(530 - 163, 410 - 370)
const SILL_TO := Vector2(827 - 163, 410 - 370)

var _spark := 0.0
var _glint := 0.0
var _rng := RandomNumberGenerator.new()


var highlight: Highlight


func _ready() -> void:
	highlight = Highlight.new()
	# Stops above the open ledger page, so a click on the page never banishes.
	highlight.rect = Rect2(-50, -62, 100, 116)
	highlight.label = "Banish with salt [B]"
	add_child(highlight)
	highlight.watch(self)


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_try_banish()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("banish"):
		_try_banish()


func _try_banish() -> void:
	if GameState.salt <= 0:
		Sfx.play(self, "error", -4.0)
		return
	decision_made.emit("banish")


## Called by the counter when a Banish is accepted.
func pour() -> void:
	Sfx.play(self, "salt")
	spark_line()


## The salt line sparks. Night 1 uses this to point at the jar (5.4).
func spark_line() -> void:
	Sfx.play(self, "spark", -3.0)
	_spark = 1.0
	_glint = 1.0


var _drawn_salt := -1


func _process(delta: float) -> void:
	var busy := _spark > 0.0 or _glint > 0.0
	_spark = max(0.0, _spark - delta * 0.8)
	_glint = max(0.0, _glint - delta * 0.35)
	if busy or GameState.salt != _drawn_salt:
		_drawn_salt = GameState.salt
		queue_redraw()


func _draw() -> void:
	# Cover the empty part of the jar so the level matches the Salt count.
	var missing := 1.0 - float(GameState.salt) / float(GameState.MAX_SALT)
	if missing > 0.0:
		var h := JAR.size.y * missing
		draw_rect(Rect2(JAR.position, Vector2(JAR.size.x, h)), Color(0.12, 0.13, 0.17, 0.92))
	for i in range(1, GameState.MAX_SALT):
		var y := JAR.end.y - JAR.size.y * i / GameState.MAX_SALT
		draw_line(Vector2(JAR.position.x + 4, y), Vector2(JAR.position.x + 14, y), Color(0.3, 0.3, 0.35, 0.6), 1.0)
	if _glint > 0.0:
		draw_rect(JAR.grow(6), Color(1, 1, 0.85, 0.25 * _glint), false, 3.0)
	# The thin line of old salt along the sill, laid by Lola long ago.
	_rng.seed = 11
	var steps := 70
	for i in steps:
		var p := SILL_FROM.lerp(SILL_TO, float(i) / steps) + Vector2(_rng.randf_range(-2, 2), _rng.randf_range(-2, 1))
		draw_circle(p, 1.4, Color(0.9, 0.9, 0.95, 0.75))
		if _spark > 0.0 and _rng.randf() < 0.35:
			var s := _rng.randf_range(4, 14) * _spark
			draw_line(p, p + Vector2(_rng.randf_range(-s, s), -s), Color(1.0, 0.85, 0.4, _spark), 1.5)
