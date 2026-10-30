extends Control
## Lola's utang ledger. Left-click the book on the counter or press the ledger
## action to open or close it (Table 21). It opens over the lower half of the
## screen so the face and cash stay visible (Table 20). It turns to each
## customer's entry on customer_arrived, and an ink smear shows under the UV
## lamp on uv_hit (Table 22). In the day phase it shows the chat being written.

## Day phase use. No pen and no UV.
@export var day_mode := false

const CLOSED_RECT := Rect2(152, 431, 167, 72)
const OPEN_RECT := Rect2(40, 432, 600, 282)

@onready var page: TextureRect = $Page
@onready var entry: RichTextLabel = $Entry
@onready var smear: TextureRect = $Smear
@onready var utang_pen: TextureButton = $UtangPen
@onready var utang_lines: Label = $UtangLines
@onready var close_button: Button = $CloseButton

var is_open := false
var current: Dictionary = {}
var smear_revealed := false
var _tween: Tween
var _refresh := 0.0


var highlight: Highlight


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.gui_input.connect(_on_page_input)
	# Clicks on the open page pass through, so a click and hold can scan it.
	page.mouse_filter = Control.MOUSE_FILTER_PASS
	close_button.pressed.connect(func(): if is_open: toggle())
	# The open page stays readable in the dark, as if lit by the desk lamp.
	var lit := CanvasItemMaterial.new()
	lit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for node in [page, entry, utang_lines, close_button, utang_pen]:
		node.material = lit
	if not day_mode:
		highlight = Highlight.new()
		highlight.rect = CLOSED_RECT
		highlight.label = "Open the ledger [L]"
		add_child(highlight)
		highlight.watch(page)
	if day_mode:
		utang_pen.visible = false
		utang_pen.set_process_unhandled_input(false)
		utang_lines.visible = false
		_set_open(true, false)
	else:
		add_to_group("uv_target")
		_set_open(false, false)
	_render()


func _unhandled_input(event: InputEvent) -> void:
	if day_mode:
		return
	if event.is_action_pressed("ledger"):
		toggle()


func _on_page_input(event: InputEvent) -> void:
	if day_mode:
		return
	# Only the closed book opens on a click. The open page closes with its
	# Close button or L.
	if event.is_action_pressed("interact") and not is_open:
		accept_event()
		toggle()


func toggle() -> void:
	_set_open(not is_open, true)


func _set_open(open: bool, animate: bool) -> void:
	is_open = open
	if animate:
		Sfx.play(self, "page", -4.0)
	var rect := OPEN_RECT if open else CLOSED_RECT
	if _tween and _tween.is_valid():
		_tween.kill()
	if animate:
		_tween = create_tween().set_parallel(true)
		_tween.tween_property(page, "position", rect.position, 0.2)
		_tween.tween_property(page, "size", rect.size, 0.2)
		_tween.tween_property(page, "modulate:a", 1.0 if open else 0.0, 0.2)
	else:
		page.position = rect.position
		page.size = rect.size
		page.modulate.a = 1.0 if open else 0.0
	entry.visible = open
	close_button.visible = open and not day_mode
	page.mouse_default_cursor_shape = Control.CURSOR_ARROW if open else Control.CURSOR_POINTING_HAND
	if highlight:
		highlight.visible = not open
	utang_lines.visible = open and not day_mode
	utang_pen.visible = open and not day_mode and GameState.night < GameState.LAST_NIGHT
	# Always drawn while open. The shader keeps it invisible until revealed.
	smear.visible = open


## Table 22: the ledger turns to the new customer's entry.
func _on_customer_arrived(c: Dictionary) -> void:
	current = c
	smear_revealed = false
	_set_smear_revealed(0.0)
	var teach: String = c.get("teach", "")
	if teach in ["first_serve", "utang", "tamper"] and not is_open:
		_set_open(true, true)
	else:
		Sfx.play(self, "page", -10.0)
	utang_pen.glow = teach == "utang"
	_render()


## Table 22: after 2 seconds on the page, a tampered entry shows its smear.
func _on_uv_hit(spot: String) -> void:
	if spot != "ledger" or current.is_empty():
		return
	if current.get("smeared", false) and not smear_revealed:
		smear_revealed = true
		_set_smear_revealed(1.0)
		Sfx.play(self, "reveal", -4.0)
		_render()


