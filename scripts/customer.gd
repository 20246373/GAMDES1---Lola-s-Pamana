extends Node2D
## One customer at the grille, built from one row of the data table.
## Listens to customer_arrived, uv_hit, and call_resolved (Table 22).

## Longest side of the served item as it pops up, in screen pixels.
const ITEM_POP_SIZE := 120.0

@onready var body: Sprite2D = $Body
@onready var sign_layer: Sprite2D = $SignLayer
@onready var cash: Sprite2D = $Cash
@onready var voice: AudioStreamPlayer2D = $Voice
@onready var anim: AnimationPlayer = $Anim

## Driven by the "talk" animation. 1 shows the talking sprite.
var talk_frame: int = 0:
	set(value):
		talk_frame = value
		_apply_talk_frame()

var data: Dictionary = {}
var _idle_tex: Texture2D
var _talk_tex: Texture2D
var _scale := 1.0
var _body_pos := Vector2.ZERO
var _tween: Tween


func _ready() -> void:
	visible = false


func _apply_talk_frame() -> void:
	if body == null:
		return
	if _talk_tex != null:
		body.texture = _talk_tex if talk_frame == 1 else _idle_tex
	else:
		# No talking version yet, such as Mang Ador. Bob gently instead.
		body.position = _body_pos + Vector2(0, -3 if talk_frame == 1 else 0)


## Table 22: the next customer appears.
func _on_customer_arrived(c: Dictionary) -> void:
	data = c
	_kill_tween()
	_setup_look()
	modulate = Color(1, 1, 1, 0)
	position = Vector2(0, 26)
	visible = true
	# Behind the shutter, the grille, and the store art.
	z_index = -5
	body.z_index = 0
	var anchors := _anchors()
	sign_layer.setup(c["face_tell"], c["cash_tell"], anchors, cash.position)
	cash.set_money(int(c["payment"]))
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 1.1)
	_tween.parallel().tween_property(self, "position:y", 0.0, 1.1).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_speak)
	Sfx.play(self, "footsteps", -10.0)


func _speak() -> void:
	voice.stream = load("res://audio/voice.wav")
	voice.play()
	anim.play("talk")
	var t := create_tween()
	t.tween_interval(2.2)
	t.tween_callback(func(): anim.stop(); talk_frame = 0)


func _setup_look() -> void:
	var look: Dictionary = CustomerData.LOOKS[data["look"]]
	_idle_tex = load(look["tex"])
	_talk_tex = load(look["talk"]) if look["talk"] != "" else null
	var k := float(_idle_tex.get_width()) / float(look["src"])
	var bbox: Rect2 = look["bbox"]
	_scale = look["height"] / bbox.size.y
	var flip := false
	var tint := Color.WHITE
	if data["look"] == "stranger":
		var v: Dictionary = CustomerData.STRANGER_VARIANTS[int(data.get("variant", 0)) % CustomerData.STRANGER_VARIANTS.size()]
		flip = v["flip"]
		tint = v["tint"]
	var face_x: float = bbox.position.x + look["eyes"].x * bbox.size.x
	body.texture = _idle_tex
	body.centered = false
	body.flip_h = flip
	body.scale = Vector2.ONE * (_scale / k)
	var x0: float = -face_x * _scale
	if flip:
		x0 = -(look["src"] - face_x) * _scale
	_body_pos = Vector2(x0, -bbox.end.y * _scale)
	body.position = _body_pos
	body.modulate = tint
	talk_frame = 0


## Face anchor points in this node's space, used to draw the UV signs.
func _anchors() -> Dictionary:
	var look: Dictionary = CustomerData.LOOKS[data["look"]]
	var bbox: Rect2 = look["bbox"]
	var face_x: float = bbox.position.x + look["eyes"].x * bbox.size.x
	var flip: bool = data["look"] == "stranger" and CustomerData.STRANGER_VARIANTS[int(data.get("variant", 0)) % CustomerData.STRANGER_VARIANTS.size()]["flip"]
	var p := func(frac: Vector2) -> Vector2:
		var x: float = (bbox.position.x + frac.x * bbox.size.x - face_x) * _scale
		if flip:
			x = -x
		return Vector2(x, (bbox.position.y + frac.y * bbox.size.y - bbox.end.y) * _scale)
	var gap: float = look["eye_gap"] * bbox.size.x * _scale
	var eyes: Vector2 = p.call(look["eyes"])
	return {
		"eye_l": eyes - Vector2(gap, 0), "eye_r": eyes + Vector2(gap, 0),
		"mouth": p.call(look["mouth"]), "neck": p.call(look["neck"]),
		"width": bbox.size.x * _scale, "waist": Vector2(0, -16),
	}


