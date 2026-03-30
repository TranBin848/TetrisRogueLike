class_name PieceDisplay extends Node2D

const PIECE_SIZE: int = 12

var _current_shape: GameData.ShapeType = GameData.ShapeType.I
var _current_rotation: int = 0
var _current_texture: Texture2D

@onready var _layer: Node2D = $Layer


func _ready() -> void:
	_layer.draw.connect(_on_draw)


func set_piece(shape: GameData.ShapeType, rotation: int = 0, block_type: String = "cyan") -> void:
	_current_shape = shape
	_current_rotation = rotation % 4

	_current_texture = load(GameData.get_block_texture_path(block_type))

	_layer.queue_redraw()


func get_piece_bounds(shape: GameData.ShapeType, rotation: int = 0) -> Rect2i:
	var shapes = GameData.get_shape_blocks(shape, rotation)

	var min_x = 4
	var min_y = 4
	var max_x = -1
	var max_y = -1

	for block_pos in shapes:
		min_x = min(min_x, block_pos.x)
		min_y = min(min_y, block_pos.y)
		max_x = max(max_x, block_pos.x)
		max_y = max(max_y, block_pos.y)

	if max_x == -1:
		return Rect2i()

	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _on_draw() -> void:
	if _current_texture == null:
		return

	var blocks = GameData.get_shape_blocks(_current_shape, _current_rotation)
	var bounds = get_piece_bounds(_current_shape, _current_rotation)

	var center_offset = Vector2(bounds.position + bounds.size / 2) * PIECE_SIZE

	for block_pos in blocks:
		var pos = Vector2(block_pos) * PIECE_SIZE - center_offset
		_layer.draw_texture_rect(_current_texture, Rect2(pos, Vector2.ONE * PIECE_SIZE), false)
