class_name Board 
extends Node2D

# =============================================================================
# CONSTANTS
# =============================================================================

const BOARD_WIDTH: int = 10
const BOARD_HEIGHT: int = 20
const CELL_SIZE: int = 32
const SPAWN_POSITION: Vector2i = Vector2i(3, 0)

const PLACED_BLOCK_SCENE: PackedScene = preload("res://scenes/placed_block.tscn")

# =============================================================================
# STATE
# =============================================================================

## 2D grid of PlacedBlock references (null = empty)
var placed_blocks_grid: Array = []

## Track destroyed block positions for gravity
var destroyed_block_positions: Array[Vector2i] = []

# =============================================================================
# NODES
# =============================================================================

@onready var placed_blocks_container: Node2D = $PlacedBlocks
@onready var moving_piece: MovingPiece = $MovingPiece
@onready var ghost_piece: Node2D = $GhostPiece

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	GameManager.set_board(self)
	initialize_board()

	EventManager.queue_started.connect(_on_queue_started)
	EventManager.queue_finished.connect(_on_queue_finished)


func initialize_board() -> void:
	# Clear existing blocks
	for child in placed_blocks_container.get_children():
		child.queue_free()

	# Initialize grid
	placed_blocks_grid.clear()
	for row in range(BOARD_HEIGHT):
		var row_array: Array = []
		row_array.resize(BOARD_WIDTH)
		for col in range(BOARD_WIDTH):
			row_array[col] = null
		placed_blocks_grid.append(row_array)

	destroyed_block_positions.clear()

# =============================================================================
# GRID QUERIES
# =============================================================================

func is_position_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < BOARD_WIDTH and pos.y >= 0 and pos.y < BOARD_HEIGHT


func is_position_occupied(pos: Vector2i) -> bool:
	if not is_position_valid(pos):
		return true  # Out of bounds = occupied
	if pos.y < 0:
		return false  # Above board is ok
	return placed_blocks_grid[pos.y][pos.x] != null


