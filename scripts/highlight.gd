class_name Highlight
extends Node2D
## A glowing outline and a name tag around a clickable counter object.
## It is unshaded, so it shows through the night darkness and Low graphics.
## It glows brightly on hover, softly while the object can be used, and red
## while it asks for a second click.

static var _material: CanvasItemMaterial

## The outline, in the parent's local space.
@export var rect := Rect2(-20, -20, 40, 40)
## Name shown above the outline on hover, for example "Serve [S]".
@export var label := ""

var hovered := false:
	set(value):
		if hovered != value:
			hovered = value
			queue_redraw()
## Soft pulse while the object can be used. Only shown with Control hints on.
var available := false:
	set(value):
		if available != value:
			available = value
			set_process(value)
			queue_redraw()
## Red outline with the label always shown, for a second-click confirm.
var warn := false:
	set(value):
		if warn != value:
			warn = value
			queue_redraw()

var _time := 0.0


func _ready() -> void:
	if _material == null:
		_material = CanvasItemMaterial.new()
		_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = _material
	z_as_relative = false
	z_index = 30
	set_process(available)


func set_label(text: String) -> void:
	if label != text:
		label = text
		queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var soft := available and Settings.control_hints and not hovered and not warn
	if not (hovered or warn or soft):
		return
	var col := Color(1.0, 0.35, 0.3) if warn else Color(1.0, 0.85, 0.45)
	var a := 1.0 if (hovered or warn) else 0.35 + 0.2 * sin(_time * 3.0)
	draw_rect(rect.grow(5), Color(col.r, col.g, col.b, 0.12 * a))
	draw_rect(rect, Color(col.r, col.g, col.b, a), false, 3.0)
	if label == "" or soft:
		return
	var font := ThemeDB.fallback_font
	var size := 16
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var base := Vector2(rect.get_center().x - w * 0.5, rect.position.y - 12)
	draw_rect(Rect2(base + Vector2(-7, -18), Vector2(w + 14, 25)), Color(0.04, 0.03, 0.05, 0.92))
	draw_rect(Rect2(base + Vector2(-7, -18), Vector2(w + 14, 25)), Color(col.r, col.g, col.b, 0.8), false, 1.5)
	draw_string(font, base, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1, 0.97, 0.9))


## Hooks hover and the pointing-hand cursor to an Area2D or a Control.
func watch(node: Node) -> void:
	node.mouse_entered.connect(func():
		hovered = true
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	)
	node.mouse_exited.connect(func():
		hovered = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	)
