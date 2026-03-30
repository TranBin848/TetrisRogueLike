extends Node

# =============================================================================
# BLOCK TYPES
# =============================================================================

const BLOCK_TYPES: Dictionary = {
	# Standard tetromino colors (7 types)
	"CYAN": "cyan",        # I piece
	"YELLOW": "yellow",    # O piece
	"PURPLE": "purple",    # T piece
	"GREEN": "green",      # S piece
	"RED": "red",          # Z piece
	"BLUE": "blue",        # J piece
	"ORANGE": "orange",    # L piece
}

const SPECIAL_BLOCKS: Array[String] = [
	"gold",
	"special_blue",
	"special_red",
	"water",
	"lucky"
]

enum BlockGroups {
	DEFAULT,
}

# Map block type to texture path
const BLOCK_TEXTURES: Dictionary = {
	"cyan": "res://resources/block_textures/cyan.png",
	"yellow": "res://resources/block_textures/yellow.png",
	"purple": "res://resources/block_textures/purple.png",
	"green": "res://resources/block_textures/green.png",
	"red": "res://resources/block_textures/red.png",
	"blue": "res://resources/block_textures/blue.png",
	"orange": "res://resources/block_textures/orange.png",
}

# =============================================================================
# TETROMINO SHAPES
# =============================================================================

enum ShapeType { I, O, T, S, Z, J, L }

# Shape to block type mapping
const SHAPE_BLOCK_TYPES: Dictionary = {
	ShapeType.I: "cyan",
	ShapeType.O: "yellow",
	ShapeType.T: "purple",
	ShapeType.S: "green",
	ShapeType.Z: "red",
	ShapeType.J: "blue",
	ShapeType.L: "orange",
}

# Each shape has 4 rotations, each rotation is array of Vector2i offsets from pivot
# Using SRS (Super Rotation System) standard
const PIECE_SHAPES: Dictionary = {
	ShapeType.I: [
		# Rotation 0 (horizontal)
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
		# Rotation 1 (vertical)
		[Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)],
		# Rotation 2
		[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)],
		# Rotation 3
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)],
	],
	ShapeType.O: [
		# O piece doesn't rotate (all 4 states same)
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
	],
	ShapeType.T: [
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
	],
	ShapeType.S: [
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)],
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
	],
	ShapeType.Z: [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],
	],
	ShapeType.J: [
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)],
	],
	ShapeType.L: [
		[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)],
	],
}

# =============================================================================
# SRS WALL KICK DATA
# =============================================================================

# Wall kick offsets for J, L, S, T, Z pieces
const WALL_KICKS_JLSTZ: Dictionary = {
	# from_rotation -> to_rotation: [kick_offsets]
	"0->1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"1->0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"1->2": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"2->1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"2->3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	"3->2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	"3->0": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	"0->3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
}

# Wall kick offsets for I piece (different from others)
const WALL_KICKS_I: Dictionary = {
	"0->1": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	"1->0": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	"1->2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
	"2->1": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	"2->3": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	"3->2": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	"3->0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	"0->3": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func get_block_texture_path(block_type: String) -> String:
	if BLOCK_TEXTURES.has(block_type):
		return BLOCK_TEXTURES[block_type]
	return ""


func get_shape_blocks(shape_type: ShapeType, rotation: int) -> Array:
	return PIECE_SHAPES[shape_type][rotation]


func get_shape_block_type(shape_type: ShapeType) -> String:
	return SHAPE_BLOCK_TYPES[shape_type]


func get_wall_kicks(shape_type: ShapeType, from_rot: int, to_rot: int) -> Array:
	var key: String = "%d->%d" % [from_rot, to_rot]
	if shape_type == ShapeType.I:
		return WALL_KICKS_I.get(key, [Vector2i.ZERO])
	elif shape_type == ShapeType.O:
		return [Vector2i.ZERO]  # O doesn't need wall kicks
	else:
		return WALL_KICKS_JLSTZ.get(key, [Vector2i.ZERO])


func get_random_shape() -> ShapeType:
	return randi() % ShapeType.size() as ShapeType


func get_random_special_block_type(base_type: String) -> String:
	# 80% normal
	if randf() > 0.2:
		return base_type
	# 20% special
	return SPECIAL_BLOCKS.pick_random()
