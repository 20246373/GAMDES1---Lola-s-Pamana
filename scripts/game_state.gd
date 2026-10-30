extends Node
## Autoload. Holds the six resources, the correct calls, and the night number,
## and sends a signal whenever one of them changes. It is the only node that
## changes a resource (Sections 8.4 and 8.5). Other nodes read its values and
## ask it for changes through the signals in Table 22 or the request methods
## below. All numbers come from Section II, Table 4, and Section VI.

signal resource_changed(resource: String, value: float, delta: float)
signal presence_changed(value: int)
signal night_lost(reason: String)
signal game_finished(ending: String)

# Starting values, Section II Procedures.
const START_PESOS := 70
const START_SANITY := 100
const START_BATTERY := 100.0
const START_SALT := 3
const START_PRESENCE := 0
const START_UTANG := 0

const MAX_SANITY := 100
const MAX_BATTERY := 100.0
const MAX_SALT := 6
const BREACH_AT := 3
const BATTERY_PACK := 50.0
const SALABAT := 10
const DAWN_REST := 25
const BATTERY_DRAIN_PER_SECOND := 2.0
const RADIO_DRAIN_EVERY := 30.0
const UTANG_PER_NIGHT := 2
const UTANG_FEE := 5
const CHATS_PER_DAY := 2
const LAST_NIGHT := 5
const TOTAL_CALLS := 30

# Table 4.
const SERVE_ENTITY_SANITY := -30
const WRONG_REFUSE_SANITY := -10
const WRONG_BANISH_SANITY := -20
const CORRECT_BANISH_SANITY := 5

# Retry floor, 6.4.
const FLOOR_SALT := 3
const FLOOR_BATTERY := 70.0
const FLOOR_SANITY := 50

# Endings, Section II Outcome.
const GOOD_SANITY := 60
const GOOD_CALLS := 24

## Three save slots, numbered 1 to 3. Each slot is one file under user://.
const SLOT_COUNT := 3
const SAVE_VERSION := 2
## The single-file checkpoint from before save slots existed. Moved into the
## first empty slot the first time the game starts.
const LEGACY_SAVE_PATH := "user://checkpoint.save"
const REQUIRED_SAVE_KEYS := ["night", "pesos", "sanity", "battery", "salt", "debts",
	"correct_calls", "known", "returning", "call_log", "seed"]
const LOSS_DELAY := 1.8

var pesos: int = START_PESOS
var sanity: int = START_SANITY
var battery: float = START_BATTERY
var salt: int = START_SALT
var presence: int = START_PRESENCE
## Open debts. Each is {key, name, amount, night, is_entity}.
var debts: Array = []
var correct_calls: int = 0
## The current day and night number, 1 to 5.
var night: int = 1
var chats_left: int = CHATS_PER_DAY
## Regular ids whose personal detail is written in the ledger.
var known: Dictionary = {}
## Entities served on utang. They return the next night.
var returning: Array = []
## Every call made this run. Calls of a lost night are removed on retry.
var call_log: Array = []
var run_seed: int = 0
var plan: Dictionary = {}
## Tonight's customers, built from the data table at 6 PM.
var tonight: Array = []
var radio_on: bool = true
var night_running: bool = false
var utang_used: int = 0
var sanity_before_rest: int = START_SANITY
var last_report: Dictionary = {}
var ending: String = ""

## The slot (1 to 3) this run saves into. -1 means no slot, so nothing is saved.
var current_slot: int = -1

var _drain_clock := 0.0
var _checkpoint: Dictionary = {}
var _lost := false


func _ready() -> void:
	Settings.ensure_loaded()
	_migrate_legacy_save()


func _process(delta: float) -> void:
	# Radio off: Sanity drops 1 every 30 seconds. The tree pause stops this.
	if not night_running or radio_on or _lost:
		return
	_drain_clock += delta
	while _drain_clock >= RADIO_DRAIN_EVERY:
		_drain_clock -= RADIO_DRAIN_EVERY
		_change_sanity(-1)
		_check_loss()


# --- runs and days ------------------------------------------------------------

## Starts a fresh run in the given save slot (1 to 3). Whatever the slot held
## before is overwritten, and the new run is saved at once so the slot shows up.
func new_run(seed_value: int = -1, slot: int = -1) -> void:
	if seed_value < 0:
		seed_value = _pick_seed()
	current_slot = slot
	_checkpoint = {}
	run_seed = seed_value
	plan = CustomerData.make_plan(run_seed)
	pesos = START_PESOS
	sanity = START_SANITY
	battery = START_BATTERY
	salt = START_SALT
	presence = START_PRESENCE
	debts = []
	correct_calls = 0
	night = 1
	known = {}
	returning = []
	call_log = []
	tonight = []
	ending = ""
	last_report = {}
	_lost = false
	start_day()
	_write_slot("day", _snapshot())


