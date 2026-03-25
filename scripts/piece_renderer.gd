class_name PieceRenderer extends Node2D

const PIECE_SIZE: int = 12
const SPRITE_SHADOWED_SCENE: PackedScene = preload("res://scenes/ui/sprite_shadow.tscn")

const SPAWN_ANIMATION_DURATION: float = 0.35
const SPAWN_ANIMATION_START: Vector2 = Vector2.ONE * 0.5

enum ShapeType{
	I, 
	O, 
	T, 
	S, 
	Z, 
	J, 
	L
}

const DECK_SPRITES: Dictionary = {
	GameData.DeckTypes.NORMAL: {
		ShapeType.I: "res://sprite/blocks/default/cyan.png", 
		ShapeType.O: "res://sprites/blocks/default/dark_green.png", 
		ShapeType.T: "res://sprites/blocks/default/purple.png", 
		ShapeType.S: "res://sprites/blocks/default/green.png", 
		ShapeType.Z: "res://sprites/blocks/default/red.png", 
		ShapeType.J: "res://sprites/blocks/default/blue.png", 
		ShapeType.L: "res://sprites/blocks/default/orange.png"
	}, 
	GameData.DeckTypes.MOAI: {
		ShapeType.I: "res://sprites/blocks/moai/blue.png", 
		ShapeType.O: "res://sprites/blocks/moai/green.png", 
		ShapeType.T: "res://sprites/blocks/moai/purple.png", 
		ShapeType.S: "res://sprites/blocks/moai/green.png", 
		ShapeType.Z: "res://sprites/blocks/moai/red.png", 
		ShapeType.J: "res://sprites/blocks/moai/blue.png", 
		ShapeType.L: "res://sprites/blocks/moai/orange.png"
	}, 
	GameData.DeckTypes.X: {
		ShapeType.I: "res://sprites/blocks/the_x/blue.png", 
		ShapeType.O: "res://sprites/blocks/the_x/green.png", 
		ShapeType.T: "res://sprites/blocks/the_x/purple.png", 
		ShapeType.S: "res://sprites/blocks/the_x/green.png", 
		ShapeType.Z: "res://sprites/blocks/the_x/red.png", 
		ShapeType.J: "res://sprites/blocks/the_x/blue.png", 
		ShapeType.L: "res://sprites/blocks/the_x/orange.png"
	}
}

const PIECE_SHADOW_SPRITE: CompressedTexture2D = preload("res://sprite/blocks/default/white_block.png")
const PIECE_SHADOW_COLOR: Color = Color("2f2f2f")
const OUTLINE_COLOR: Color = Color("2f2f2f")
const SHADOW_OFFSET: Vector2 = Vector2(2,2)

