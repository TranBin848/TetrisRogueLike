class_name Board extends Node2D

const PIECE_SIZE: int = 12
const PLACED_BLOCK_SCENE: PackedScene = preload("res://scenes/placed_block.tscn")


const BOARD_WIDTH: int = 10
const BOARD_HEIGHT: int = 20


const GRAVITY_DELAY: float = 0.1
const CALCULATION_DELAY: float = 1.0


const DEATHLINE_TOP_ROWS: int = 0
const DEATHLINE_BOTTOM_ROWS: int = 19


var placed_blocks_grid: Array[Array] = []
var destroyed_block_positions: Array[Vector2i] = []
var notification_rows: Array[int] = []

var linebreak_sound_pitch: float = 0.8

var momentum_perk_time_left: float = 0.0


@onready var placed_blocks: Node2D = $PlacedBlocks
@onready var line_destruction_color_rect: ColorRect = $LineDestructionColorRect
@onready var calculation_delay_timer: Timer = $CalculationDelayTimer

func _ready() -> void :
	initialize_board()
	_update_deathline_position()


	calculation_delay_timer.wait_time = CALCULATION_DELAY
	calculation_delay_timer.timeout.connect(_on_calculation_delay_timeout)


	EventManager.queue_started.connect( func():
		calculation_delay_timer.stop()
	)


	GameManager.calculation_finished.connect( func():
		linebreak_sound_pitch = 0.8
		calculation_delay_timer.start()
	)

	await get_tree().create_timer(CALCULATION_DELAY).timeout
	if OS.is_debug_build():
		print("[RenderDebug] Board ready -> spawn first moving piece")
	GameManager.spawn_moving_piece()


func _process(delta: float) -> void :
	#if GameManager.is_game_busy():
		#return

	if momentum_perk_time_left > 0.0:
		momentum_perk_time_left -= delta


func _on_calculation_delay_timeout() -> void :
	print("calculation_delay_timer timeout - proceeding to next action")

	if GameManager.is_calculating:
		GameManager.is_calculating = false
		GameScreen.next_action()


func _update_deathline_position() -> void :
	var is_fall_up: bool = GameManager.current_boss == GameData.BossTypes.FALL_UP
	var deathline_row: int = DEATHLINE_BOTTOM_ROWS if is_fall_up else DEATHLINE_TOP_ROWS

	line_destruction_color_rect.position.y = (deathline_row * PIECE_SIZE) + (PIECE_SIZE / 2)
	line_destruction_color_rect.size.x = BOARD_WIDTH * PIECE_SIZE


func initialize_board() -> void :

	GameManager.activate_perk(GameData.Perks.ACCELERATOR);
	GameManager.activate_perk(GameData.Perks.COMBO_ENGINE);
	GameManager.activate_perk(GameData.Perks.SACRIFICE_ROW);

	placed_blocks_grid.clear()
	GameManager.clear_placed_blocks_variables()

	for row in range(BOARD_HEIGHT):
		var sprite_row: Array[Node2D] = []

		for col in range(BOARD_WIDTH):
			sprite_row.append(null)

		placed_blocks_grid.append(sprite_row)
	if GameManager.is_perk_active(GameData.Perks.SACRIFICE_ROW):
		_spawn_warden_row();
		InGamePerksContainer._self.ready.connect(func() -> void:
			await get_tree().create_timer(1.5 * GameManager.timescale).timeout;
			GameManager.trigger_perk(GameData.Perks.SACRIFICE_ROW);
		, CONNECT_ONE_SHOT);

func is_position_occupied(pos: Vector2i) -> bool:

	if pos.x < 0 or pos.x >= BOARD_WIDTH or pos.y < 0 or pos.y >= BOARD_HEIGHT:
		return true


	if placed_blocks_grid.is_empty() or pos.y >= placed_blocks_grid.size():
		return true

	return placed_blocks_grid[pos.y][pos.x] != null


func place_block(pos: Vector2i, sprite_path: String, block_type: String = GameData.BLOCK_TYPES.NORMAL) -> PlacedBlock:
	if pos.x < 0 or pos.x >= BOARD_WIDTH or pos.y < 0 or pos.y >= BOARD_HEIGHT:
		return null

	var block_instance: PlacedBlock = PLACED_BLOCK_SCENE.instantiate()
	placed_blocks.add_child(block_instance)
	if OS.is_debug_build():
		print("[RenderDebug] place_block() instantiate at=", pos, " type=", block_type, " sprite=", sprite_path)

	block_instance.type = block_type
	block_instance.set_texture(load(sprite_path))
	block_instance.set_grid_position(pos, PIECE_SIZE)

	block_instance.destroyed.connect( func() -> void :

		for row in BOARD_HEIGHT:
			for col in BOARD_WIDTH:
				if placed_blocks_grid[row][col] == block_instance:
					placed_blocks_grid[row][col] = null
					destroyed_block_positions.append(Vector2i(col, row))
					return
	)

	placed_blocks_grid[pos.y][pos.x] = block_instance
	GameManager.add_placed_block(block_instance, block_type)

	return block_instance