func _pick_seed() -> int:
	if Settings.test_seed.strip_edges().is_valid_int():
		return int(Settings.test_seed.strip_edges())
	return randi() % 1000000


func start_day() -> void:
	chats_left = CHATS_PER_DAY


func utang_total() -> int:
	var total := 0
	for d in debts:
		total += int(d["amount"])
	return total


func can_buy(item_id: String) -> bool:
	var price := _catalogue_price(item_id)
	if pesos < price:
		return false
	match item_id:
		"salt":
			return salt < MAX_SALT
		"battery":
			return battery < MAX_BATTERY
		"salabat":
			return sanity < MAX_SANITY
	return false


## Day catalogue. Battery packs and salabat take effect when bought.
func buy(item_id: String) -> bool:
	if not can_buy(item_id):
		return false
	_change_pesos(-_catalogue_price(item_id))
	match item_id:
		"salt":
			_set_salt(salt + 1)
		"battery":
			_set_battery(min(MAX_BATTERY, battery + BATTERY_PACK))
		"salabat":
			_change_sanity(SALABAT)
	return true


func _catalogue_price(item_id: String) -> int:
	for entry in CustomerData.CATALOGUE:
		if entry["id"] == item_id:
			return entry["price"]
	return 9999


## A day chat. Each chat adds the regular's one personal detail to the ledger.
func chat(regular_id: String) -> bool:
	if chats_left <= 0:
		return false
	chats_left -= 1
	known[regular_id] = true
	return true


# --- nights -------------------------------------------------------------------

## 6 PM. Save the checkpoint and set Presence to 0 (Table 22, day_finished).
func start_night() -> void:
	_lost = false
	_set_presence(0)
	utang_used = 0
	_drain_clock = 0.0
	radio_on = true
	night_running = false
	_save_checkpoint()
	tonight = CustomerData.build_night(night, plan, known, returning)
	returning = []


## The counter calls this when the shutter is first raised and the clock starts.
func set_night_running(running: bool) -> void:
	night_running = running


func can_utang() -> bool:
	return night < LAST_NIGHT and utang_used < UTANG_PER_NIGHT


func utang_lines_left() -> int:
	return 0 if night >= LAST_NIGHT else UTANG_PER_NIGHT - utang_used


## Holding the UV lamp drains 2% per second.
func drain_battery(amount: float) -> void:
	if amount <= 0.0 or battery <= 0.0:
		return
	_set_battery(max(0.0, battery - amount))


## A returning entity's unpaid debt clears from the ledger when it returns.
func clear_debt(key: String) -> void:
	var before := utang_total()
	debts = debts.filter(func(d): return d["key"] != key)
	if utang_total() != before:
		resource_changed.emit("utang", utang_total(), utang_total() - before)


func is_lost() -> bool:
	return _lost


## Connected to Radio.radio_toggled (Table 22).
func _on_radio_toggled(on: bool) -> void:
	radio_on = on


## Connected to Counter.call_resolved (Table 22). Applies Table 4.
func _on_call_resolved(result: Dictionary) -> void:
	if _lost:
		return
	var c: Dictionary = result["customer"]
	var decision: String = result["decision"]
	var entity: bool = c["is_entity"]
	match decision:
		"serve":
			if entity:
				_change_sanity(SERVE_ENTITY_SANITY)
			else:
				_change_pesos(int(c["price"]))
		"serve_utang":
			utang_used += 1
			var amount: int = int(c["price"]) + UTANG_FEE
			var key: String = c.get("debt_key", c["id"])
			debts.append({"key": key, "name": c["name"], "amount": amount, "night": night, "is_entity": entity})
			resource_changed.emit("utang", utang_total(), amount)
			if entity:
				var back := c.duplicate(true)
				back["debt_key"] = key
				returning.append(back)
		"refuse":
			if entity:
				_set_presence(presence + 1)
			else:
				_change_sanity(WRONG_REFUSE_SANITY)
		"banish":
			_set_salt(salt - 1)
			if entity:
				_change_sanity(CORRECT_BANISH_SANITY)
			else:
				_change_sanity(WRONG_BANISH_SANITY)
	if result["correct"]:
		correct_calls += 1
		resource_changed.emit("correct_calls", correct_calls, 1)
	call_log.append({
		"night": night, "name": c["name"], "decision": decision, "correct": result["correct"],
		"clue": result.get("clue", ""), "is_entity": entity, "item": c["item_name"],
		"entity_type": c.get("entity_type", ""),
	})
	_check_loss()


