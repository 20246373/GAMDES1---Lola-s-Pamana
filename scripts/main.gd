extends Node
## The only scene that loads at start. It holds nothing but the pause menu.
## Every screen is its own scene file, loaded only when it is shown and freed
## when the player leaves it, so just one screen is ever in memory (8.4).
## The current screen is added as a child of Main with its Figure 8 name.

const SCREENS := {
	"MainMenu": "res://scenes/main_menu.tscn",
	"DayPhase": "res://scenes/day_phase.tscn",
	"NightCounter": "res://scenes/counter.tscn",
	"DawnReport": "res://scenes/dawn_report.tscn",
	"EndScreen": "res://scenes/end_screen.tscn",
}

@onready var pause_menu: CanvasLayer = $PauseMenu

var active := ""
var _screen: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().physics_object_picking = true
	Settings.ensure_loaded()
	GameState.night_lost.connect(_on_night_lost)
	GameState.game_finished.connect(_on_game_finished)
	pause_menu.pause_toggled.connect(_on_pause_toggled)
	pause_menu.menu_button.pressed.connect(_on_pause_main_menu)
	_show_menu()


## One action covers every menu, the loss screen, and the dawn report, so
## each screen works without the mouse (Table 21).
func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed("confirm") or event.is_action_pressed("chat")):
		return
	var f := get_viewport().gui_get_focus_owner()
	if f is BaseButton and f.is_visible_in_tree() and not f.disabled:
		get_viewport().set_input_as_handled()
		if f.toggle_mode:
			f.button_pressed = not f.button_pressed
		else:
			f.pressed.emit()


func _activate(screen: String) -> Node:
	# Free the screen being left before loading the next one.
	if _screen:
		remove_child(_screen)
		_screen.queue_free()
		_screen = null
	active = screen
	pause_menu.allowed = screen in ["DayPhase", "NightCounter", "DawnReport"]
	_screen = load(SCREENS[screen]).instantiate()
	_screen.name = screen
	_screen.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_screen)
	# Keep the pause menu listed last, above the screen.
	move_child(_screen, 0)
	return _screen


func _show_menu() -> void:
	get_tree().paused = false
	pause_menu.set_paused(false)
	var menu := _activate("MainMenu")
	menu.new_game_requested.connect(_on_play)
	menu.continue_requested.connect(_on_continue)


func _on_play(slot: int) -> void:
	Sfx.play(self, "click")
	var s := -1
	if Settings.test_seed.strip_edges().is_valid_int():
		s = int(Settings.test_seed.strip_edges())
	GameState.new_run(s, slot)
	_go_day()


func _on_continue(slot: int) -> void:
	Sfx.play(self, "click")
	match GameState.continue_run(slot):
		"day":
			_go_day()
		"night":
			_go_night()
		_:
			# The slot could not be read, so stay on the menu.
			_show_menu()


func _go_day() -> void:
	var day := _activate("DayPhase")
	day.day_finished.connect(_on_day_finished)


## Table 22: day_finished. The night counter loads, the 6 PM checkpoint is
## saved, and Presence resets to 0.
func _on_day_finished() -> void:
	GameState.start_night()
	_go_night()


func _go_night() -> void:
	var counter := _activate("NightCounter")
	counter.night_survived.connect(_on_night_survived)


## Table 22: night_survived. The dawn report loads.
func _on_night_survived() -> void:
	var t := create_tween()
	t.tween_interval(1.5)
	t.tween_callback(func():
		GameState.dawn()
		var report := _activate("DawnReport")
		report.next_button.pressed.connect(_on_report_next)
	)


func _on_report_next() -> void:
	Sfx.play(self, "click")
	if GameState.night >= GameState.LAST_NIGHT:
		GameState.finish_game()
	else:
		GameState.next_day()
		_go_day()


## Table 22: game_finished. Win state.
func _on_game_finished(ending: String) -> void:
	var end := _activate("EndScreen")
	end.show_mode(ending)
	end.menu_button.pressed.connect(_on_end_menu)


## Table 22: night_lost. Lose state.
func _on_night_lost(reason: String) -> void:
	if active != "NightCounter":
		return
	var end := _activate("EndScreen")
	end.show_mode(reason)
	end.retry_button.pressed.connect(_on_retry)
	end.menu_button.pressed.connect(_on_end_menu)


func _on_retry() -> void:
	Sfx.play(self, "click")
	GameState.retry_night()
	_go_night()


func _on_end_menu() -> void:
	Sfx.play(self, "click")
	_show_menu()


## Table 22: pause_toggled. The scene tree pauses.
func _on_pause_toggled(paused: bool) -> void:
	get_tree().paused = paused


func _on_pause_main_menu() -> void:
	_show_menu()
