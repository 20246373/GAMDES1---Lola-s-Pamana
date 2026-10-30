extends CanvasLayer
## The night HUD. Always shows Pesos, Sanity, UV battery, and the Salt count
## on solid panels (Table 20). Updates with a sound on resource_changed, shows
## each order as a caption on customer_arrived, and names each warning on
## warning_played (Table 22).

@onready var pesos: Label = $Pesos
@onready var sanity: TextureProgressBar = $Sanity
@onready var battery: TextureProgressBar = $Battery
@onready var salt_count: Label = $SaltCount
@onready var caption: Label = $Caption
@onready var caption_panel: Panel = $CaptionPanel
@onready var sanity_value: Label = $SanityValue
@onready var battery_value: Label = $BatteryValue
@onready var utang_label: Label = $UtangLabel
@onready var night_label: Label = $NightLabel
@onready var clock: Label = $Clock
@onready var hint: Label = $Hint
@onready var hint_panel: Panel = $HintPanel
@onready var tags: Control = $Tags
@onready var scan_panel: Panel = $ScanPanel
@onready var scan_list: RichTextLabel = $ScanList

## Key labels on the counter tools, in screen pixels (Table 21).
const TAGS := {
	"ledger": {"pos": Vector2(170, 506), "text": "Ledger [L]"},
	"salt": {"pos": Vector2(208, 392), "text": "Banish [B]"},
	"drawer": {"pos": Vector2(784, 540), "text": "Serve [S]"},
	"rope": {"pos": Vector2(886, 290), "text": "Refuse [R]"},
	"radio": {"pos": Vector2(1140, 506), "text": "Radio [T]"},
	"pen": {"pos": Vector2(474, 676), "text": "Utang [U]"},
}
const SCAN_COLORS := {"tell": "#ff7a6e", "warn": "#ffd27a", "clean": "#8dffa0"}

var _tag_labels := {}
var _hint_clock := 0.0

var _speech := ""
var _sound := ""
var _sound_time := 0.0
var _battery_warned := false


func _ready() -> void:
	if not can_process():
		visible = false
		return
	GameState.resource_changed.connect(_on_resource_changed)
	night_label.text = "Night %d" % GameState.night
	for key in TAGS:
		var l := Label.new()
		l.text = TAGS[key]["text"]
		l.position = TAGS[key]["pos"]
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.65))
		l.add_theme_constant_override("outline_size", 5)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tags.add_child(l)
		_tag_labels[key] = l
	_refresh_all()
	_update_caption()


func _refresh_all() -> void:
	pesos.text = "PHP %d" % GameState.pesos
	sanity.value = GameState.sanity
	sanity_value.text = str(GameState.sanity)
	battery.value = GameState.battery
	battery_value.text = "%d%%" % int(round(GameState.battery))
	salt_count.text = "Salt %d/%d" % [GameState.salt, GameState.MAX_SALT]
	utang_label.text = "Utang PHP %d" % GameState.utang_total()


## Table 22: the HUD updates the value with a sound.
func _on_resource_changed(resource: String, value: float, delta: float) -> void:
	_refresh_all()
	match resource:
		"pesos":
			if delta > 0:
				_popup(pesos, "+%d" % int(delta), Color(0.6, 1.0, 0.6))
			elif delta < 0:
				_popup(pesos, "%d" % int(delta), Color(1.0, 0.6, 0.5))
		"sanity":
			if delta < 0:
				Sfx.play(self, "heartbeat", -4.0 if delta <= -10 else -10.0)
				_popup(sanity, "%d" % int(delta), Color(1.0, 0.45, 0.4))
				_flash(sanity)
			elif delta > 0:
				Sfx.play(self, "gain", -8.0)
				_popup(sanity, "+%d" % int(delta), Color(0.6, 1.0, 0.7))
		"battery":
			if value <= 25.0 and not _battery_warned and delta < 0:
				_battery_warned = true
				Sfx.play(self, "low_battery", -6.0)
				_flash(battery)
			elif value > 25.0:
				_battery_warned = false
			if delta > 0:
				_popup(battery, "+%d%%" % int(delta), Color(0.8, 0.7, 1.0))
		"salt":
			if delta != 0:
				_popup(salt_count, ("%+d" % int(delta)), Color(0.95, 0.95, 1.0))
		"utang":
			if delta != 0:
				_popup(utang_label, ("%+d" % int(delta)), Color(1.0, 0.85, 0.6))