func _check_loss() -> void:
	if _lost:
		return
	var reason := ""
	if sanity <= 0:
		reason = "breakdown"
	elif presence >= BREACH_AT:
		reason = "breach"
	if reason == "":
		return
	_lost = true
	night_running = false
	# Let the jump scare or the shutter play before the loss screen.
	get_tree().create_timer(LOSS_DELAY, false).timeout.connect(func(): night_lost.emit(reason))


## Called by Main when Counter emits night_survived. Judge the outcome first,
## then reset Presence, collect repaid debts, and add 25 Sanity (Section II).
func dawn() -> Dictionary:
	night_running = false
	sanity_before_rest = sanity
	var calls := call_log.filter(func(e): return e["night"] == night)
	var right := calls.filter(func(e): return e["correct"]).size()
	_set_presence(0)
	var repaid: Array = []
	var keep: Array = []
	for d in debts:
		if not d["is_entity"]:
			repaid.append(d)
		else:
			keep.append(d)
	debts = keep
	var repaid_total := 0
	for d in repaid:
		repaid_total += int(d["amount"])
	if repaid_total > 0:
		_change_pesos(repaid_total)
		resource_changed.emit("utang", utang_total(), -repaid_total)
	_change_sanity(DAWN_REST)
	last_report = {
		"night": night,
		"calls": calls,
		"correct_tonight": right,
		"star": right == calls.size() and calls.size() > 0,
		"correct_total": correct_calls,
		"sanity_before": sanity_before_rest,
		"sanity_after": sanity,
		"pesos": pesos,
		"repaid": repaid,
		"repaid_total": repaid_total,
		"page": Story.page_for(night),
		"last": night >= LAST_NIGHT,
		"saved_slot": -1,
	}
	# Auto-save: the night is finished, so store the start of the next day.
	if _autosave_next_day():
		last_report["saved_slot"] = current_slot
	return last_report


func next_day() -> void:
	night += 1
	start_day()


## After the Night 5 dawn report. Win state (Table 22, game_finished).
func finish_game() -> void:
	if sanity_before_rest >= GOOD_SANITY and correct_calls >= GOOD_CALLS:
		ending = "good"
	else:
		ending = "bittersweet"
	# The run is over, so its slot is freed for a new game.
	delete_slot(current_slot)
	game_finished.emit(ending)


# --- checkpoint and save slots ------------------------------------------------

func _snapshot() -> Dictionary:
	return {
		"night": night, "pesos": pesos, "sanity": sanity, "battery": battery, "salt": salt,
		"debts": debts.duplicate(true), "correct_calls": correct_calls, "known": known.duplicate(),
		"returning": returning.duplicate(true), "call_log": call_log.duplicate(true), "seed": run_seed,
	}


## 6 PM. Keeps the checkpoint in memory for Retry and in the slot for Continue.
func _save_checkpoint() -> void:
	_checkpoint = _snapshot()
	_write_slot("night", _checkpoint)


## Auto-save after a night is survived. The slot holds the start of the next
## day, so Continue returns to the day phase with the dawn rest and repaid utang
## already counted. Nothing is saved after Night 5, because the game is over.
func _autosave_next_day() -> bool:
	if current_slot < 1 or night >= LAST_NIGHT:
		return false
	var snap := _snapshot()
	snap["night"] = night + 1
	return _write_slot("day", snap)


func slot_path(slot: int) -> String:
	return "user://save_slot_%d.save" % slot


## phase is "day" (the next screen is the day phase) or "night" (the 6 PM
## checkpoint, the next screen is the night counter).
func _write_slot(phase: String, snap: Dictionary) -> bool:
	if current_slot < 1 or current_slot > SLOT_COUNT:
		return false
	return _write_slot_file(current_slot, phase, snap)


func _write_slot_file(slot: int, phase: String, snap: Dictionary) -> bool:
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save slot %d." % slot)
		return false
	f.store_var({
		"version": SAVE_VERSION,
		"phase": phase,
		"saved_at": Time.get_unix_time_from_system(),
		"state": snap,
	})
	f.close()
	return true


## Reads and checks one slot. Returns {} when the slot is empty or damaged.
func read_slot(slot: int) -> Dictionary:
	if slot < 1 or slot > SLOT_COUNT or not FileAccess.file_exists(slot_path(slot)):
		return {}
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var data = f.get_var()
	f.close()
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("state")) != TYPE_DICTIONARY:
		return {}
	if not (data.get("phase", "") in ["day", "night"]):
		return {}
	for key in REQUIRED_SAVE_KEYS:
		if not data["state"].has(key):
			return {}
	return data


