@tool
class_name SpriteShadowed extends Node2D

@export var texture: CompressedTexture2D:
	set(value):
		texture = value

		if is_instance_valid(main_sprite):
			main_sprite.texture = texture

		_update_sprite_positions()

@export var centered: bool = true:
	set(value):
		centered = value
		_update_sprite_positions()


func _update_sprite_positions() -> void :

	if not is_instance_valid(main_sprite) or not texture:
		return

	if centered:
		main_sprite.position = Vector2.ZERO
	else:
		main_sprite.position = texture.get_size() / 2

	if is_instance_valid(shadow_sprite):
		shadow_sprite.position = main_sprite.position + shadow_margin


@export var shadow_margin: Vector2 = Vector2(4, 4)

@export var shadow_texture: CompressedTexture2D:
	set(value):
		shadow_texture = value
		if is_instance_valid(shadow_sprite):
			shadow_sprite.texture = shadow_texture

@export var shadow_color: Color = Color.BLACK:
	set(value):
		shadow_color = value

		if is_instance_valid(shadow_sprite):
			(shadow_sprite.material as ShaderMaterial).set_shader_parameter("shadow_color", shadow_color)

@onready var main_sprite: Sprite2D = $MainSprite
@onready var shadow_sprite: Sprite2D = $ShadowSprite

func _ready() -> void :
	main_sprite.texture = texture

	if shadow_sprite:
		shadow_sprite.visible = true
		shadow_sprite.position = shadow_margin * scale
		shadow_sprite.texture = shadow_texture if shadow_texture else texture

		(shadow_sprite.material as ShaderMaterial).set_shader_parameter("shadow_color", shadow_color)

	_update_sprite_positions()


func _process(_delta: float) -> void :
	if shadow_sprite:
		shadow_sprite.global_position = main_sprite.global_position + (shadow_margin * scale)
		shadow_sprite.global_rotation = main_sprite.global_rotation
