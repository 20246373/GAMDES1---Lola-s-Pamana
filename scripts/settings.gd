class_name Settings
extends RefCounted
## Player settings from 1.4: volume, captions, brightness, and reduced scares.
## Saved to user://settings.cfg.

const PATH := "user://settings.cfg"

static var master_volume: float = 0.8
static var music_volume: float = 0.7
static var sfx_volume: float = 0.9
static var captions: bool = true
## 1.0 is the default night. Higher raises the lowest light level (8.2).
static var brightness: float = 1.0
## Turns off camera sway and softens jump scares and lamp flicker.
static var reduced_scares: bool = false
## Turns off the 2D lights and the fog, which cost the most on slow GPUs such
## as Chromebooks. On by default. Turn it off on a strong PC for full lighting.
## The night turns it back on by itself if frames start to lag.
static var low_graphics: bool = true
## Short hints and key labels on screen. The GDD teaches through the level
## alone (5.4), so players can turn these off.
static var control_hints: bool = true
## Testers can enter a seed to repeat a bug (6.4). Empty means a new seed.
static var test_seed: String = ""
static var _loaded := false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		master_volume = cfg.get_value("audio", "master", master_volume)
		music_volume = cfg.get_value("audio", "music", music_volume)
		sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
		captions = cfg.get_value("display", "captions", captions)
		brightness = cfg.get_value("display", "brightness", brightness)
		reduced_scares = cfg.get_value("display", "reduced_scares", reduced_scares)
		low_graphics = cfg.get_value("display", "graphics_quality", "low") == "low"
		control_hints = cfg.get_value("display", "control_hints", control_hints)
		test_seed = cfg.get_value("testing", "seed", test_seed)
	apply_audio()


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "captions", captions)
	cfg.set_value("display", "brightness", brightness)
	cfg.set_value("display", "reduced_scares", reduced_scares)
	cfg.set_value("display", "graphics_quality", "low" if low_graphics else "full")
	cfg.set_value("display", "control_hints", control_hints)
	cfg.set_value("testing", "seed", test_seed)
	cfg.save(PATH)
	apply_audio()


static func apply_audio() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)


static func _set_bus(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(value, 0.0001)))
	AudioServer.set_bus_mute(idx, value <= 0.001)
