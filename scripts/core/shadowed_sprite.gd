class_name ShadowedSprite extends Node2D

## Shadow and outline settings
const SHADOW_OFFSET: Vector2 = Vector2(2, 2)
const SHADOW_COLOR: Color = Color("2f2f2f")
const OUTLINE_COLOR: Color = Color("2f2f2f")

## The texture to display
var texture: Texture2D = null:
	set(value):
		texture = value
		queue_redraw()

## Size of the sprite (for drawing)
var sprite_size: Vector2 = Vector2(48, 48):
	set(value):
		sprite_size = value
		queue_redraw()

## White texture for shadow/outline (will be created if not set)
var _white_texture: Texture2D = null


func _ready() -> void:
	_create_white_texture()


func _draw() -> void:
	if texture == null:
		return

	# Draw shadow (offset, darker)
	_draw_shadow()

	# Draw outline (8 directions around)
	_draw_outline()

	# Draw main texture
	draw_texture_rect(texture, Rect2(Vector2.ZERO, sprite_size), false)


func _draw_shadow() -> void:
	if _white_texture == null:
		return

	var shadow_rect: Rect2 = Rect2(SHADOW_OFFSET, sprite_size)
	draw_texture_rect(_white_texture, shadow_rect, false, SHADOW_COLOR)


func _draw_outline() -> void:
	if _white_texture == null:
		return

	var outline_offsets: Array[Vector2] = [
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
		Vector2(-1, 0), Vector2(1, 0),
		Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)
	]

	for offset in outline_offsets:
		var outline_rect: Rect2 = Rect2(offset, sprite_size)
		draw_texture_rect(_white_texture, outline_rect, false, OUTLINE_COLOR)


func _create_white_texture() -> void:
	var img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_white_texture = ImageTexture.create_from_image(img)


## Helper to set up the sprite with texture and size
func setup(tex: Texture2D, size: Vector2 = Vector2(32, 32)) -> void:
	sprite_size = size
	texture = tex