const PIECE_SHAPES:Dictionary[ShapeType , Array] = {
ShapeType.I: [

		[
			[0, 0, 0, 0], 
			[1, 1, 1, 1], 
			[0, 0, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 0, 1, 0], 
			[0, 0, 1, 0], 
			[0, 0, 1, 0], 
			[0, 0, 1, 0]
		], 

		[
			[0, 0, 0, 0], 
			[0, 0, 0, 0], 
			[1, 1, 1, 1], 
			[0, 0, 0, 0]
		], 

		[
			[0, 1, 0, 0], 
			[0, 1, 0, 0], 
			[0, 1, 0, 0], 
			[0, 1, 0, 0]
		]
	], 
	ShapeType.O: [

		[
			[0, 1, 1, 0], 
			[0, 1, 1, 0], 
			[0, 0, 0, 0], 
			[0, 0, 0, 0]
		], 
		[
			[0, 1, 1, 0], 
			[0, 1, 1, 0], 
			[0, 0, 0, 0], 
			[0, 0, 0, 0]
		], 
		[
			[0, 1, 1, 0], 
			[0, 1, 1, 0], 
			[0, 0, 0, 0], 
			[0, 0, 0, 0]
		], 
		[
			[0, 1, 1, 0], 
			[0, 1, 1, 0], 
			[0, 0, 0, 0], 
			[0, 0, 0, 0]
		]
	], 
	ShapeType.T: [

		[
			[0, 1, 0, 0], 
			[1, 1, 1, 0], 
			[0, 0, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 1, 0, 0], 
			[0, 1, 1, 0], 
			[0, 1, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 0, 0, 0], 
			[1, 1, 1, 0], 
			[0, 1, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 1, 0, 0], 
			[1, 1, 0, 0], 
			[0, 1, 0, 0], 
			[0, 0, 0, 0]
		]
	], 
	ShapeType.S: [

		[
			[0, 1, 1, 0], 
			[1, 1, 0, 0], 
			[0, 0, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 1, 0, 0], 
			[0, 1, 1, 0], 
			[0, 0, 1, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 0, 0, 0], 
			[0, 1, 1, 0], 
			[1, 1, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[1, 0, 0, 0], 
			[1, 1, 0, 0], 
			[0, 1, 0, 0], 
			[0, 0, 0, 0]
		]
	], 
	ShapeType.Z: [

		[
			[1, 1, 0, 0], 
			[0, 1, 1, 0], 
			[0, 0, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 0, 1, 0], 
			[0, 1, 1, 0], 
			[0, 1, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 0, 0, 0], 
			[1, 1, 0, 0], 
			[0, 1, 1, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 1, 0, 0], 
			[1, 1, 0, 0], 
			[1, 0, 0, 0], 
			[0, 0, 0, 0]
		]
	], 
	ShapeType.J: [

		[
			[1, 0, 0, 0], 
			[1, 1, 1, 0], 
			[0, 0, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 1, 1, 0], 
			[0, 1, 0, 0], 
			[0, 1, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 0, 0, 0], 
			[1, 1, 1, 0], 
			[0, 0, 1, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 1, 0, 0], 
			[0, 1, 0, 0], 
			[1, 1, 0, 0], 
			[0, 0, 0, 0]
		]
	], 
	ShapeType.L: [

		[
			[0, 0, 1, 0], 
			[1, 1, 1, 0], 
			[0, 0, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 1, 0, 0], 
			[0, 1, 0, 0], 
			[0, 1, 1, 0], 
			[0, 0, 0, 0]
		], 

		[
			[0, 0, 0, 0], 
			[1, 1, 1, 0], 
			[1, 0, 0, 0], 
			[0, 0, 0, 0]
		], 

		[
			[1, 1, 0, 0], 
			[0, 1, 0, 0], 
			[0, 1, 0, 0], 
			[0, 0, 0, 0]
		]
	]
}

var current_shape_type:ShapeType = ShapeType.I
var current_rotation:int = 0
var current_texture: Texture2D = null
var current_blocks :Array[Vector2i] = []

@onready var shadow_outline_layer: Node2D = $ShadowOutlineLayer
@onready var texture_layer: Node2D = $TextureLayer

func _ready() -> void:
	shadow_outline_layer.draw.connect(_draw_shadow_outline)
	texture_layer.draw.connect(_draw_texture)

func _draw_shadow_outline() -> void :
	if current_texture == null or current_blocks.is_empty():
		return


	var bounds: = get_piece_bounds(current_shape_type, current_rotation)
	var center_offset: = Vector2(bounds.position + bounds.size / 2) * PIECE_SIZE

	var outline_offsets: Array[Vector2] = [
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), 
		Vector2(-1, 0), Vector2(1, 0), 
		Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)
	]


	for block_pos in current_blocks:
		var pos: = Vector2(block_pos) * PIECE_SIZE + SHADOW_OFFSET - center_offset

		for offset in outline_offsets:
			shadow_outline_layer.draw_texture_rect(PIECE_SHADOW_SPRITE, Rect2(pos + offset, Vector2.ONE * PIECE_SIZE), false, PIECE_SHADOW_COLOR)

		shadow_outline_layer.draw_texture_rect(PIECE_SHADOW_SPRITE, Rect2(pos, Vector2.ONE * PIECE_SIZE), false, PIECE_SHADOW_COLOR)


	for block_pos in current_blocks:
		var pos: = Vector2(block_pos) * PIECE_SIZE - center_offset
		for offset in outline_offsets:
			shadow_outline_layer.draw_texture_rect(PIECE_SHADOW_SPRITE, Rect2(pos + offset, Vector2.ONE * PIECE_SIZE), false, OUTLINE_COLOR)


