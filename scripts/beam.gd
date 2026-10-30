extends Area2D
## The UV beam. After 2 seconds on one spot it emits uv_hit (Table 22).
## Spots come from nodes in the "uv_target" group: the customer's face and
## cash, and the open ledger page.
## It also draws everything the player needs to see without sound: the beam,
## a box around the spot being scanned, a progress ring, and the result.
## All of it is unshaded, so it shows through the night darkness.

signal uv_hit(spot: String)

const DWELL := 2.0
const POPUP_TIME := 2.6
const VIOLET := Color(0.78, 0.6, 1.0)
const CLEAN := Color(0.55, 1.0, 0.6)
const TELL := Color(1.0, 0.35, 0.35)
const WARN := Color(1.0, 0.8, 0.3)
const NAMES := {"face": "face", "cash": "cash", "ledger": "ledger page"}

@export var radius := 85.0
var lit := false
## Set by the UV lamp while the store is open.
var active := false

var _spot := ""
var _target: Node
var _dwell := 0.0
var _fired := false
var _hover_spot := ""
var _hover_target: Node
## Scan results for each customer id: {spot: {"kind": String, "text": String}}.
var _findings := {}
var _popups: Array = []
var _was_busy := false


func _ready() -> void:
	add_to_group("uv_beam")
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = m
	z_as_relative = false
	z_index = 40


## Results for one customer, for the HUD's scan list.
func findings_for(id: String) -> Dictionary:
	return _findings.get(id, {})


func _process(delta: float) -> void:
	var spot := ""
	var target: Node = null
	if active:
		for n in get_tree().get_nodes_in_group("uv_target"):
			if not n.has_method("uv_spot_at"):
				continue
			var s: String = n.uv_spot_at(global_position)
			if s != "":
				spot = s
				target = n
				break
	_hover_spot = spot
	_hover_target = target
	if lit:
		if spot != _spot or target != _target:
			_spot = spot
			_target = target
			_dwell = 0.0
			_fired = _already_scanned(spot, target)
		elif spot != "" and not _fired:
			_dwell += delta
			if _dwell >= DWELL:
				_fire()
	else:
		_spot = ""
		_target = null
		_dwell = 0.0
		_fired = false
	for p in _popups:
		p["time"] -= delta
	_popups = _popups.filter(func(p): return p["time"] > 0.0)
	# Redraw only while something is on screen or just changed.
	var busy := lit or not _popups.is_empty() or _hover_target != null
	if busy or _was_busy:
		queue_redraw()
	_was_busy = busy


func _already_scanned(spot: String, target: Node) -> bool:
	if spot == "" or target == null:
		return false
	return findings_for(target.uv_subject_id()).has(spot)


func _fire() -> void:
	_fired = true
	Sfx.play(self, "scan_done", -6.0)
	uv_hit.emit(_spot)
	# The customer or ledger has revealed its tell by now, so read the result.
	var result: Dictionary = _target.uv_result(_spot)
	var id: String = _target.uv_subject_id()
	if not _findings.has(id):
		_findings[id] = {}
	_findings[id][_spot] = result
	var r: Rect2 = _target.uv_spot_rect(_spot)
	_popups.append({"pos": Vector2(r.get_center().x, r.position.y - 6), "text": result["text"],
		"kind": result["kind"], "time": POPUP_TIME})


func _kind_color(kind: String) -> Color:
	match kind:
		"tell":
			return TELL
		"warn":
			return WARN
	return CLEAN


func _draw() -> void:
	# Draw in canvas coordinates.
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	var at := global_position
	if active and _hover_target and not lit:
		# Show what can be scanned under the mouse.
		_dashed_rect(_hover_target.uv_spot_rect(_hover_spot), Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.8))
		if Settings.control_hints:
			_tag(at + Vector2(0, 46), "Hold right click, Space, or click to scan", VIOLET, 14)
	if lit:
		Glow.draw(self, at, radius, Color(0.6, 0.35, 1.0, 0.3))
		draw_arc(at, radius, 0, TAU, 48, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.9), 2.0)
		if _target:
			var r: Rect2 = _target.uv_spot_rect(_spot)
			var col := VIOLET
			if _fired:
				var res: Dictionary = findings_for(_target.uv_subject_id()).get(_spot, {})
				col = _kind_color(res.get("kind", "clean"))
			draw_rect(r, col, false, 3.0)
			if not _fired:
				var frac := clampf(_dwell / DWELL, 0.0, 1.0)
				draw_arc(at, 26, -PI / 2, -PI / 2 + TAU, 40, Color(0, 0, 0, 0.6), 7.0)
				draw_arc(at, 26, -PI / 2, -PI / 2 + TAU * frac, 40, VIOLET, 5.0)
				_tag(at + Vector2(0, 52), "Scanning the %s..." % NAMES.get(_spot, _spot), VIOLET, 15)
		else:
			_tag(at + Vector2(0, 52), "Point at a face, cash, or the ledger", VIOLET, 14)
	for p in _popups:
		var a := clampf(p["time"] / 0.5, 0.0, 1.0)
		var col := _kind_color(p["kind"])
		_tag(p["pos"], p["text"], Color(col.r, col.g, col.b, a), 17, a)


## A text tag on a dark plate, centred on pos.
func _tag(pos: Vector2, text: String, col: Color, size: int, alpha := 1.0) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var base := pos - Vector2(w * 0.5, 0)
	var plate := Rect2(base + Vector2(-8, -size - 2), Vector2(w + 16, size + 12))
	draw_rect(plate, Color(0.04, 0.03, 0.06, 0.9 * alpha))
	draw_rect(plate, Color(col.r, col.g, col.b, 0.9 * alpha), false, 1.5)
	draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1, 1, 1, alpha))


func _dashed_rect(r: Rect2, col: Color) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var length := a.distance_to(b)
		var d := 0.0
		while d < length:
			draw_line(a.lerp(b, d / length), a.lerp(b, minf(d + 10.0, length) / length), col, 2.0)
			d += 18.0