## Table 22: the order shows as a caption.
func _on_customer_arrived(c: Dictionary) -> void:
	var who: String = c["name"]
	_speech = "%s: \"%s\"" % [who, c["line"]]
	_update_caption()


## Table 22: a caption names the sound.
func _on_warning_played(_sound_name: String, text: String) -> void:
	if not Settings.captions or text == "":
		return
	_sound = text
	_sound_time = 4.5
	_update_caption()


func _process(delta: float) -> void:
	var counter := get_parent()
	if counter and counter.has_method("clock_text"):
		clock.text = counter.clock_text()
		if counter.current.is_empty() and _speech != "":
			_speech = ""
			_update_caption()
	_hint_clock -= delta
	if _hint_clock <= 0.0:
		_hint_clock = 0.25
		_update_hints(counter)
		_update_scan_list(counter)
	if _sound_time > 0.0:
		_sound_time -= delta
		if _sound_time <= 0.0:
			_sound = ""
			_update_caption()


## Contextual help. The GDD teaches through the level alone (5.4), so these
## hints can be turned off with Control hints in Settings.
func _update_hints(counter: Node) -> void:
	var on := Settings.control_hints and counter != null and counter.has_method("clock_text")
	hint.visible = on
	hint_panel.visible = on
	tags.visible = on
	if not on:
		return
	var ledger_open: bool = counter.ledger.is_open
	_tag_labels["ledger"].visible = not ledger_open
	_tag_labels["pen"].visible = ledger_open and GameState.night < GameState.LAST_NIGHT
	_tag_labels["rope"].text = "Open [R]" if not counter.opened else "Refuse [R]"
	var c: Dictionary = counter.current
	if not counter.opened:
		hint.text = "It is 6 PM. Click the shutter rope, or press R, to open the store."
	elif not c.is_empty():
		var scanned: Dictionary = counter.uv_lamp.beam.findings_for(c.get("id", ""))
		if scanned.is_empty():
			hint.text = "Check the ledger for this customer. Then point the mouse at their face or cash and hold the right mouse button or Space for 2 seconds. Clicking and holding on it works too."
		else:
			hint.text = "Two tells mean an entity. To decide, click a glowing object: the cash drawer to serve, the salt jar to banish, the shutter rope to refuse, or the pen in the ledger for utang."
	elif GameState.radio_on:
		hint.text = "Waiting for the next customer. Turn the radio off, by clicking it or pressing T, to hear warning sounds. Your Sanity drops while it is off."
	else:
		hint.text = "The radio is off, so you can hear warnings, but your Sanity drops 1 every 30 seconds. Click the radio or press T to turn it back on."


## What the UV lamp has found on the current customer, so no clue depends on
## hearing the scan sounds.
func _update_scan_list(counter: Node) -> void:
	var c: Dictionary = {}
	if counter != null and counter.has_method("clock_text"):
		c = counter.current
	var has_customer := not c.is_empty()
	scan_panel.visible = has_customer
	scan_list.visible = has_customer
	if not has_customer:
		return
	var found: Dictionary = counter.uv_lamp.beam.findings_for(c.get("id", ""))
	var t := "[b]UV scan[/b]\n"
	var spots := ["face", "cash"]
	if GameState.night >= 4 or found.has("ledger"):
		spots.append("ledger")
	for spot in spots:
		if found.has(spot):
			var r: Dictionary = found[spot]
			t += "[color=%s]%s[/color]\n" % [SCAN_COLORS.get(r["kind"], "#ffffff"), r["text"]]
		else:
			t += "[color=#9a94a8]%s: not scanned[/color]\n" % spot.capitalize()
	scan_list.text = t.strip_edges()


func _update_caption() -> void:
	var lines: Array = []
	if _speech != "":
		lines.append(_speech)
	if _sound != "":
		lines.append("[ " + _sound + " ]")
	caption.text = "\n".join(lines)
	caption_panel.visible = lines.size() > 0
	caption.visible = lines.size() > 0


func _popup(anchor: Control, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 22)
	l.position = anchor.position + Vector2(anchor.size.x * 0.5, 30)
	add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y + 26, 1.1)
	t.parallel().tween_property(l, "modulate:a", 0.0, 1.1).set_delay(0.4)
	t.tween_callback(l.queue_free)


func _flash(node: CanvasItem) -> void:
	var t := node.create_tween()
	t.tween_property(node, "modulate", Color(1.8, 0.6, 0.6), 0.12)
	t.tween_property(node, "modulate", Color.WHITE, 0.4)
