extends Node

signal score_changed(value: int)
signal points_changed(value: int)
signal multiplier_changed(value: int)
signal next_piece_calculated()
signal pieces_finished()
signal hold_piece_changed()


var original_pieces: Dictionary[PieceRenderer.ShapeType, Array] = {}
var pieces: Dictionary[PieceRenderer.ShapeType, Array] = {}
var piece_queue: Array[PieceRenderer.ShapeType] = []
var current_deck: GameData.DeckTypes = GameData.DeckTypes.NORMAL
var hold_piece_data: Dictionary = {}

var score: int = 0:
	set(value):
		score = value
		score_changed.emit(score)

var target_score: int = 1000

var points:int = 0:
	set(value):
		points = value
		points_changed.emit(points)

var multiplier: int = 1:
	set(value):
		multiplier = value
		multiplier_changed.emit(multiplier)

var next_piece_cache: Dictionary = {}:
	set(value):
		next_piece_cache = value
		next_piece_calculated.emit()

func _ready() -> void:
	pass
 
func get_current_default_block() -> String:
	match current_deck:
		GameData.DeckTypes.NORMAL:
			return GameData.BLOCK_TYPES.NORMAL
		GameData.DeckTypes.MOAI:
			return GameData.BLOCK_TYPES.MOAI
		GameData.DeckTypes.X:
			return GameData.BLOCK_TYPES.X
		_:
			return GameData.BLOCK_TYPES.NORMAL


func generate_piece_queue() -> void :
	original_pieces.clear()
	pieces.clear()
	piece_queue.clear()


	var all_shapes: Array[PieceRenderer.ShapeType] = [
		PieceRenderer.ShapeType.I, 
		PieceRenderer.ShapeType.O, 
		PieceRenderer.ShapeType.T, 
		PieceRenderer.ShapeType.S, 
		PieceRenderer.ShapeType.Z, 
		PieceRenderer.ShapeType.J, 
		PieceRenderer.ShapeType.L
	]

	for shape_type: PieceRenderer.ShapeType in all_shapes:
		original_pieces[shape_type] = []
		pieces[shape_type] = []

	for bag_index: int in 3:
		for shape_type: PieceRenderer.ShapeType in all_shapes:
			original_pieces[shape_type].append(get_current_default_block())


	for shape_type: PieceRenderer.ShapeType in all_shapes:
		pieces[shape_type] = original_pieces[shape_type].duplicate()

	generate_next_bag()
	_calculate_next_piece_cache()
func generate_next_bag() -> void :
	var new_bag: Array[PieceRenderer.ShapeType] = [
		PieceRenderer.ShapeType.I, 
		PieceRenderer.ShapeType.O, 
		PieceRenderer.ShapeType.T, 
		PieceRenderer.ShapeType.S, 
		PieceRenderer.ShapeType.Z, 
		PieceRenderer.ShapeType.J, 
		PieceRenderer.ShapeType.L
	]

	Random.shuffle(new_bag)
	piece_queue.append_array(new_bag)

func _calculate_next_piece_cache() -> void :
	next_piece_cache = {}


	for i in piece_queue.size():
		var next_shape: PieceRenderer.ShapeType = piece_queue[i]
		var pieces_of_shape: Array = pieces.get(next_shape, [])

		if pieces_of_shape.size() > 0:
			var block_type: String = _pick_block_type(pieces_of_shape)
			next_piece_cache = {"type": block_type, "shape": next_shape, "queue_index": i}
			return


	for shape_type in pieces.keys():
		if pieces[shape_type].size() > 0:

			piece_queue.append(shape_type)
			var block_type: String = _pick_block_type(pieces[shape_type])
			next_piece_cache = {"type": block_type, "shape": shape_type, "queue_index": piece_queue.size() - 1}
			return


	if not hold_piece_data.is_empty():
		next_piece_cache = {"type": hold_piece_data.type, "shape": hold_piece_data.shape}
		hold_piece_data = {}
		hold_piece_changed.emit()
		print("[GameManager] Used piece from hold: ", GameData.get_block_name(next_piece_cache.type))
		return

	pieces_finished.emit()


func _pick_block_type(available_blocks: Array) -> String:
	if available_blocks.is_empty():
		return ""
	return Random.pick_random(available_blocks)

func pick_random(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[Random.randi() % array.size()]

func get_next_piece() -> Dictionary:
	if next_piece_cache.has("type") and next_piece_cache.has("shape"):
		return {"type": next_piece_cache.type, "shape": next_piece_cache.shape}

	return {}

func get_remaining_pieces_count() -> int:
	var total_count: int = 0

	for key in pieces:
		total_count += pieces[key].size()

	return total_count
func consume_next_piece() -> Dictionary:
	if next_piece_cache.is_empty():
		print("[GameManager] No pieces available in any shape type!")
		return {}

	var piece_data: Dictionary = {"type": next_piece_cache.type, "shape": next_piece_cache.shape}

	if next_piece_cache.has("queue_index"):
		var queue_index: int = next_piece_cache.queue_index
		pieces[piece_data.shape].erase(piece_data.type)
		piece_queue.remove_at(queue_index)

		if piece_queue.size() <= 3:
			generate_next_bag()

	_calculate_next_piece_cache()

	return piece_data
func get_original_pieces_count() -> int:
	var total_count: int = 0
	for shape_type: PieceRenderer.ShapeType in original_pieces:
		total_count += original_pieces[shape_type].size()
	return total_count

func reset_pieces_to_original() -> void :
	pieces = original_pieces.duplicate(true)

	piece_queue.clear()
	next_piece_cache = {}

	generate_next_bag()
	_calculate_next_piece_cache()

#Test
func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Q:
				points += 100
			KEY_W:
				multiplier += 1
			KEY_E:
				score += points * multiplier
				points = 0
				multiplier = 1
