extends TextureButton
## The pen on Lola's utang page. Left-click it or press serve_utang to extend
## utang (Table 21). Allowed twice per night and never on Night 5. A third try
## fails because the pen has no free line to write on (5.4).
## Emits decision_made (Table 22).

signal decision_made(decision: String)

var glow := false
var _time := 0.0


var highlight: Highlight


func _ready() -> void:
	texture_normal = _make_texture()
	pressed.connect(_try)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	highlight = Highlight.new()
	highlight.rect = Rect2(Vector2(-4, -4), size + Vector2(8, 8))
	highlight.label = "Serve on utang [U]"
	add_child(highlight)
	highlight.watch(self)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("serve_utang"):
		_try()


func _try() -> void:
	if GameState.night >= GameState.LAST_NIGHT:
		return
	if not GameState.can_utang():
		Sfx.play(self, "error", -4.0)
		var t := create_tween()
		t.tween_property(self, "rotation", 0.25, 0.06)
		t.tween_property(self, "rotation", -0.25, 0.08)
		t.tween_property(self, "rotation", 0.0, 0.06)
		return
	Sfx.play(self, "pen", -2.0)
	glow = false
	decision_made.emit("serve_utang")


func _process(delta: float) -> void:
	_time += delta
	self_modulate = Color(1.3, 1.15, 0.8) if glow and fmod(_time, 1.0) < 0.5 else Color.WHITE


func _make_texture() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(8, 56):
		for w in range(-3, 4):
			var x := i + w
			var y := 63 - i
			if x >= 0 and x < 64:
				var col := Color(0.12, 0.12, 0.35) if i > 16 else Color(0.75, 0.7, 0.5)
				img.set_pixel(x, y, col)
	for i in range(4, 10):
		img.set_pixel(i, 63 - i, Color(0.05, 0.05, 0.05))
	return ImageTexture.create_from_image(img)
