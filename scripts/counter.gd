extends Node2D
## The night scene. Holds the store, the street, the lights, and every counter
## tool (Figure 8). Runs one night of up to 300 seconds from 6 PM to 6 AM, with
## the clock running in real time. Customers arrive one at a time. The next one
## walks up a few seconds after the current one leaves, or a little later when
## a street event plays in the gap. After the last customer leaves, the clock
## runs fast to the 6 AM bell (Section II). Every decision is checked against
## the customer's data row and the Table 4 result goes to GameState.

signal customer_arrived(customer: Dictionary)
signal warning_played(sound: String, caption: String)
signal call_resolved(result: Dictionary)
signal night_survived

const NIGHT_LENGTH := 300.0
## 3 AM is 9 game hours after 6 PM.
const THREE_AM := 225.0
## Seconds between one customer leaving and the next walking up.
const WALK_UP := 3.0
## A gap with a street event is long enough for the event to play out.
const EVENT_START := 1.0
const EVENT_GAP := 6.0
## The Night 3 silence holds the street empty a little longer.
const SILENCE_GAP := 8.0
## How many times faster than real time the clock runs when it skips ahead.
const CLOCK_SKIP_SPEED := 40.0
const WARNING_DELAY := 2.5
const WARNING_REPEAT := 10.0
## How long each reaction plays before the grille is empty again.
const LEAVE_TIME := {"serve": 2.2, "serve_entity": 2.8, "serve_utang": 2.0, "refuse": 1.4, "banish": 2.6}

const NIGHT_DUSK := Color(0.42, 0.4, 0.55)
const NIGHT_DEEP := Color(0.17, 0.18, 0.3)

@onready var camera: Camera2D = $Camera2D
@onready var darkness: CanvasModulate = $Darkness
@onready var street: Sprite2D = $Street
@onready var customer: Node2D = $CustomerSlot/Customer
@onready var desk_lamp: PointLight2D = $DeskLamp
@onready var uv_lamp: PointLight2D = $UVLamp
@onready var ledger: Control = $Ledger
@onready var cash_drawer: Area2D = $CashDrawer
@onready var salt_jar: Area2D = $SaltJar
@onready var shutter_rope: Area2D = $ShutterRope
@onready var radio: Area2D = $Radio
@onready var night_clock: Timer = $NightClock
@onready var arrival_timer: Timer = $ArrivalTimer
@onready var hud: CanvasLayer = $HUD

var night := 1
var schedule: Array = []
var next_index := 0
var current: Dictionary = {}
var resolving := false
var opened := false
var finished := false
var radio_on := true

var _warn_clock := 0.0
var _warned_once := false
var _beat_running := false
var _silence_done := false
var _silence := false
var _bell_rung := false
## The clock runs fast until it reaches this time, or not at all when negative.
var _skip_to := -1.0
var _rng := RandomNumberGenerator.new()
var _wind: AudioStreamPlayer


func _ready() -> void:
	if not can_process():
		# A hidden placeholder in Main. It starts nothing.
		return
	night = GameState.night
	schedule = GameState.tonight
	_rng.seed = GameState.run_seed + night * 977
	# Table 22 wiring to the autoload. The scene file wires the rest.
	radio.radio_toggled.connect(GameState._on_radio_toggled)
	call_resolved.connect(GameState._on_call_resolved)
	night_clock.wait_time = NIGHT_LENGTH
	_preload_tonight()
	# At 6 PM only the rope is ready to use.
	shutter_rope.highlight.available = true
	darkness.color = _night_color(0.0)
	shutter_rope.shutter.amount = 1.0
	shutter_rope.shutter_down = true
	radio_on = true
	GameState._on_radio_toggled(true)
	_start_wind()


## Load every texture tonight's customers need while the shutter is still
## down at 6 PM, so nothing loads in the middle of an encounter.
var _cache: Array = []


func _preload_tonight() -> void:
	for c in schedule:
		var look: Dictionary = CustomerData.LOOKS[c["look"]]
		_cache.append(load(look["tex"]))
		if look["talk"] != "":
			_cache.append(load(look["talk"]))
		if c["is_entity"]:
			_cache.append(load(CustomerData.TRUE_FORMS[c["entity_type"]]))
		_cache.append(load(CustomerData.ITEMS[c["order"]]["icon"]))


# --- time ---------------------------------------------------------------------

func elapsed() -> float:
	if not opened:
		return 0.0
	if night_clock.is_stopped():
		return NIGHT_LENGTH
	return NIGHT_LENGTH - night_clock.time_left


## Runs the night clock fast toward _skip_to by taking time off the timer.
func _tick_clock_skip(delta: float) -> void:
	if _skip_to < 0.0:
		return
	var left := NIGHT_LENGTH - _skip_to
	var next_left := maxf(left, night_clock.time_left - delta * (CLOCK_SKIP_SPEED - 1.0))
	if next_left <= left:
		_skip_to = -1.0
	night_clock.start(maxf(next_left, 0.01))


