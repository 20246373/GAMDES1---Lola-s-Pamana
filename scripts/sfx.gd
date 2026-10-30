class_name Sfx
extends RefCounted
## Plays a one-shot sound as a child of the given node, so it pauses with it.

const DIR := "res://audio/"

## Captions shown for sounds that matter to play (Section IX and 1.4).
const CAPTIONS := {
	"tiktik": "A tik-tik bird calls from the street.",
	"whispers": "Whispers drift in from the fog.",
	"static": "The radio crackles into static.",
	"shriek": "A shriek at the grille.",
	"scare": "A scream.",
	"bell": "The 6 AM church bell rings.",
	"heartbeat": "Your heart thumps.",
	"spark": "The salt line sparks.",
	"shutter": "The shutter slams down.",
}


static func play(owner: Node, sound: String, volume_db: float = 0.0, bus: String = "SFX", pitch: float = 1.0) -> AudioStreamPlayer:
	if owner == null or not is_instance_valid(owner) or not owner.is_inside_tree():
		return null
	var stream: AudioStream = load(DIR + sound + ".wav")
	if stream == null:
		return null
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = volume_db
	p.pitch_scale = pitch
	owner.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p


static func caption_for(sound: String) -> String:
	return CAPTIONS.get(sound, "")
