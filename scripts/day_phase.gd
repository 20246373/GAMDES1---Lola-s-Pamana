extends Control
## The day phase. A catalogue for Salt, battery packs, and salabat, and three
## visiting regulars. The player chats with up to two, and each chat writes one
## personal detail into the ledger (Section II). Day 2's first visitor is
## always Aling Bebang, and her chat cannot be skipped (5.4). No countdown.
## Emits day_finished (Table 22).

signal day_finished

@onready var catalogue: GridContainer = $Catalogue
@onready var visitors: HBoxContainer = $Visitors
@onready var visitor_names: HBoxContainer = $VisitorNames
@onready var hint: Label = $Hint
@onready var day_ledger: Control = $DayLedger
@onready var stats: Label = $Stats
@onready var speech: Label = $SpeechPanel/Speech
@onready var speech_panel: PanelContainer = $SpeechPanel
@onready var open_button: Button = $OpenButton
@onready var title: Label = $Title

var _chatted := {}
var _buttons: Array = []
var _visitor_buttons := {}
var _forced := ""


func _ready() -> void:
	if not can_process():
		return
	var day := GameState.night
	title.text = "Day %d" % day
	if day == 2:
		_forced = "aling_bebang"
	_build_catalogue()
	_build_visitors(CustomerData.DAY_VISITORS[day])
	open_button.pressed.connect(_on_open_pressed)
	speech_panel.visible = false
	_refresh()
	_buttons[0].grab_focus()


func _build_catalogue() -> void:
	for i in CustomerData.CATALOGUE.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(176, 112)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_buy.bind(i))
		catalogue.add_child(b)
		_buttons.append(b)


## The visiting regulars stand at the window, behind the grille and the
## store art. Each one is a flat button, so clicking a regular starts a chat.
func _build_visitors(ids: Array) -> void:
	var delay := 0.3
	var empty := StyleBoxEmpty.new()
	for rid in ids:
		var look: Dictionary = CustomerData.LOOKS[rid]
		var b := Button.new()
		b.custom_minimum_size = Vector2(210, 274)
		b.focus_mode = Control.FOCUS_ALL
		for style in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(style, empty)
		b.pressed.connect(_chat.bind(rid))
		var tex: Texture2D = load(look["tex"])
		var k := float(tex.get_width()) / float(look["src"])
		var bbox: Rect2 = look["bbox"]
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(bbox.position * k, bbox.size * k)
		var portrait := TextureRect.new()
		portrait.texture = atlas
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		portrait.offset_top = 274.0 - look["height"]
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(portrait)
		visitors.add_child(b)
		# Name tags sit on a dark plate above each regular's head, clear of the
		# speech box and the counter art.
		var holder := CenterContainer.new()
		holder.custom_minimum_size = Vector2(210, 28)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var name_label := Label.new()
		name_label.text = CustomerData.REGULARS[rid]["name"]
		name_label.add_theme_font_size_override("font_size", 17)
		name_label.add_theme_stylebox_override("normal", _name_plate())
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(name_label)
		visitor_names.add_child(holder)
		b.focus_entered.connect(func(): name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35)))
		b.focus_exited.connect(func(): name_label.remove_theme_color_override("font_color"))
		b.mouse_entered.connect(func(): name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35)))
		b.mouse_exited.connect(func(): if not b.has_focus(): name_label.remove_theme_color_override("font_color"))
		_visitor_buttons[rid] = {"button": b, "idle": tex, "portrait": portrait, "atlas": atlas, "look": look, "name": name_label}
		# Visitors walk up one at a time. On Day 2, Aling Bebang is first.
		for node in [b, holder]:
			node.modulate.a = 0.0
			var t: Tween = node.create_tween()
			t.tween_interval(delay)
			t.tween_property(node, "modulate:a", 1.0, 0.6)
		delay += 0.7


func _name_plate() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.06, 0.82)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	return sb