func _draw_texture() -> void :
	if current_texture == null or current_blocks.is_empty():
		return


	var bounds: = get_piece_bounds(current_shape_type, current_rotation)
	var center_offset: = Vector2(bounds.position + bounds.size / 2) * PIECE_SIZE


	for block_pos in current_blocks:
		var pos: = Vector2(block_pos) * PIECE_SIZE - center_offset
		texture_layer.draw_texture_rect(current_texture, Rect2(pos, Vector2.ONE * PIECE_SIZE), false)


func set_piece(shape_type: ShapeType, rotation_index: int = 0, animated: bool = true, block_type: String = GameData.BLOCK_TYPES.NORMAL) -> void :

	if not PIECE_SHAPES.has(shape_type):
		push_error("Invalid piece type: " + str(shape_type))
		return

	rotation_index = rotation_index % 4


	current_shape_type = shape_type
	current_rotation = rotation_index
	current_blocks = get_piece_blocks(shape_type, rotation_index)


	var sprite_path: String
	if block_type in [GameData.BLOCK_TYPES.NORMAL, GameData.BLOCK_TYPES.MOAI, GameData.BLOCK_TYPES.X]:
		sprite_path = DECK_SPRITES[GameData.DeckTypes.NORMAL][shape_type]

		if DECK_SPRITES.has(GameManager.current_deck) and DECK_SPRITES[GameManager.current_deck].has(shape_type):
			sprite_path = DECK_SPRITES[GameManager.current_deck][shape_type]
	else:
		sprite_path = GameData.get_block_texture_path(block_type)

	current_texture = load(sprite_path)


	var bounds: = get_piece_bounds(shape_type, rotation_index)
	var center_offset: = Vector2(bounds.position + bounds.size / 2) * PIECE_SIZE
	shadow_outline_layer.position = center_offset
	texture_layer.position = center_offset


	if animated:
		shadow_outline_layer.scale = SPAWN_ANIMATION_START
		texture_layer.scale = SPAWN_ANIMATION_START
		var tween: = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
		tween.tween_property(shadow_outline_layer, "scale", Vector2.ONE, SPAWN_ANIMATION_DURATION / GameManager.timescale)
		tween.tween_property(texture_layer, "scale", Vector2.ONE, SPAWN_ANIMATION_DURATION / GameManager.timescale)
	else:
		shadow_outline_layer.scale = Vector2.ONE
		texture_layer.scale = Vector2.ONE

	shadow_outline_layer.queue_redraw()
	texture_layer.queue_redraw()

func get_piece_bounds(piece_type: ShapeType, rotation_index: int = 0) -> Rect2i:
	if not PIECE_SHAPES.has(piece_type):
		return Rect2i()

	rotation_index = rotation_index % 4
	var shape = PIECE_SHAPES[piece_type][rotation_index]

	var min_x = 4
	var min_y = 4
	var max_x = -1
	var max_y = -1

	for row in range(shape.size()):
		for col in range(shape[row].size()):
			if shape[row][col] == 1:
				min_x = min(min_x, col)
				min_y = min(min_y, row)
				max_x = max(max_x, col)
				max_y = max(max_y, row)

	if max_x == -1:
		return Rect2i()

	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func get_piece_blocks(piece_type: ShapeType, rotation_index: int = 0) -> Array[Vector2i]:

	var blocks: Array[Vector2i] = []

	if not PIECE_SHAPES.has(piece_type):
		return blocks

	rotation_index = rotation_index % 4
	var shape = PIECE_SHAPES[piece_type][rotation_index]

	for row in range(shape.size()):
		for col in range(shape[row].size()):
			if shape[row][col] == 1:
				blocks.append(Vector2i(col, row))

	return blocks
