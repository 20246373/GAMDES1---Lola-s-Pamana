extends Control
## Save slot picker. Opens after Play ("new") and after Continue ("continue").
## Three slots, each with a Delete button. Overwriting or deleting asks first.

signal slot_chosen(slot: int, mode: String)
signal closed

@onready var heading: Label = $Panel/Box/Heading
@onready var rows: VBoxContainer = $Panel/Box/Slots
@onready var hint: Label = $Panel/Box/Hint
@onready var back: Button = $Panel/Box/Back
@onready var confirm_panel: PanelContainer = $Confirm
@onready var confirm_text: Label = $Confirm/Box/Text
@onready var confirm_yes: Button = $Confirm/Box/Buttons/Yes
@onready var confirm_no: Button = $Confirm/Box/Buttons/No

var mode := "new"
var _slot_buttons: Array = []
var _delete_buttons: Array = []
var _pending: Callable = Callable()


func _ready() -> void:
	back.pressed.connect(close)
	confirm_no.pressed.connect(_close_confirm)
	confirm_yes.pressed.connect(_on_confirm_yes)
	confirm_panel.visible = false
	_build_rows()


func open(open_mode: String) -> void:
	mode = open_mode
	Sfx.play(self, "click")
	if mode == "continue":
		heading.text = "Continue"
		hint.text = "Choose a saved game. Progress saves by itself after every night you survive."
	else:
		heading.text = "Choose a Save Slot"
		hint.text = "Pick an empty slot to start. Picking a used slot starts over in it."
	_close_confirm()
	_refresh()
	visible = true
	_focus_first()


func close() -> void:
	Sfx.play(self, "click")
	_hide()
	closed.emit()


func _hide() -> void:
	confirm_panel.visible = false
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if confirm_panel.visible:
			_close_confirm()
		else:
			close()


func _build_rows() -> void:
	for slot in range(1, GameState.SLOT_COUNT + 1):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var pick := Button.new()
		pick.custom_minimum_size = Vector2(0, 86)
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.alignment = HORIZONTAL_ALIGNMENT_LEFT
		pick.focus_mode = Control.FOCUS_ALL
		pick.pressed.connect(_on_slot_pressed.bind(slot))
		var del := Button.new()
		del.custom_minimum_size = Vector2(110, 86)
		del.text = "Delete"
		del.focus_mode = Control.FOCUS_ALL
		del.pressed.connect(_on_delete_pressed.bind(slot))
		row.add_child(pick)
		row.add_child(del)
		rows.add_child(row)
		_slot_buttons.append(pick)
		_delete_buttons.append(del)


func _refresh() -> void:
	for i in GameState.SLOT_COUNT:
		var slot := i + 1
		var info := GameState.slot_info(slot)
		var pick: Button = _slot_buttons[i]
		var del: Button = _delete_buttons[i]
		if info.is_empty():
			pick.text = "Slot %d\nEmpty" % slot
			pick.disabled = mode == "continue"
			del.disabled = true
		else:
			pick.text = "Slot %d    %s\nPesos %d    Sanity %d    Correct calls %d of %d\nSaved %s" % [
				slot, _where(info), info["pesos"], info["sanity"], info["correct_calls"],
				GameState.TOTAL_CALLS, _stamp(info["saved_at"])]
			pick.disabled = false
			del.disabled = false


func _where(info: Dictionary) -> String:
	if info["phase"] == "night":
		return "Night %d, 6 PM" % info["night"]
	return "Day %d" % info["night"]


func _stamp(unix: float) -> String:
	if unix <= 0.0:
		return "unknown"
	# Saved times are UTC. Shift them to the player's clock.
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))
	return Time.get_datetime_string_from_unix_time(int(unix) + bias * 60, true).substr(0, 16)


func _focus_first() -> void:
	for b in _slot_buttons:
		if not b.disabled:
			b.grab_focus()
			return
	back.grab_focus()


func _on_slot_pressed(slot: int) -> void:
	Sfx.play(self, "click")
	if mode == "continue":
		_choose(slot)
		return
	if GameState.slot_has_save(slot):
		_ask("Slot %d already has a game. Start a new game and erase it?" % slot, _choose.bind(slot), slot)
	else:
		_choose(slot)


func _on_delete_pressed(slot: int) -> void:
	Sfx.play(self, "click")
	_ask("Delete Slot %d? This cannot be undone." % slot, _delete.bind(slot), slot)


func _choose(slot: int) -> void:
	_hide()
	slot_chosen.emit(slot, mode)


func _delete(slot: int) -> void:
	GameState.delete_slot(slot)
	_refresh()
	_focus_first()


func _ask(text: String, action: Callable, slot: int) -> void:
	_pending = action
	confirm_text.text = text
	confirm_panel.visible = true
	confirm_no.grab_focus()


func _on_confirm_yes() -> void:
	Sfx.play(self, "click")
	var action := _pending
	_pending = Callable()
	confirm_panel.visible = false
	if action.is_valid():
		action.call()


func _close_confirm() -> void:
	_pending = Callable()
	if confirm_panel.visible:
		confirm_panel.visible = false
		_focus_first()
