extends CanvasLayer
## Pause menu. Esc, P, or the on-screen Pause button toggles it during the day,
## the night, and the dawn report (Table 21).
## Emits pause_toggled (Table 22). Main pauses the scene tree, which stops the
## night clock and the Sanity drain.

signal pause_toggled(paused: bool)

@onready var root: Control = $Root
@onready var resume_button: Button = $Root/Menu/Resume
@onready var how_button: Button = $Root/Menu/HowToPlay
@onready var how_panel: PanelContainer = $Root/HowToPlayPanel
@onready var settings_button: Button = $Root/Menu/Settings
@onready var menu_button: Button = $Root/Menu/MainMenu
@onready var settings_panel: PanelContainer = $Root/SettingsPanel
@onready var seed_label: Label = $Root/Seed
@onready var pause_button: Button = $PauseButton

## Set by Main. Pausing is allowed only during play and the dawn report.
var allowed := false:
	set(value):
		allowed = value
		_update_pause_button()
var paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	settings_panel.visible = false
	how_panel.visible = false
	resume_button.pressed.connect(toggle)
	how_button.pressed.connect(how_panel.open)
	how_panel.visibility_changed.connect(func(): if not how_panel.visible and paused: how_button.grab_focus())
	settings_button.pressed.connect(func(): settings_panel.open())
	settings_panel.visibility_changed.connect(func(): if not settings_panel.visible and paused: settings_button.grab_focus())
	pause_button.pressed.connect(toggle)
	_update_pause_button()


## The on-screen Pause button shows whenever pausing is allowed and the game
## is not already paused.
func _update_pause_button() -> void:
	if is_node_ready():
		pause_button.visible = allowed and not paused


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and allowed:
		get_viewport().set_input_as_handled()
		if settings_panel.visible:
			settings_panel.close()
			return
		if how_panel.visible:
			how_panel.close()
			return
		toggle()


func toggle() -> void:
	set_paused(not paused)


func set_paused(value: bool) -> void:
	if paused == value:
		return
	paused = value
	root.visible = paused
	_update_pause_button()
	settings_panel.visible = false
	how_panel.visible = false
	seed_label.text = "Run seed %d" % GameState.run_seed
	if paused:
		resume_button.grab_focus()
	Sfx.play(self, "click")
	pause_toggled.emit(paused)
