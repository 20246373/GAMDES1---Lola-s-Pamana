extends Area2D
## The radio. Left-click it or press the radio action to switch it on or off
## (Table 21). On: music, no Sanity drain, warnings muted. Off: warnings heard,
## Sanity drains 1 every 30 seconds (Section II). Emits radio_toggled (Table 22).

signal radio_toggled(on: bool)

@onready var music: AudioStreamPlayer = $Music

var on := true
var _static := false
var _silenced := false
var _static_player: AudioStreamPlayer


var highlight: Highlight


func _ready() -> void:
	highlight = Highlight.new()
	highlight.rect = Rect2(-66, -48, 132, 88)
	add_child(highlight)
	highlight.watch(self)
	_update_label()
	music.finished.connect(_on_music_finished)
	if can_process():
		_update_music()


func _on_music_finished() -> void:
	if _should_play():
		music.play()


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		toggle()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("radio"):
		toggle()


func toggle() -> void:
	if _static:
		return
	on = not on
	_update_label()
	Sfx.play(self, "click", -4.0)
	_update_music()
	radio_toggled.emit(on)


## Night 2 teaching beat: the radio cuts to static by itself (5.4).
func force_static(seconds: float) -> void:
	_static = true
	_update_music()
	_static_player = Sfx.play(self, "static", -8.0)
	var t := create_tween()
	t.tween_interval(min(2.0, seconds))
	t.tween_callback(func():
		if is_instance_valid(_static_player):
			_static_player.stop()
	)
	t.tween_interval(max(0.0, seconds - 2.0))
	t.tween_callback(func():
		_static = false
		_update_music()
	)


## Night 3 silence beat: everything cuts out until the next customer (5.4).
func set_silenced(value: bool) -> void:
	_silenced = value
	_update_music()


func is_audible_off() -> bool:
	return not on


func _update_label() -> void:
	if highlight:
		highlight.set_label("Turn the radio off [T]" if on else "Turn the radio on [T]")


func _should_play() -> bool:
	return on and not _static and not _silenced


func _update_music() -> void:
	queue_redraw()
	if _should_play():
		if not music.playing:
			music.play()
	else:
		music.stop()




func _draw() -> void:
	var body := Rect2(Vector2(-62, -34), Vector2(124, 68))
	draw_rect(body, Color(0.36, 0.22, 0.16))
	draw_rect(body, Color(0.12, 0.07, 0.05), false, 3.0)
	# Speaker grille.
	for i in 6:
		draw_line(Vector2(-52, -22 + i * 8), Vector2(-6, -22 + i * 8), Color(0.18, 0.11, 0.08), 3.0)
	# Dial and power light.
	draw_circle(Vector2(30, -6), 14, Color(0.75, 0.68, 0.5))
	var ang := -0.3 if _should_play() else -0.9
	draw_line(Vector2(30, -6), Vector2(30, -6) + Vector2(cos(ang), sin(ang)) * 11, Color(0.2, 0.1, 0.05), 2.0)
	var light := Color(0.35, 1.0, 0.45) if _should_play() else (Color(1.0, 0.85, 0.3) if _static else Color(0.35, 0.1, 0.1))
	draw_circle(Vector2(30, 20), 5, light)
	draw_string(ThemeDB.fallback_font, Vector2(-54, 28), "ON" if on else "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.85, 0.7))
	draw_rect(Rect2(Vector2(-58, -44), Vector2(4, 12)), Color(0.6, 0.6, 0.65))