## What the slot picker shows for a slot. {} means the slot is empty.
func slot_info(slot: int) -> Dictionary:
	var data := read_slot(slot)
	if data.is_empty():
		return {}
	var st: Dictionary = data["state"]
	return {
		"night": int(st["night"]),
		"phase": data["phase"],
		"pesos": int(st["pesos"]),
		"sanity": int(st["sanity"]),
		"correct_calls": int(st["correct_calls"]),
		"saved_at": float(data.get("saved_at", 0.0)),
	}


func slot_has_save(slot: int) -> bool:
	return not read_slot(slot).is_empty()


func has_saved_run() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if slot_has_save(slot):
			return true
	return false


func delete_slot(slot: int) -> void:
	if slot < 1 or slot > SLOT_COUNT:
		return
	if FileAccess.file_exists(slot_path(slot)):
		DirAccess.remove_absolute(slot_path(slot))
	if slot == current_slot:
		current_slot = -1


func _migrate_legacy_save() -> void:
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return
	var f := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	var cp = null
	if f:
		cp = f.get_var()
		f.close()
	var valid: bool = typeof(cp) == TYPE_DICTIONARY
	if valid:
		for key in REQUIRED_SAVE_KEYS:
			if not cp.has(key):
				valid = false
	if valid:
		for slot in range(1, SLOT_COUNT + 1):
			if not slot_has_save(slot):
				_write_slot_file(slot, "night", cp)
				DirAccess.remove_absolute(LEGACY_SAVE_PATH)
				return
		return  # Every slot is taken. Keep the old file for now.
	DirAccess.remove_absolute(LEGACY_SAVE_PATH)


func _restore(cp: Dictionary) -> void:
	night = cp["night"]
	run_seed = cp["seed"]
	plan = CustomerData.make_plan(run_seed)
	pesos = cp["pesos"]
	sanity = cp["sanity"]
	battery = cp["battery"]
	salt = cp["salt"]
	debts = cp["debts"].duplicate(true)
	correct_calls = cp["correct_calls"]
	known = cp["known"].duplicate()
	returning = cp["returning"].duplicate(true)
	call_log = cp["call_log"].duplicate(true)
	_lost = false
	ending = ""


## Main menu Continue. Loads the chosen slot and returns where the player
## resumes: "day", "night", or "" if the slot could not be loaded.
func continue_run(slot: int) -> String:
	var data := read_slot(slot)
	if data.is_empty():
		return ""
	current_slot = slot
	_checkpoint = {}
	_restore(data["state"])
	presence = START_PRESENCE
	tonight = []
	last_report = {}
	if data["phase"] == "night":
		start_night()  # Builds the night and saves the 6 PM checkpoint again.
		return "night"
	start_day()
	return "day"


## Retry after a Breakdown or Breach. Restores every resource and the call
## count to 6 PM, then raises anything below the retry floor (6.4).
func retry_night() -> void:
	_restore(_checkpoint)
	salt = max(salt, FLOOR_SALT)
	battery = max(battery, FLOOR_BATTERY)
	sanity = max(sanity, FLOOR_SANITY)
	_lost = false
	_set_presence(0)
	utang_used = 0
	_drain_clock = 0.0
	radio_on = true
	night_running = false
	tonight = CustomerData.build_night(night, plan, known, returning)
	returning = []
	for r in ["pesos", "sanity", "battery", "salt", "utang"]:
		resource_changed.emit(r, get_resource(r), 0)


func get_resource(r: String) -> float:
	match r:
		"pesos": return pesos
		"sanity": return sanity
		"battery": return battery
		"salt": return salt
		"presence": return presence
		"utang": return utang_total()
		"correct_calls": return correct_calls
	return 0


# --- the only setters ---------------------------------------------------------

func _change_pesos(delta: int) -> void:
	pesos += delta
	resource_changed.emit("pesos", pesos, delta)


func _change_sanity(delta: int) -> void:
	var before := sanity
	sanity = clampi(sanity + delta, 0, MAX_SANITY)
	resource_changed.emit("sanity", sanity, sanity - before)


func _set_battery(value: float) -> void:
	var before := battery
	battery = clampf(value, 0.0, MAX_BATTERY)
	resource_changed.emit("battery", battery, battery - before)


func _set_salt(value: int) -> void:
	var before := salt
	salt = clampi(value, 0, MAX_SALT)
	resource_changed.emit("salt", salt, salt - before)


func _set_presence(value: int) -> void:
	presence = max(0, value)
	presence_changed.emit(presence)
	resource_changed.emit("presence", presence, 0)