## Spot tests for the UV beam. "face" covers the whole figure in the window.
func uv_spot_at(world_pos: Vector2) -> String:
	if not visible or data.is_empty() or modulate.a < 0.5:
		return ""
	for spot in ["cash", "face"]:
		if uv_spot_rect(spot).has_point(world_pos):
			return spot
	return ""


## The scan area of a spot, in canvas coordinates. The face area covers the
## whole figure in the window.
func uv_spot_rect(spot: String) -> Rect2:
	if spot == "cash":
		return Rect2(cash.global_position - Vector2(46, 22), Vector2(92, 44))
	var look: Dictionary = CustomerData.LOOKS[data.get("look", "stranger")]
	var w: float = look["bbox"].size.x * _scale
	var h: float = look["height"]
	return Rect2(global_position + Vector2(-w * 0.5, -h), Vector2(w, h))


## Who is being scanned, so scan results reset for the next customer.
func uv_subject_id() -> String:
	return data.get("id", "")


## What a finished scan found, for the beam and the HUD.
func uv_result(spot: String) -> Dictionary:
	if spot == "face":
		if sign_layer.face_revealed:
			# The manananggal's sign is at the waist, not on the face.
			var where := "Body: " if sign_layer.face_sign == "manananggal" else "Face: "
			return {"kind": "tell", "text": where + CustomerData.SIGNS[sign_layer.face_sign]}
		return {"kind": "clean", "text": "Face: nothing strange"}
	if sign_layer.cash_revealed:
		return {"kind": "tell", "text": "Cash: turned into leaves"}
	return {"kind": "clean", "text": "Cash: real money"}


## Table 22: after 2 seconds on one spot, a folklore sign or leaf cash shows.
func _on_uv_hit(spot: String) -> void:
	if data.is_empty() or not visible:
		return
	if sign_layer.reveal(spot):
		Sfx.play(self, "reveal", -4.0)


## Table 22: the customer leaves, collapses into leaves, or triggers a jump scare.
func _on_call_resolved(result: Dictionary) -> void:
	if data.is_empty():
		return
	_kill_tween()
	anim.stop()
	talk_frame = 0
	var entity: bool = data["is_entity"]
	match result["decision"]:
		"serve":
			cash.set_money(0)
			if entity:
				_jump_scare()
			else:
				_show_item()
				_leave(1.4, 0.6)
		"serve_utang":
			_nod()
			_leave(1.2, 0.7)
		"refuse":
			_leave(0.5, 0.5)
		"banish":
			if entity:
				_collapse()
			else:
				_flinch()
				_leave(1.0, 0.9)


func _leave(delay: float, duration: float) -> void:
	_tween = create_tween()
	_tween.tween_interval(delay)
	_tween.tween_property(self, "modulate:a", 0.0, duration)
	_tween.tween_callback(_clear)


func _clear() -> void:
	visible = false
	data = {}
	cash.set_money(0)
	sign_layer.setup("", false, {}, cash.position)


func _show_item() -> void:
	var icon := Sprite2D.new()
	icon.texture = load(CustomerData.ITEMS[data["order"]]["icon"])
	# The item art sits small in a wide canvas, so crop to the drawn part.
	var img := icon.texture.get_image()
	if img.is_compressed():
		img.decompress()
	var used := img.get_used_rect()
	if used.size.x > 0 and used.size.y > 0:
		icon.region_enabled = true
		icon.region_rect = Rect2(used)
	var size := Vector2(used.size) if icon.region_enabled else icon.texture.get_size()
	var full := Vector2.ONE * (ITEM_POP_SIZE / maxf(size.x, size.y))
	icon.scale = full * 0.6
	# On the slot, not the customer, so it stays in view while they walk off.
	icon.position = position + cash.position + Vector2(-30, 0)
	icon.z_index = 12
	get_parent().add_child(icon)
	var t := icon.create_tween()
	t.tween_property(icon, "scale", full, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(icon, "position:y", icon.position.y - 80, 1.0).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.6)
	t.tween_property(icon, "modulate:a", 0.0, 0.6)
	t.tween_callback(icon.queue_free)