func _set_smear_revealed(v: float) -> void:
	var mat := smear.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("revealed", v)


func uv_spot_at(world_pos: Vector2) -> String:
	if not is_open or current.is_empty():
		return ""
	# The pen and the Close button stay clickable.
	for c in [utang_pen, close_button]:
		if c.visible and Rect2(c.global_position, c.size).grow(4).has_point(world_pos):
			return ""
	if uv_spot_rect("ledger").has_point(world_pos):
		return "ledger"
	return ""


func uv_spot_rect(_spot: String) -> Rect2:
	return Rect2(OPEN_RECT.position, OPEN_RECT.size)


func uv_subject_id() -> String:
	return current.get("id", "")


func uv_result(_spot: String) -> Dictionary:
	if smear_revealed:
		return {"kind": "warn", "text": "Ledger: fresh ink. This entry was changed."}
	return {"kind": "clean", "text": "Ledger: no fresh ink"}


func _process(delta: float) -> void:
	if day_mode:
		return
	var mat := smear.material as ShaderMaterial
	var beam := get_tree().get_first_node_in_group("uv_beam")
	if mat and beam:
		mat.set_shader_parameter("beam_pos", beam.global_position)
		mat.set_shader_parameter("beam_radius", beam.radius)
		mat.set_shader_parameter("beam_on", 1.0 if beam.lit else 0.0)
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = 0.3
		_render_utang()


func _render() -> void:
	entry.text = _entry_text(current)
	_render_utang()


func _entry_text(c: Dictionary) -> String:
	if c.is_empty():
		return "[i]Lola's ledger[/i]"
	if c.get("kind", "") != "regular":
		return "[b]A stranger[/b]\n[i]No line in Lola's book.[/i]"
	var l: Dictionary = c["ledger"]
	var t := "[font_size=24][b]%s[/b][/font_size]\n" % l["name"]
	t += "Usual order: %s\n" % CustomerData.item_name(l["usual"])
	t += "Detail: %s\n" % (l["detail"] if l["detail"] != "" else "[i]not known yet[/i]")
	var past: Array = l["past_debts"]
	if past.size() > 0:
		t += "[font_size=16]"
		for line in past.slice(0, 5):
			t += "[s]%s[/s]\n" % line
		t += "[/font_size]"
	if smear_revealed:
		t += "[color=#6a2cc0][b]Fresh ink: someone changed the order line.[/b][/color]"
	return t


func _render_utang() -> void:
	if day_mode:
		return
	var t := "UTANG\n"
	if GameState.night >= GameState.LAST_NIGHT:
		t += "\nThe pen is gone.\nNo utang tonight."
	else:
		var tonight := GameState.debts.filter(func(d): return d["night"] == GameState.night)
		for i in GameState.UTANG_PER_NIGHT:
			if i < tonight.size():
				t += "%d. %s PHP %d\n" % [i + 1, tonight[i]["name"], tonight[i]["amount"]]
			else:
				t += "%d. ____________\n" % (i + 1)
	var older := GameState.debts.filter(func(d): return d["night"] != GameState.night)
	if older.size() > 0:
		t += "\nStill owed:\n"
		for d in older:
			t += "%s PHP %d\n" % [d["name"], d["amount"]]
	utang_lines.text = t


## Day phase: show a regular's entry and write the new detail by hand.
func show_regular(regular_id: String, write_detail: bool) -> void:
	var reg: Dictionary = CustomerData.REGULARS[regular_id]
	current = {"kind": "regular", "ledger": {
		"name": reg["name"], "usual": reg["usual"], "past_debts": reg["past_debts"],
		"detail": reg["detail"] if (write_detail or GameState.known.has(regular_id)) else ""}}
	_render()
	if write_detail:
		var parsed := entry.get_parsed_text()
		var at := parsed.find(reg["detail"])
		entry.visible_characters = at
		Sfx.play(self, "pen", -2.0)
		var t := create_tween()
		t.tween_property(entry, "visible_characters", at + reg["detail"].length(), 1.4)
		t.tween_callback(func(): entry.visible_characters = -1)
	else:
		entry.visible_characters = -1