## Game time shown on the HUD. 6 PM to 6 AM over 300 seconds.
func clock_text() -> String:
	var e := elapsed()
	if e >= NIGHT_LENGTH and not finished:
		e = NIGHT_LENGTH - 1.0
	var minutes := int(18 * 60 + e / NIGHT_LENGTH * 12 * 60) % (24 * 60)
	var h := int(minutes / 60.0)
	var m := minutes % 60
	var suffix := "AM" if h < 12 else "PM"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m, suffix]


func _night_color(e: float) -> Color:
	# The scene darkens as the night goes on (M2).
	var c := NIGHT_DUSK.lerp(NIGHT_DEEP, clampf(e / 120.0, 0.0, 1.0))
	var b := Settings.brightness
	if b >= 1.0:
		c = c.lerp(Color(0.75, 0.75, 0.85), clampf((b - 1.0) * 0.8, 0.0, 0.8))
	else:
		c = c * b
	if Settings.low_graphics:
		# No desk lamp light, so lift the darkness a little.
		c = c.lerp(NIGHT_DUSK, 0.7)
	c.a = 1.0
	return c


func _process(delta: float) -> void:
	darkness.color = _night_color(elapsed())
	# A slight sway that follows the mouse by up to 8 pixels (Table 20).
	var target := Vector2.ZERO
	if not Settings.reduced_scares:
		var vp := get_viewport_rect().size
		var m := get_viewport().get_mouse_position()
		target = ((m - vp / 2.0) / (vp / 2.0)).clamp(Vector2(-1, -1), Vector2(1, 1)) * 8.0
	camera.offset = camera.offset.lerp(target, clampf(delta * 3.0, 0.0, 1.0))
	_check_frame_rate(delta)
	if not opened or finished or GameState.is_lost():
		return
	_tick_clock_skip(delta)
	_tick_warnings(delta)
	_check_end()


## With full lighting on, five slow frames in a row switch to low graphics,
## so a weak GPU never stays stuck. The first seconds are skipped, because
## loading the scene always makes a few frames slow.
var _slow_frames := 0
var _settle := 2.0


func _check_frame_rate(delta: float) -> void:
	if Settings.low_graphics:
		return
	if _settle > 0.0:
		_settle -= delta
		return
	_slow_frames = _slow_frames + 1 if delta > 0.1 else 0
	if _slow_frames >= 5:
		Settings.low_graphics = true
		Settings.save()


# --- opening and arrivals ----------------------------------------------------

func _open_store() -> void:
	if opened:
		return
	opened = true
	shutter_rope.highlight.available = false
	shutter_rope.raise_shutter()
	uv_lamp.active = true
	night_clock.start(NIGHT_LENGTH)
	GameState.set_night_running(true)
	_spawn_next()


func _spawn_next() -> void:
	if next_index >= schedule.size() or not current.is_empty():
		return
	if finished or GameState.is_lost() or _bell_rung:
		return
	# Night 2: the radio cuts to static before customer 2 (5.4).
	if night == 2 and next_index == 1 and not _beat_running and not _warned_once:
		_run_static_beat()
		return
	var c: Dictionary = schedule[next_index]
	next_index += 1
	current = c
	resolving = false
	_warn_clock = WARNING_DELAY
	if _silence:
		_end_silence()
	shutter_rope.raise_shutter()
	if c.get("returning", false):
		GameState.clear_debt(c.get("debt_key", ""))
	cash_drawer.highlight_first = c.get("teach", "") == "first_serve"
	customer_arrived.emit(c)
	# The decision tools glow once the customer has stepped up.
	var ready_tween := create_tween()
	ready_tween.tween_interval(1.2)
	ready_tween.tween_callback(func(): if current == c and not resolving: _set_tools_available(true))
	if c.get("teach", "") == "first_entity":
		var t := create_tween()
		t.tween_interval(4.0)
		t.tween_callback(salt_jar.spark_line)


func _schedule_next() -> void:
	if next_index >= schedule.size():
		return
	if _silence:
		arrival_timer.start(SILENCE_GAP)
		return
	# The Night 2 static beat fills the gap before customer 2 by itself.
	var beat_next := night == 2 and next_index == 1
	# Every Night 1 gap holds one street event (5.3). Later nights have them
	# sometimes. The gap is longer only when an event plays in it.
	if not beat_next and (night == 1 or _rng.randf() < 0.4):
		arrival_timer.start(EVENT_GAP)
		var t := create_tween()
		t.tween_interval(EVENT_START)
		t.tween_callback(_play_street_event)
	else:
		arrival_timer.start(WALK_UP)


func _on_arrival_timer_timeout() -> void:
	if current.is_empty() and not _beat_running:
		_spawn_next()


# --- decisions ----------------------------------------------------------------