func _unhandled_input(event: InputEvent) -> void:
	for i in 3:
		if event.is_action_pressed("buy_%d" % (i + 1)):
			_buy(i)
			get_viewport().set_input_as_handled()
			return


func _buy(i: int) -> void:
	var entry: Dictionary = CustomerData.CATALOGUE[i]
	if GameState.buy(entry["id"]):
		Sfx.play(self, "buy", -2.0)
		var b: Button = _buttons[i]
		var t := b.create_tween()
		t.tween_property(b, "scale", Vector2(1.06, 1.06), 0.08)
		t.tween_property(b, "scale", Vector2.ONE, 0.1)
	else:
		Sfx.play(self, "error", -4.0)
	_refresh()


func _chat(rid: String) -> void:
	if _chatted.has(rid):
		return
	if _forced != "" and rid != _forced:
		Sfx.play(self, "error", -6.0)
		return
	if not GameState.chat(rid):
		Sfx.play(self, "error", -6.0)
		return
	_chatted[rid] = true
	if rid == _forced:
		_forced = ""
	var reg: Dictionary = CustomerData.REGULARS[rid]
	speech.text = "%s: \"%s\"" % [reg["name"], reg["chat"]]
	speech_panel.visible = true
	day_ledger.show_regular(rid, true)
	Sfx.play(self, "voice", -4.0)
	_talk(rid)
	_refresh()


func _talk(rid: String) -> void:
	var v: Dictionary = _visitor_buttons[rid]
	var look: Dictionary = v["look"]
	if look["talk"] == "":
		var b: Button = v["button"]
		var bob := b.create_tween()
		for i in 4:
			bob.tween_property(v["portrait"], "position:y", 3.0 if i % 2 == 0 else 6.0, 0.15)
		return
	var talk_tex: Texture2D = load(look["talk"])
	var atlas: AtlasTexture = v["atlas"]
	var t := create_tween()
	for i in 6:
		t.tween_callback(func(): atlas.atlas = talk_tex if i % 2 == 0 else v["idle"])
		t.tween_interval(0.18)
	t.tween_callback(func(): atlas.atlas = v["idle"])


func _refresh() -> void:
	for i in CustomerData.CATALOGUE.size():
		var entry: Dictionary = CustomerData.CATALOGUE[i]
		var b: Button = _buttons[i]
		var extra := ""
		match entry["id"]:
			"salt":
				extra = "Jar: %d of %d" % [GameState.salt, GameState.MAX_SALT]
			"battery":
				extra = "+50%%, now %d%%" % int(round(GameState.battery))
			"salabat":
				extra = "+10 Sanity"
		b.text = "%s\nPHP %d\n%s\nKey %d" % [entry["name"], entry["price"], extra, i + 1]
		b.disabled = not GameState.can_buy(entry["id"])
	for rid in _visitor_buttons:
		var b: Button = _visitor_buttons[rid]["button"]
		var blocked: bool = _chatted.has(rid) or GameState.chats_left <= 0 or (_forced != "" and rid != _forced)
		b.disabled = blocked
		_visitor_buttons[rid]["portrait"].self_modulate = Color(0.6, 0.6, 0.65) if blocked else Color.WHITE
	stats.text = "PHP %d    Sanity %d    UV %d%%    Salt %d/%d    Chats left %d" % [
		GameState.pesos, GameState.sanity, int(round(GameState.battery)), GameState.salt,
		GameState.MAX_SALT, GameState.chats_left]
	open_button.disabled = _forced != ""
	hint.visible = Settings.control_hints
	if _forced != "":
		hint.text = "Aling Bebang is the first visitor today. Click her to chat with her first."
	elif GameState.chats_left > 0:
		hint.text = "To buy supplies, click an item or press 1, 2, or 3. To chat, click a regular at the window. Each chat writes one detail into the ledger. Chats left today: %d." % GameState.chats_left
	else:
		hint.text = "No chats left today. Buy what you need, then press Open at 6 PM."


func _on_open_pressed() -> void:
	if _forced != "":
		return
	Sfx.play(self, "click")
	day_finished.emit()
