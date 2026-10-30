extends PanelContainer
## Settings from 1.4: volume, captions, brightness, and reduced scares.

@onready var master: HSlider = $Box/Master/Slider
@onready var music: HSlider = $Box/Music/Slider
@onready var sfx: HSlider = $Box/Effects/Slider
@onready var brightness: HSlider = $Box/Brightness/Slider
@onready var captions: CheckButton = $Box/Captions
@onready var reduced: CheckButton = $Box/ReducedScares
@onready var low_graphics: CheckButton = $Box/LowGraphics
@onready var control_hints: CheckButton = $Box/ControlHints
@onready var seed_edit: LineEdit = $Box/Seed/Edit
@onready var back: Button = $Box/Back


func _ready() -> void:
	Settings.ensure_loaded()
	master.value = Settings.master_volume
	music.value = Settings.music_volume
	sfx.value = Settings.sfx_volume
	brightness.value = Settings.brightness
	captions.button_pressed = Settings.captions
	reduced.button_pressed = Settings.reduced_scares
	low_graphics.button_pressed = Settings.low_graphics
	control_hints.button_pressed = Settings.control_hints
	seed_edit.text = Settings.test_seed
	master.value_changed.connect(func(v): Settings.master_volume = v; Settings.apply_audio())
	music.value_changed.connect(func(v): Settings.music_volume = v; Settings.apply_audio())
	sfx.value_changed.connect(func(v): Settings.sfx_volume = v; Settings.apply_audio())
	brightness.value_changed.connect(func(v): Settings.brightness = v)
	captions.toggled.connect(func(on): Settings.captions = on)
	reduced.toggled.connect(func(on): Settings.reduced_scares = on)
	low_graphics.toggled.connect(func(on): Settings.low_graphics = on)
	control_hints.toggled.connect(func(on): Settings.control_hints = on)
	seed_edit.text_changed.connect(func(t): Settings.test_seed = t)
	back.pressed.connect(close)


func open() -> void:
	# The night scene may have turned low graphics on by itself.
	low_graphics.set_pressed_no_signal(Settings.low_graphics)
	visible = true
	master.grab_focus()


func close() -> void:
	Settings.save()
	Sfx.play(self, "click")
	visible = false