func _nod() -> void:
	var t := create_tween()
	t.tween_property(body, "position:y", _body_pos.y + 6, 0.15)
	t.tween_property(body, "position:y", _body_pos.y, 0.15)


func _flinch() -> void:
	Sfx.play(self, "salt", -2.0)
	var t := create_tween()
	for i in 4:
		t.tween_property(body, "position:x", _body_pos.x + (8 if i % 2 == 0 else -8), 0.05)
	t.tween_property(body, "position:x", _body_pos.x, 0.05)


func _show_true_form(height: float, center: Vector2) -> void:
	var kind: String = data["entity_type"]
	var info: Dictionary = CustomerData.TRUE_FORM_BBOX[kind]
	var tex: Texture2D = load(CustomerData.TRUE_FORMS[kind])
	var k := float(tex.get_width()) / float(info["src"])
	var bbox: Rect2 = info["bbox"]
	var s := height / bbox.size.y
	body.texture = tex
	body.flip_h = false
	body.modulate = Color(1, 1, 1)
	body.scale = Vector2.ONE * (s / k)
	body.position = center - Vector2(bbox.get_center().x * s, bbox.end.y * s)


## Serving an entity: lose 30 Sanity and get a jump scare (Table 4).
func _jump_scare() -> void:
	var reduced := Settings.reduced_scares
	z_index = 60
	sign_layer.setup("", false, {}, cash.position)
	_show_true_form(300.0, Vector2(0, 0))
	body.modulate = Color(2.2, 1.6, 1.6)
	Sfx.play(self, "scare", -8.0 if reduced else 0.0)
	var target_scale := body.scale * (1.4 if reduced else 2.3)
	var shift := Vector2(0, 0) if reduced else Vector2(0, 280)
	_tween = create_tween()
	_tween.tween_property(body, "scale", target_scale, 0.18 if not reduced else 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "position", shift, 0.18 if not reduced else 0.5)
	_tween.tween_interval(0.9)
	_tween.tween_property(self, "modulate:a", 0.0, 0.6)
	_tween.tween_callback(_clear)


## A correct Banish: a shriek, then the entity collapses into dry leaves.
func _collapse() -> void:
	Sfx.play(self, "shriek", -3.0 if not Settings.reduced_scares else -10.0)
	_show_true_form(330.0, Vector2(0, 0))
	body.modulate = Color(1.6, 1.4, 1.8)
	sign_layer.setup("", false, {}, cash.position)
	cash.set_money(0)
	_tween = create_tween()
	_tween.tween_interval(0.7)
	_tween.tween_callback(_spawn_leaves)
	_tween.tween_property(body, "modulate", Color(0.5, 0.35, 0.15, 0.0), 0.8)
	_tween.tween_interval(0.4)
	_tween.tween_callback(_clear)


func _spawn_leaves() -> void:
	Sfx.play(self, "leaves", -4.0)
	var p := CPUParticles2D.new()
	p.amount = 70
	p.lifetime = 1.6
	p.one_shot = true
	p.explosiveness = 0.85
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(70, 120)
	p.position = Vector2(0, -150)
	p.direction = Vector2(0, 1)
	p.spread = 60.0
	p.gravity = Vector2(0, 260)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 140.0
	p.angular_velocity_min = -220.0
	p.angular_velocity_max = 220.0
	p.scale_amount_min = 5.0
	p.scale_amount_max = 9.0
	p.color = Color(0.55, 0.38, 0.14)
	p.z_index = 12
	add_child(p)
	p.emitting = true
	var t := p.create_tween()
	t.tween_interval(2.2)
	t.tween_callback(p.queue_free)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