func place_blocks_directly(positions: Array[Vector2i], block_type: String = GameData.BLOCK_TYPES.NORMAL, simulated_rotation: bool = false) -> Array[PlacedBlock]:
	var sprite_path: String = GameData.get_block_texture_path(block_type)
	return place_piece(positions, sprite_path, block_type, simulated_rotation)


func place_piece(blocks: Array[Vector2i], sprite_path: String, block_type: String = GameData.BLOCK_TYPES.NORMAL, piece_was_rotated: bool = false) -> Array[PlacedBlock]:
	var b: Array[PlacedBlock] = []
	if OS.is_debug_build():
		print("[RenderDebug] place_piece() blocks=", blocks, " type=", block_type, " rotated=", piece_was_rotated)

	for block_pos in blocks:
		b.append(place_block(block_pos, sprite_path, block_type))

	_trigger_below_blocks_animation(blocks)
	handle_block_placement_interactions(b, piece_was_rotated)

	if block_type == GameData.BLOCK_TYPES.SAND:
		_process_sand_blocks(b)

	#AchievementManager.add_progress(AchievementManager.AchievementId.PLACE_50_PIECES)
	#AchievementManager.add_progress(AchievementManager.AchievementId.PLACE_100_PIECES)
	#AchievementManager.add_progress(AchievementManager.AchievementId.PLACE_500_PIECES)

	return b

func _process_sand_blocks(sand_blocks: Array[PlacedBlock]) -> void:
	var is_fall_up: bool = GameManager.current_boss == GameData.BossTypes.FALL_UP

	if is_fall_up:
		sand_blocks.sort_custom(func(a, b): return a.grid_position.y < b.grid_position.y)
	else:
		sand_blocks.sort_custom(func(a, b): return a.grid_position.y > b.grid_position.y)

	var any_moved = false

	for block in sand_blocks:
		if not is_instance_valid(block):
			continue

		var col = block.grid_position.x
		var start_row = block.grid_position.y
		var final_row = start_row

		if is_fall_up:
			var check_row = start_row - 1
			while check_row >= 0 and not is_position_occupied(Vector2i(col, check_row)):
				final_row = check_row
				check_row -= 1
		else:
			var check_row = start_row + 1
			while check_row < BOARD_HEIGHT and not is_position_occupied(Vector2i(col, check_row)):
				final_row = check_row
				check_row += 1

		if final_row != start_row:
			placed_blocks_grid[start_row][col] = null
			placed_blocks_grid[final_row][col] = block
			block.grid_position = Vector2i(col, final_row)
			block.animate_y(final_row * PIECE_SIZE)
			any_moved = true

	if any_moved:
		GameCamera.shake_direction(2, 270, 0.2)

func is_line_full(row: int) -> bool:

	if row < 0 or row >= BOARD_HEIGHT:
		return false

	for col in BOARD_WIDTH:
		var block = placed_blocks_grid[row][col]

		if block == null or not is_instance_valid(block):
			return false
		if block.type == "indestructible":
			return false

	return true


func is_line_fully_empty(row: int) -> bool:

	if row < 0 or row >= BOARD_HEIGHT:
		return false

	for col in BOARD_WIDTH:
		if placed_blocks_grid[row][col] != null:
			return false

	return true


func is_fully_clear() -> bool:

	for row in BOARD_HEIGHT:
		for col in BOARD_WIDTH:
			if placed_blocks_grid[row][col] != null:
				return false

	return true


