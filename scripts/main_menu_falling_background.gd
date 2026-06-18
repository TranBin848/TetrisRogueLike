class_name MainMenuFallingBackground extends Node2D

const SCREEN_SIZE: Vector2 = Vector2(480, 270)
const PIECE_SIZE: int = 12
const SHADOW_OFFSET: Vector2 = Vector2(2, 2)
const PIECE_SHADOW_COLOR: Color = Color("2f2f2f")
const OUTLINE_COLOR: Color = Color("2f2f2f")
const PIECE_SHADOW_SPRITE: Texture2D = preload("res://images/white_block.png")
const MONOCHROME_PIECE_COLOR: Color = Color("1b2027")
const MONOCHROME_OUTLINE_COLOR: Color = Color("303842")
const MONOCHROME_SHADOW_COLOR: Color = Color("090c10")
const GRID_COLOR: Color = Color("29313a")
const DARK_BACKGROUND_COLOR: Color = Color("0d1116")

const SHAPES: Array = [
	[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
]

const NORMAL_TEXTURE_PATHS: Array[String] = [
	"res://images/blocks/normal/blue.png",
	"res://images/blocks/normal/yellow.png",
	"res://images/blocks/normal/purple.png",
	"res://images/blocks/normal/green.png",
	"res://images/blocks/normal/red.png",
	"res://images/blocks/normal/orange.png",
	"res://images/blocks/normal/cyan.png"
]
const SPECIAL_TEXTURE_PATHS: Array[String] = [
	"res://images/blocks/special/common/gold.png",
	"res://images/blocks/special/common/bluec.png",
	"res://images/blocks/special/common/redc.png",
	"res://images/blocks/special/common/sand.png",
	"res://images/blocks/special/common/rainbow.png",
	"res://images/blocks/special/uncommon/glass.png",
	"res://images/blocks/special/uncommon/lucky.png",
	"res://images/blocks/special/uncommon/copy.png",
	"res://images/blocks/special/rare/obsidian.png",
	"res://images/blocks/special/rare/danger.png"
]

@export var quantity: int = 30
@export var piece_scale_min: float = 0.6
@export var piece_scale_max: float = 0.7
@export var special_piece_chance: float = 0.35
@export var fall_speed_min: float = 40.0
@export var fall_speed_max: float = 70.0
@export var monochrome: bool = false
@export var grid_enabled: bool = false
@export var grid_size: int = 16

var pieces: Array[Dictionary] = []
var normal_textures: Array[Texture2D] = []
var special_textures: Array[Texture2D] = []


func _ready() -> void:
	z_index = -100
	_load_textures()

	for i in quantity:
		pieces.append(_create_piece(randf_range(-SCREEN_SIZE.y, SCREEN_SIZE.y)))


func _process(delta: float) -> void:
	for piece in pieces:
		var piece_node: Node2D = piece["node"]
		piece_node.position += piece["velocity"] * delta
		piece_node.rotation += piece["rotation_speed"] * delta

		if piece_node.position.y > SCREEN_SIZE.y + 42.0:
			_reset_piece(piece)


func _draw() -> void:
	draw_rect(
		Rect2(Vector2.ZERO, SCREEN_SIZE),
		DARK_BACKGROUND_COLOR if monochrome else Color.BLACK
	)

	if not grid_enabled:
		return

	for x in range(0, int(SCREEN_SIZE.x) + 1, grid_size):
		draw_line(Vector2(x, 0), Vector2(x, SCREEN_SIZE.y), GRID_COLOR, 1.0)

	for y in range(0, int(SCREEN_SIZE.y) + 1, grid_size):
		draw_line(Vector2(0, y), Vector2(SCREEN_SIZE.x, y), GRID_COLOR, 1.0)


func _load_textures() -> void:
	for texture_path in NORMAL_TEXTURE_PATHS:
		normal_textures.append(load(texture_path))

	for texture_path in SPECIAL_TEXTURE_PATHS:
		special_textures.append(load(texture_path))


func _create_piece(y_offset: float = 0.0) -> Dictionary:
	var piece_node := Node2D.new()
	add_child(piece_node)

	var piece: Dictionary = {
		"node": piece_node,
		"velocity": Vector2.ZERO,
		"rotation_speed": 0.0
	}

	_reset_piece(piece)
	piece_node.position.y = y_offset
	return piece


func _reset_piece(piece: Dictionary) -> void:
	var piece_node: Node2D = piece["node"]
	piece_node.position = Vector2(randf_range(-20.0, SCREEN_SIZE.x + 20.0), randf_range(-90.0, -20.0))
	piece_node.rotation = randf_range(-PI, PI)
	piece_node.scale = Vector2.ONE * randf_range(piece_scale_min, piece_scale_max)

	var speed: float = randf_range(fall_speed_min, fall_speed_max)
	piece["velocity"] = Vector2(randf_range(-8.0, 8.0), speed)
	piece["rotation_speed"] = randf_range(-0.85, 0.85)

	_rebuild_piece_sprites(piece)


func _rebuild_piece_sprites(piece: Dictionary) -> void:
	var piece_node: Node2D = piece["node"]
	for child in piece_node.get_children():
		child.free()

	var shape: Array = SHAPES[randi() % SHAPES.size()]
	var texture: Texture2D = PIECE_SHADOW_SPRITE if monochrome else _pick_block_texture()
	var piece_color: Color = MONOCHROME_PIECE_COLOR if monochrome else Color.WHITE
	var outline_color: Color = MONOCHROME_OUTLINE_COLOR if monochrome else OUTLINE_COLOR
	var shadow_color: Color = MONOCHROME_SHADOW_COLOR if monochrome else PIECE_SHADOW_COLOR
	var center_offset: Vector2 = _get_shape_center_offset(shape)
	var outline_offsets: Array[Vector2] = [
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
		Vector2(-1, 0), Vector2(1, 0),
		Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)
	]

	for block_pos in shape:
		var local_pos: Vector2 = Vector2(block_pos) * PIECE_SIZE - center_offset

		for offset in outline_offsets:
			_add_block_sprite(piece_node, PIECE_SHADOW_SPRITE, local_pos + SHADOW_OFFSET + offset, shadow_color, -2)

		_add_block_sprite(piece_node, PIECE_SHADOW_SPRITE, local_pos + SHADOW_OFFSET, shadow_color, -2)

		for offset in outline_offsets:
			_add_block_sprite(piece_node, PIECE_SHADOW_SPRITE, local_pos + offset, outline_color, -1)

		_add_block_sprite(piece_node, texture, local_pos, piece_color, 0)


func _pick_block_texture() -> Texture2D:
	if randf() < special_piece_chance and not special_textures.is_empty():
		return special_textures[randi() % special_textures.size()]

	return normal_textures[randi() % normal_textures.size()]


func _add_block_sprite(parent: Node2D, texture: Texture2D, local_pos: Vector2, color: Color, z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = local_pos
	sprite.modulate = color
	sprite.z_index = z
	sprite.scale = Vector2(PIECE_SIZE / texture.get_width(), PIECE_SIZE / texture.get_height())
	parent.add_child(sprite)


func _get_shape_center_offset(shape: Array) -> Vector2:
	var min_pos := Vector2i(4, 4)
	var max_pos := Vector2i(-1, -1)

	for block_pos in shape:
		min_pos.x = min(min_pos.x, block_pos.x)
		min_pos.y = min(min_pos.y, block_pos.y)
		max_pos.x = max(max_pos.x, block_pos.x)
		max_pos.y = max(max_pos.y, block_pos.y)

	return Vector2(min_pos.x + max_pos.x + 1, min_pos.y + max_pos.y + 1) * PIECE_SIZE * 0.5
