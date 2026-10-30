extends Sprite2D
## The UV-only layer. Draws the folklore sign on the face and the leaves in the
## cash. Its shader shows them only inside the UV beam, and only after the
## beam has rested on that spot for 2 seconds (Section II and Table 22).

var face_sign := ""
var face_revealed := false
var has_leaves := false
var cash_revealed := false
var anchors: Dictionary = {}
var cash_pos := Vector2.ZERO
var _time := 0.0


func setup(sign_name: String, leaves: bool, face_anchors: Dictionary, money_pos: Vector2) -> void:
	face_sign = sign_name
	has_leaves = leaves
	anchors = face_anchors
	cash_pos = money_pos
	face_revealed = false
	cash_revealed = false
	_set_revealed(0.0)
	queue_redraw()


## Returns true when a tell shows. A clean spot shows nothing.
func reveal(spot: String) -> bool:
	if spot == "face" and face_sign != "" and not face_revealed:
		face_revealed = true
	elif spot == "cash" and has_leaves and not cash_revealed:
		cash_revealed = true
	else:
		return false
	_set_revealed(1.0)
	queue_redraw()
	return true


func _set_revealed(v: float) -> void:
	var mat := material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("revealed", v)


func _process(delta: float) -> void:
	_time += delta
	var mat := material as ShaderMaterial
	if mat == null:
		return
	var beam := get_tree().get_first_node_in_group("uv_beam")
	if beam:
		mat.set_shader_parameter("beam_pos", beam.global_position)
		mat.set_shader_parameter("beam_radius", beam.radius)
		mat.set_shader_parameter("beam_on", 1.0 if beam.lit else 0.0)
	if face_revealed or cash_revealed:
		queue_redraw()


func _draw() -> void:
	# An invisible pixel, so the UV shader is ready before the first customer.
	draw_rect(Rect2(0, 0, 1, 1), Color(0, 0, 0, 0))
	if face_revealed and anchors.size() > 0:
		match face_sign:
			"aswang":
				_draw_fangs()
				_draw_stitches()
			"tiktik":
				_draw_red_eyes()
			"kapre":
				_draw_cigar()
			"manananggal":
				_draw_split()
	if cash_revealed:
		_draw_leaves()


func _glow(p: Vector2, r: float, c: Color) -> void:
	for i in range(5, 0, -1):
		draw_circle(p, r * (1.0 + i * 0.7), Color(c.r, c.g, c.b, 0.06 * (6 - i)))
	draw_circle(p, r, c)


func _draw_red_eyes() -> void:
	var pulse := 0.8 + 0.2 * sin(_time * 6.0)
	_glow(anchors["eye_l"], 5.0, Color(1.0, 0.1, 0.05, pulse))
	_glow(anchors["eye_r"], 5.0, Color(1.0, 0.1, 0.05, pulse))


func _draw_fangs() -> void:
	var m: Vector2 = anchors["mouth"]
	var c := Color(0.95, 0.95, 1.0)
	for dx in [-7.0, 7.0]:
		var tip := m + Vector2(dx, 14)
		draw_colored_polygon(PackedVector2Array([m + Vector2(dx - 4, 0), m + Vector2(dx + 4, 0), tip]), c)
		_glow(tip, 1.5, Color(0.8, 0.2, 1.0, 0.8))


func _draw_stitches() -> void:
	var n: Vector2 = anchors["neck"]
	var half: float = anchors["width"] * 0.13
	var col := Color(0.85, 0.2, 1.0)
	draw_line(n - Vector2(half, 0), n + Vector2(half, 0), col, 2.5)
	var steps := 7
	for i in range(steps + 1):
		var x := -half + 2.0 * half * i / steps
		draw_line(n + Vector2(x - 3, -5), n + Vector2(x + 3, 5), col, 2.0)
	_glow(n, 3.0, Color(0.8, 0.2, 1.0, 0.35))


func _draw_cigar() -> void:
	var start: Vector2 = anchors["mouth"] + Vector2(6, 2)
	var end := start + Vector2(34, -6)
	draw_line(start, end, Color(0.45, 0.25, 0.1), 6.0)
	var flicker := 0.75 + 0.25 * sin(_time * 11.0)
	_glow(end, 4.5, Color(1.0, 0.45, 0.05, flicker))
	for i in 3:
		var off := Vector2(4 + i * 5, -10 - i * 14 + sin(_time * 2.0 + i) * 3)
		draw_circle(end + off, 4 + i * 2, Color(0.8, 0.8, 1.0, 0.25 - i * 0.06))


func _draw_split() -> void:
	var y: float = anchors["waist"].y
	var half: float = anchors["width"] * 0.42
	var pts := PackedVector2Array()
	var steps := 12
	for i in range(steps + 1):
		var x := -half + 2.0 * half * i / steps
		pts.append(Vector2(x, y + (8.0 if i % 2 == 0 else -8.0)))
	draw_polyline(pts, Color(1.0, 0.15, 0.2), 4.0)
	draw_polyline(pts, Color(1.0, 0.6, 0.6, 0.5), 9.0)


func _draw_leaves() -> void:
	var leaf := func(p: Vector2, rot: float, s: float):
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			# Pointed at both ends like a dry leaf.
			var w := 4.5 * pow(absf(sin(a)), 0.8)
			pts.append(Vector2(cos(a) * 12.0, sin(a) * w) * s)
		var xf := Transform2D(rot, p)
		draw_colored_polygon(xf * pts, Color(0.62, 0.88, 0.3, 1.0))
		draw_polyline(xf * pts, Color(0.22, 0.38, 0.1), 1.0, true)
		draw_line(xf * Vector2(-12 * s, 0), xf * Vector2(12 * s, 0), Color(0.22, 0.38, 0.1), 1.0)
	leaf.call(cash_pos + Vector2(-16, -2), 0.4, 1.6)
	leaf.call(cash_pos + Vector2(12, 5), -0.6, 1.4)
	leaf.call(cash_pos + Vector2(2, -9), 1.2, 1.2)
	_glow(cash_pos, 3.0, Color(0.6, 1.0, 0.4, 0.25))