func check_and_clear_lines(should_execute_events: bool = true, should_trigger_next_action: bool = true) -> int:
	var rows_to_clear: Array[int] = []

	for i in BOARD_HEIGHT:
		if is_line_full(i):
			rows_to_clear.append(i)

	if rows_to_clear.size() > 0:
		var lines_count: int = rows_to_clear.size()

		for i in rows_to_clear:
			for col in range(BOARD_WIDTH - 1, -1, -1):
				var block: PlacedBlock = placed_blocks_grid[i][col]

				if is_instance_valid(block):
					EventManager.add_event(BlockChainReaction.common_destroy.bind(block, lines_count))

		GameCamera.shake_direction(2 * linebreak_sound_pitch, 0, 0.3)

		if GameManager.is_perk_active(GameData.Perks.STACK_MASTER) and lines_count >= 3:
			GameManager.trigger_perk(GameData.Perks.STACK_MASTER)
		if GameManager.is_perk_active(GameData.Perks.BUILDER):
			for i in range(lines_count):
				GameManager.trigger_perk(GameData.Perks.BUILDER);
		if GameManager.is_perk_active(GameData.Perks.PAUPER) and lines_count == 1:
			GameManager.trigger_cumulative_perk(GameData.Perks.PAUPER)
		if GameManager.is_perk_active(GameData.Perks.COMBO_ENGINE) and lines_count >= 2:
			GameManager.trigger_cumulative_perk(GameData.Perks.COMBO_ENGINE)

		if GameManager.is_perk_active(GameData.Perks.PERFECTION) and lines_count == 4:
			GameManager.trigger_cumulative_perk(GameData.Perks.PERFECTION)

		if GameManager.is_perk_active(GameData.Perks.MOMENTUM):
			if momentum_perk_time_left > 0.0:
				GameManager.trigger_cumulative_perk(GameData.Perks.MOMENTUM)
			else:
				GameManager.reset_cumulative_perk(GameData.Perks.MOMENTUM)

			momentum_perk_time_left = 15.0


		#if GameManager.current_boss == GameData.BossTypes.PERFECTIONIST and lines_count < 4:
			#EventManager.add_event_last( func() -> float:
				#GameManager.points = GameManager.points.multiply(0.5)
#
				#var boss_texture_rect: BossTypeTextureRect = GameManager.get_unique_node("BossTypeTextureRect")
				#PointNotification.create_and_slide(boss_texture_rect.global_position + boss_texture_rect.size / 2 + Vector2(0, 6), PointNotification.BLUE, "x0.5", 1.8, PointNotification.DOWN, 12.0)
#
				#return BlockChainReaction.DEFAULT_DELAY
			#)


		if GameManager.is_perk_active(GameData.Perks.FULL_CLEAR):
			GameManager.trigger_perk(GameData.Perks.FULL_CLEAR)

		if should_execute_events:
			GameManager.is_calculating = true
			EventManager.execute_events()
	else:
		if should_trigger_next_action:
			GameScreen.next_action()

	return rows_to_clear.size()







func apply_gravity_changes() -> float:


	if EventManager.should_check_lines_after_queue:
		print("Skipping gravity application - line check pending after queue")
		return 0.0



	var local_destroyed_positions: Array[Vector2i] = destroyed_block_positions.duplicate()
	destroyed_block_positions.clear()


	var destroyed_by_column: Dictionary = {}
	for pos in local_destroyed_positions:
		if not destroyed_by_column.has(pos.x):
			destroyed_by_column[pos.x] = []
		destroyed_by_column[pos.x].append(pos.y)


	for col in destroyed_by_column.keys():
		var destroyed_rows: Array[int] = []

		destroyed_rows.assign(destroyed_by_column[col])
		destroyed_rows.sort()

		_apply_gravity_to_column(col, destroyed_rows)

	return GRAVITY_DELAY




func _trigger_below_blocks_animation(newly_placed_blocks: Array[Vector2i]) -> void :
	if newly_placed_blocks.is_empty():
		return


	var affected_columns: Array[int] = []
	for block_pos in newly_placed_blocks:
		if block_pos.x not in affected_columns:
			affected_columns.append(block_pos.x)


	if not _has_blocks_in_columns(affected_columns):
		return


	var animated_blocks_count: int = _animate_blocks_in_columns(affected_columns)


	if animated_blocks_count > 5:
		GameCamera.shake_direction(1, 270, 0.2)


func _has_blocks_in_columns(columns: Array[int]) -> bool:
	for col in columns:
		for row in range(BOARD_HEIGHT):
			if placed_blocks_grid[row][col] != null:
				return true
	return false


func _animate_blocks_in_columns(columns: Array[int]) -> int:
	var animated_count: int = 0

	for col in columns:
		for row in range(BOARD_HEIGHT):
			var block: PlacedBlock = placed_blocks_grid[row][col]
			if is_instance_valid(block):
				block.above_placement_animation()
				animated_count += 1

	return animated_count




