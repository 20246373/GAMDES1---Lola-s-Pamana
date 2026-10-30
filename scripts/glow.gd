class_name Glow
extends RefCounted
## One shared soft radial texture. Drawing it once is far cheaper than
## stacking many large translucent circles on slow GPUs.

static var _texture: GradientTexture2D
static var _add_material: CanvasItemMaterial


static func texture() -> Texture2D:
	if _texture == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		_texture = GradientTexture2D.new()
		_texture.gradient = g
		_texture.width = 128
		_texture.height = 128
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(0.5, 0.0)
	return _texture


## Additive blending that ignores 2D lights, for glows.
static func add_material() -> CanvasItemMaterial:
	if _add_material == null:
		_add_material = CanvasItemMaterial.new()
		_add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_add_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _add_material


## Draws a soft glow of the given radius centred on p.
static func draw(item: CanvasItem, p: Vector2, radius: float, color: Color) -> void:
	item.draw_texture_rect(texture(), Rect2(p - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color)