func is_position_free(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= BOARD_WIDTH:
		return false
	if pos.y >= BOARD_HEIGHT:
		return false
	if pos.y < 0:
		return true  # Above board is free
	return placed_blocks_grid[pos.y][pos.x] == null


func get_block_at(pos: Vector2i) -> PlacedBlock:
	if not is_position_valid(pos):
		return null
	return placed_blocks_grid[pos.y][pos.x] as PlacedBlock


func get_column_blocks(col: int) -> Array[PlacedBlock]:
	var blocks: Array[PlacedBlock] = []
	if col < 0 or col >= BOARD_WIDTH:
		return blocks
	for row in range(BOARD_HEIGHT):
		var block: PlacedBlock = placed_blocks_grid[row][col] as PlacedBlock
		if is_instance_valid(block):
			blocks.append(block)
	return blocks

# =============================================================================
# BLOCK PLACEMENT
# =============================================================================

func place_block(pos: Vector2i, block_type: String) -> PlacedBlock:
	if not is_position_valid(pos):
		return null
	if pos.y < 0:
		return null  # Can't place above board

	var block: PlacedBlock = PLACED_BLOCK_SCENE.instantiate()
	placed_blocks_container.add_child(block)

	block.type = block_type
	block.set_grid_position(pos)

	# Connect destroyed signal to track position
	block.destroyed.connect(func():
		_on_block_destroyed(block)
	)

	placed_blocks_grid[pos.y][pos.x] = block
	return block


func _on_block_destroyed(block: PlacedBlock) -> void:
	var pos: Vector2i = block.grid_position
	if is_position_valid(pos):
		placed_blocks_grid[pos.y][pos.x] = null
		destroyed_block_positions.append(pos)

# =============================================================================
# LINE CLEARING
# =============================================================================

func is_line_full(row: int) -> bool:
	if row < 0 or row >= BOARD_HEIGHT:
		return false
	for col in range(BOARD_WIDTH):
		var block = placed_blocks_grid[row][col]
		if block == null or not is_instance_valid(block):
			return false
	return true


func check_and_clear_lines(should_execute_events: bool = true, should_spawn_next: bool = true) -> int:
	var rows_to_clear: Array[int] = []

	# Find all full rows
	for row in range(BOARD_HEIGHT):
		if is_line_full(row):
			rows_to_clear.append(row)

	if rows_to_clear.size() > 0:
		var lines_count: int = rows_to_clear.size()

		# Reset pitch for new line clear
		PlacedBlock.reset_destroy_pitch()

		# Queue destruction RIGHT TO LEFT for each row
		for row in rows_to_clear:
			for col in range(BOARD_WIDTH - 1, -1, -1):
				var block: PlacedBlock = placed_blocks_grid[row][col] as PlacedBlock
				if is_instance_valid(block) and not block.destroy_animation_requested:
					EventManager.add_event(BlockEffects.common_destroy.bind(block, lines_count))

		# Camera shake
		var camera = get_viewport().get_camera_2d()
		if camera and camera.has_method("shake_direction"):
			camera.shake_direction(2.0 * lines_count, 0, 0.3)

		EventManager.add_event(func():
			print("All multiplier added?")
			return 0.0;
		);

		# Update score
		GameManager.on_lines_cleared(lines_count)

		if should_execute_events:
			GameManager.is_calculating = true
			EventManager.execute_events()
	else:
		# No lines to clear - spawn next piece
		if should_spawn_next:
			spawn_next_piece()

	return rows_to_clear.size()

# =============================================================================
# GRAVITY
# =============================================================================

func apply_gravity_changes() -> void:
	if destroyed_block_positions.is_empty():
		spawn_next_piece()
		return

	var local_destroyed: Array[Vector2i] = destroyed_block_positions.duplicate()
	destroyed_block_positions.clear()

	# Group destroyed positions by column
	var by_column: Dictionary = {}
	for pos in local_destroyed:
		if not by_column.has(pos.x):
			by_column[pos.x] = []
		by_column[pos.x].append(pos.y)

	# Apply gravity to each affected column
	for col in by_column.keys():
		var destroyed_rows: Array = by_column[col]
		destroyed_rows.sort()
		_apply_gravity_to_column(col, destroyed_rows)

	# Check for cascading line clears
	await get_tree().create_timer(0.2).timeout
	var cascading_lines: int = check_and_clear_lines(true, true)
	if cascading_lines == 0:
		spawn_next_piece()


func _apply_gravity_to_column(col: int, destroyed_rows: Array) -> void:
	# Collect all blocks above destroyed rows that need to fall
	var falling_blocks: Array[Dictionary] = []

	# Iterate from bottom to top
	for row in range(BOARD_HEIGHT - 1, -1, -1):
		var block: PlacedBlock = placed_blocks_grid[row][col] as PlacedBlock
		if not is_instance_valid(block):
			continue

		# Count how many destroyed rows are BELOW this block
		var fall_distance: int = 0
		for destroyed_row in destroyed_rows:
			if destroyed_row > row:
				fall_distance += 1

		if fall_distance > 0:
			var target_row: int = mini(BOARD_HEIGHT - 1, row + fall_distance)
			falling_blocks.append({
				"block": block,
				"from_row": row,
				"to_row": target_row
			})

	# Move blocks in grid and animate
	for data in falling_blocks:
		var block: PlacedBlock = data["block"]
		var from_row: int = data["from_row"]
		var to_row: int = data["to_row"]

		# Update grid
		placed_blocks_grid[from_row][col] = null
		placed_blocks_grid[to_row][col] = block

		# Update block position
		block.grid_position = Vector2i(col, to_row)
		block.animate_fall_to(to_row * CELL_SIZE)

# =============================================================================
# PIECE SPAWNING
# =============================================================================

func spawn_next_piece() -> void:
	GameManager.finish_calculation()

	if moving_piece:
		var shape: GameData.ShapeType = GameManager.consume_next_piece()
		moving_piece.spawn(shape)

		# Check game over
		if not moving_piece.is_spawn_valid():
			GameManager.trigger_game_over()

# =============================================================================
# EVENT CALLBACKS
# =============================================================================

func _on_queue_started() -> void:
	pass


func _on_queue_finished() -> void:
	pass
