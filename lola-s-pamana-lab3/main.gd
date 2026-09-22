extends Node2D

# Lab 3: minimal core loop for "Lola's Pamana"
# Input -> Action -> Feedback -> repeat.
#   INSPECT (L) reads the ledger and reveals whether the customer matches it.
#   SERVE (S) or REFUSE (R) ends the encounter and the next customer arrives.
#
# No visible countdown. Tension comes from doubt and sound, not a clock,
# to fit slow-burn horror instead of a reflex game.

const GAP := 2.0                # pause between customers
const START_PESOS := 150
const START_SANITY := 100

# One data table for the encounters. is_entity is hidden from the player.
# The ledger line is what Lola's notebook says this regular always buys.
const CUSTOMERS := [
	{"name": "Aling Nena", "order": "sinigang mix", "ledger": "sinigang mix", "is_entity": false},
	{"name": "Mang Ador", "order": "yosi", "ledger": "yosi", "is_entity": false},
	{"name": "Aling Nena", "order": "coffee sachet", "ledger": "sinigang mix", "is_entity": true},
	{"name": "Kuya Migo", "order": "pandesal", "ledger": "pandesal", "is_entity": false},
	{"name": "Mang Ador", "order": "candle", "ledger": "yosi", "is_entity": true},
	{"name": "Aling Bebang", "order": "soy sauce", "ledger": "soy sauce", "is_entity": false},
]

var index := 0
var pesos := START_PESOS
var sanity := START_SANITY
var correct := 0
var total := 0
var inspected := false
var waiting := false        # true during the gap between customers
var gap_left := 0.0

@onready var customer_rect: TextureRect = $UI/CustomerWindow/Customer
@onready var name_label: Label = $UI/NameLabel
@onready var clue_label: Label = $UI/ClueLabel
@onready var result_label: Label = $UI/ResultLabel
@onready var stats_label: Label = $UI/StatsLabel
@onready var prompt_label: Label = $UI/PromptLabel


func _ready() -> void:
	_ensure_actions()
	_start_customer()


# Safety net: if the Input Map actions are missing, register them at runtime
# so the build still runs. Normally they come from Project Settings.
func _ensure_actions() -> void:
	var keys := {"inspect": KEY_L, "serve": KEY_S, "refuse": KEY_R}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev := InputEventKey.new()
			ev.physical_keycode = keys[action]
			InputMap.action_add_event(action, ev)


func _process(delta: float) -> void:
	if waiting:
		gap_left -= delta
		if gap_left <= 0.0:
			_start_customer()
		return

	if Input.is_action_just_pressed("inspect"):
		_inspect()
	elif Input.is_action_just_pressed("serve"):
		_resolve("serve")
	elif Input.is_action_just_pressed("refuse"):
		_resolve("refuse")


# --- the loop ----------------------------------------------------------------

func _start_customer() -> void:
	waiting = false
	inspected = false

	var c: Dictionary = CUSTOMERS[index % CUSTOMERS.size()]
	name_label.text = "%s asks for %s" % [c["name"], c["order"]]
	clue_label.text = "Press L to read Lola's ledger."
	result_label.text = ""
	# hidden until the player checks the ledger
	customer_rect.visible = false
	customer_rect.modulate = Color(1, 1, 1, 1)
	customer_rect.scale = Vector2.ONE
	prompt_label.text = "L  read ledger        S  serve        R  refuse"
	_update_stats()


func _inspect() -> void:
	var c: Dictionary = CUSTOMERS[index % CUSTOMERS.size()]
	inspected = true
	if c["order"] == c["ledger"]:
		clue_label.text = "Ledger: %s always buys %s. The order matches." % [c["name"], c["ledger"]]
	else:
		clue_label.text = "Ledger: %s always buys %s. This one asked for %s." % [c["name"], c["ledger"], c["order"]]

	# pop up from behind the counter
	customer_rect.visible = true
	customer_rect.scale = Vector2(0.7, 0.7)
	customer_rect.modulate = Color(1, 0.97, 0.85, 1)  # light warm cue: "ledger checked"
	var tween := create_tween()
	tween.tween_property(customer_rect, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _resolve(decision: String) -> void:
	var c: Dictionary = CUSTOMERS[index % CUSTOMERS.size()]
	var is_entity: bool = c["is_entity"]
	total += 1

	match decision:
		"serve":
			if is_entity:
				sanity -= 30
				result_label.text = "It took the item and smiled with too many teeth.  Sanity -30"
			else:
				pesos += 20
				correct += 1
				result_label.text = "%s pays and walks home.  Pesos +20" % c["name"]
		"refuse":
			if is_entity:
				correct += 1
				result_label.text = "The shutter drops. Something scratches the iron once, then leaves."
			else:
				sanity -= 10
				result_label.text = "You shut out a real neighbor.  Sanity -10"

	if not inspected:
		result_label.text += "\nYou never opened the ledger."

	# duck back below the counter on any decision
	customer_rect.visible = false

	prompt_label.text = "..."
	_update_stats()

	index += 1
	waiting = true
	gap_left = GAP

	if sanity <= 0:
		_reset_run()


func _reset_run() -> void:
	result_label.text = "SANITY BROKE. The night resets."
	pesos = START_PESOS
	sanity = START_SANITY
	correct = 0
	total = 0
	index = 0


func _update_stats() -> void:
	stats_label.text = "Pesos %d      Sanity %d      Correct calls %d of %d" % [
		pesos, sanity, correct, total
	]