## Table 22: decision_made from CashDrawer, UtangPen, ShutterRope, and SaltJar.
func _on_decision_made(decision: String) -> void:
	if decision == "open":
		_open_store()
		return
	if current.is_empty() or resolving or finished or GameState.is_lost():
		return
	if customer.modulate.a < 0.6:
		return
	match decision:
		"serve_utang":
			if not GameState.can_utang():
				return
		"banish":
			if GameState.salt <= 0:
				return
	resolving = true
	_set_tools_available(false)
	var c := current
	var entity: bool = c["is_entity"]
	var correct: bool = (decision in ["serve", "serve_utang"]) != entity
	var result := {
		"decision": decision,
		"customer": c,
		"correct": correct,
		"clue": CustomerData.clue_for(c, decision),
	}
	match decision:
		"serve":
			cash_drawer.play_open()
		"refuse":
			shutter_rope.drop_shutter()
		"banish":
			salt_jar.pour()
			desk_lamp.flicker()
	call_resolved.emit(result)
	var key := decision
	if decision == "serve" and entity:
		key = "serve_entity"
	var t := create_tween()
	t.tween_interval(LEAVE_TIME[key])
	t.tween_callback(_customer_left)


func _customer_left() -> void:
	current = {}
	resolving = false
	cash_drawer.highlight_first = false
	if next_index >= schedule.size():
		# Nothing is left to do tonight, so the clock runs fast to 6 AM.
		_skip_to = NIGHT_LENGTH
		return
	if night == 3 and next_index == 5 and not _silence_done:
		_start_silence()
	_schedule_next()


func _check_end() -> void:
	# The bell rings at 6 AM and ends the night (Rule 5). Customers who have
	# not arrived are skipped. One already at the grille is still decided.
	if finished or elapsed() < NIGHT_LENGTH:
		return
	if not _bell_rung:
		_bell_rung = true
		arrival_timer.stop()
		Sfx.play(self, "bell")
	if not current.is_empty():
		return
	finished = true
	GameState.set_night_running(false)
	uv_lamp.active = false
	night_survived.emit()


## Soft glow on the objects that decide a customer, while a decision is open.
func _set_tools_available(on: bool) -> void:
	cash_drawer.highlight.available = on
	salt_jar.highlight.available = on and GameState.salt > 0
	shutter_rope.highlight.available = on
	ledger.utang_pen.highlight.available = on and ledger.is_open and GameState.can_utang()


# --- warnings -----------------------------------------------------------------

## Table 22: radio_toggled. Warnings are heard only with the radio off.
func _on_radio_toggled(on: bool) -> void:
	radio_on = on
	if not on:
		_warn_clock = min(_warn_clock, 1.5)


func _tick_warnings(delta: float) -> void:
	if current.is_empty() or resolving or _silence or radio_on:
		return
	if not current.get("warned", false):
		return
	_warn_clock -= delta
	if _warn_clock <= 0.0:
		_warn_clock = WARNING_REPEAT
		_play_warning(current)


func _play_warning(c: Dictionary) -> void:
	var sound := "tiktik" if c.get("entity_type", "") == "tiktik" else ("whispers" if _rng.randf() < 0.5 else "tiktik")
	Sfx.play(self, sound, -2.0)
	warning_played.emit(sound, Sfx.caption_for(sound))


## Night 2, the gap before customer 2. The radio cuts to static by itself. In
## the silence the tik-tik bird calls with a caption and a lamp flicker. The
## radio comes back and the next customer is the first tiktik (5.4).
func _run_static_beat() -> void:
	if _beat_running or _warned_once:
		return
	_beat_running = true
	_warned_once = true
	radio.force_static(5.5)
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		Sfx.play(self, "tiktik", -1.0)
		warning_played.emit("tiktik", Sfx.caption_for("tiktik"))
	)
	t.tween_interval(3.5)
	t.tween_callback(func():
		_beat_running = false
		if current.is_empty():
			_spawn_next()
	)


## Night 3: at 3 AM or when customer 5 leaves, whichever is later, the radio,
## the street, and the tik-tik bird all cut out until the next customer. If
## customer 5 leaves before 3 AM, the clock runs fast to 3 AM in the silence.
func _start_silence() -> void:
	_silence = true
	_silence_done = true
	radio.set_silenced(true)
	if is_instance_valid(_wind):
		_wind.stop()
	if elapsed() < THREE_AM:
		_skip_to = THREE_AM


## One street event in a gap between customers. Visual or a plain street sound,
## never a warning (Table 17).
func _play_street_event() -> void:
	if not current.is_empty() or _silence or finished:
		return
	match _rng.randi_range(0, 3):
		0:
			street.shadow_pass(_rng.randf() < 0.5)
			Sfx.play(self, "footsteps", -10.0)
		1:
			desk_lamp.dim(1.0)
		2:
			street.shadow_pass(_rng.randf() < 0.5)
		3:
			Sfx.play(self, "dog", -14.0)
			desk_lamp.dim(0.6)


func _end_silence() -> void:
	_silence = false
	radio.set_silenced(false)
	_start_wind()


## Street ambience, looped. It stops during the 3 AM silence.
func _start_wind() -> void:
	if _silence or finished:
		return
	_wind = Sfx.play(self, "wind", -18.0)
	if _wind:
		_wind.finished.connect(_start_wind)
