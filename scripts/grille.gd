extends Node2D
## The iron grille across the service window. Customers stand behind it, so
## every face is seen through the bars (Section II Boundaries and 7.1).
## A narrow slot is left open above the counter for goods and cash.
## Drawn once in screen space. It does not redraw every frame.

## The open service window in the store art, in 1280 x 720 screen pixels.
const OPENING := Rect2(528, 204, 302, 210)
const SLOT_HEIGHT := 40.0
const BAR_GAP := 30.0
const IRON := Color(0.11, 0.1, 0.1)
const EDGE := Color(0.4, 0.38, 0.36)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Draw in canvas pixels whatever the parent's scale is.
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	var top := OPENING.position.y
	var bottom := OPENING.end.y - SLOT_HEIGHT
	var x := OPENING.position.x + BAR_GAP * 0.5
	while x < OPENING.end.x:
		draw_line(Vector2(x, top), Vector2(x, bottom), IRON, 5.0)
		draw_line(Vector2(x - 2, top), Vector2(x - 2, bottom), EDGE, 1.0)
		x += BAR_GAP
	for y in [top + 24.0, top + 128.0, bottom]:
		draw_line(Vector2(OPENING.position.x, y), Vector2(OPENING.end.x, y), IRON, 6.0)
		draw_line(Vector2(OPENING.position.x, y - 2), Vector2(OPENING.end.x, y - 2), EDGE, 1.0)
