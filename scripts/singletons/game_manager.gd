extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal score_changed(new_score: int)
signal multiplier_changed(new_multiplier: int)
signal lines_cleared(count: int)
signal piece_landed(blocks: Array)
signal block_destroyed(block: Node)
signal game_over()
signal game_started()
signal calculation_finished()
signal coins_changed(new_coins: int)

# =============================================================================
# GAME STATE
# =============================================================================

var score: int = 0
var multiplier: int = 1
var lines_cleared_total: int = 0
var level: int = 1
var coins: int = 0
var is_game_over: bool = false
var is_calculating: bool = false
var paused: bool = false

# =============================================================================
# PIECE BAG (7-bag randomizer)
# =============================================================================

var _piece_bag: Array[Dictionary] = []
var _next_piece: Dictionary = {}
var _held_piece: Dictionary = {}
var _can_hold: bool = true

# =============================================================================
# BOARD REFERENCE
# =============================================================================

var _board: Node = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_refill_bag()
	_next_piece = _pick_from_bag()


func reset_game() -> void:
	score = 0
	multiplier = 1
	lines_cleared_total = 0
	level = 1
	coins = 0
	is_game_over = false
	is_calculating = false
	paused = false
	_held_piece = {}
	_can_hold = true
	_piece_bag.clear()
	_refill_bag()
	_next_piece = _pick_from_bag()
	score_changed.emit(score)
	multiplier_changed.emit(multiplier)
	coins_changed.emit(coins)
	game_started.emit()

# =============================================================================
# BOARD MANAGEMENT
# =============================================================================

func set_board(board: Node) -> void:
	_board = board


func get_board() -> Node:
	return _board


func can_move() -> bool:
	return not is_calculating and not is_game_over and not paused

# =============================================================================
# PIECE MANAGEMENT
# =============================================================================

func get_next_piece() -> Dictionary:
	return _next_piece


func consume_next_piece() -> Dictionary:
	var current: Dictionary = _next_piece
	_next_piece = _pick_from_bag()
	_can_hold = true
	return current


func get_held_piece() -> Dictionary:
	return _held_piece


func try_hold_piece(current_piece: Dictionary) -> Dictionary:
	if not _can_hold:
		return {}

	_can_hold = false
	var old_held: Dictionary = _held_piece
	_held_piece = current_piece

	if old_held.is_empty():
		return consume_next_piece()
	else:
		return old_held


func _refill_bag() -> void:
	var shapes = [
		GameData.ShapeType.I,
		GameData.ShapeType.O,
		GameData.ShapeType.T,
		GameData.ShapeType.S,
		GameData.ShapeType.Z,
		GameData.ShapeType.J,
		GameData.ShapeType.L,
	]
	shapes.shuffle()
	
	for s in shapes:
		var base_type: String = GameData.get_shape_block_type(s)
		var t: String = GameData.get_random_special_block_type(base_type)
		_piece_bag.append({"shape": s, "type": t})


func _pick_from_bag() -> Dictionary:
	if _piece_bag.is_empty():
		_refill_bag()
	return _piece_bag.pop_front()

# =============================================================================
# SCORING
# =============================================================================

## Base points for line clears
const LINE_SCORES: Array[int] = [0, 100, 300, 500, 800]  # 0, 1, 2, 3, 4 lines

func add_score(points: int) -> void:
	score += points * multiplier
	score_changed.emit(score)

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func add_multiplier(value: int) -> void:
	multiplier += value
	multiplier_changed.emit(multiplier)


func reset_multiplier() -> void:
	multiplier = 1
	multiplier_changed.emit(multiplier)


func on_lines_cleared(count: int) -> void:
	if count <= 0:
		return

	lines_cleared_total += count

	# Calculate score based on lines cleared
	var line_index: int = mini(count, LINE_SCORES.size() - 1)
	var points: int = LINE_SCORES[line_index] * level
	add_score(points)

	# Update level
	var new_level: int = (lines_cleared_total / 10) + 1
	if new_level > level:
		level = new_level

	lines_cleared.emit(count)


func trigger_game_over() -> void:
	is_game_over = true
	game_over.emit()


func finish_calculation() -> void:
	is_calculating = false
	calculation_finished.emit()

# =============================================================================
# FALL SPEED
# =============================================================================

## Get fall interval in seconds based on level
func get_fall_speed() -> float:
	# Formula similar to classic Tetris
	# Level 1: 1.0s, Level 10: ~0.1s, Level 20: ~0.05s
	var frames: float = pow(0.8 - ((level - 1) * 0.007), level - 1) * 60.0
	return max(frames / 60.0, 0.016)  # Minimum 1 frame at 60fps