func handle_block_placement_interactions(newly_placed_blocks: Array[PlacedBlock], piece_was_rotated: bool = false) -> void :

	var colony_event_queue: Array[Callable] = []

	var worker_bee_blocks: Array[PlacedBlock] = GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.WORKER_BEE)
	var queen_bee_blocks: Array[PlacedBlock] = GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.QUEEN_BEE)


	for b in newly_placed_blocks:
		worker_bee_blocks.erase(b)
		queen_bee_blocks.erase(b)

	for worker_bee_block in worker_bee_blocks:
		var adjacent_blocks: Array[PlacedBlock] = worker_bee_block.get_adjacent_blocks()
		var adjacent_colony_block_count: int = 0

		for block in adjacent_blocks:
			if is_instance_valid(block) and GameData.is_block_on_group(block.type, GameData.BlockGroups.COLONY):
				adjacent_colony_block_count += 1

		if adjacent_colony_block_count > 0:
			colony_event_queue.append(BlockChainReaction.worker_bee.bind(worker_bee_block, adjacent_colony_block_count))

	for queen_bee_block in queen_bee_blocks:
		var adjacent_blocks: Array[PlacedBlock] = queen_bee_block.get_adjacent_blocks()
		var adjacent_colony_block_count: int = 0

		for block in adjacent_blocks:
			if is_instance_valid(block) and GameData.is_block_on_group(block.type, GameData.BlockGroups.COLONY):
				adjacent_colony_block_count += 1

		if adjacent_colony_block_count > 0:
			colony_event_queue.append(BlockChainReaction.queen_bee.bind(queen_bee_block, adjacent_colony_block_count))

	if colony_event_queue.size() > 0:
		EventManager.execute_queue_events(colony_event_queue)


	if not piece_was_rotated:

		if GameManager.is_perk_active(GameData.Perks.ACCEPTANCE):
			GameManager.trigger_perk(GameData.Perks.ACCEPTANCE)

		var bricks: Array[PlacedBlock] = GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.BRICK)


		for b in newly_placed_blocks:
			bricks.erase(b)

		if bricks.size() > 0:
			var bricks_event_queue: Array[Callable] = []

			for brick in bricks:
				bricks_event_queue.append(BlockChainReaction.brick.bind(brick))

			EventManager.execute_queue_events(bricks_event_queue)




func _apply_gravity_to_column(col: int, destroyed_rows: Array[int]) -> void :
	var falling_blocks: Array[Dictionary] = []
	var is_fall_up: bool = GameManager.current_boss == GameData.BossTypes.FALL_UP


	var row_range: Array[int] = []
	row_range.assign(range(BOARD_HEIGHT) if is_fall_up else range(BOARD_HEIGHT - 1, -1, -1))

	for row in row_range:
		var block: PlacedBlock = placed_blocks_grid[row][col]

		if not is_instance_valid(block):
			continue


		var fall_distance: int = 0
		for destroyed_row in destroyed_rows:
			var should_fall: bool = destroyed_row < row if is_fall_up else destroyed_row > row
			if should_fall:
				fall_distance += 1

		if fall_distance > 0:

			var target_row: int
			if is_fall_up:
				target_row = max(0, row - fall_distance)
			else:
				target_row = min(BOARD_HEIGHT - 1, row + fall_distance)

			falling_blocks.append({
				"block": block, 
				"from_row": row, 
				"to_row": target_row
			})


	for block_data in falling_blocks:
		var block: PlacedBlock = block_data["block"]
		var from_row: int = block_data["from_row"]
		var to_row: int = block_data["to_row"]


		var final_row: int = to_row
		if is_fall_up:

			while final_row < BOARD_HEIGHT and is_instance_valid(placed_blocks_grid[final_row][col]):
				final_row += 1

			if final_row >= BOARD_HEIGHT:
				continue
		else:

			while final_row >= 0 and is_instance_valid(placed_blocks_grid[final_row][col]):
				final_row -= 1

			if final_row < 0:
				continue


		placed_blocks_grid[from_row][col] = null
		placed_blocks_grid[final_row][col] = block

		block.grid_position = Vector2i(col, final_row)
		block.animate_y(final_row * PIECE_SIZE)


func _spawn_warden_row() -> void :
	for row in range(0, BOARD_HEIGHT - 1):
		for col in range(BOARD_WIDTH):
			var block: PlacedBlock = placed_blocks_grid[row + 1][col]
			placed_blocks_grid[row + 1][col] = null
			placed_blocks_grid[row][col] = block
			if is_instance_valid(block):
				block.grid_position = Vector2i(col, row)
				block.animate_y(row * PIECE_SIZE)
				if row <= DEATHLINE_TOP_ROWS:
					GameManager.deathline = true
	for col in range(BOARD_WIDTH):
		placed_blocks_grid[BOARD_HEIGHT - 1][col] = null
	var positions: Array[Vector2i] = []
	for col in range(BOARD_WIDTH):
		positions.append(Vector2i(col, BOARD_HEIGHT - 1))
	place_blocks_directly(positions, "indestructible")
	#await get_tree().process_frame
	#check_and_clear_lines()
