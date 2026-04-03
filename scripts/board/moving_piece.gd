class_name MovingPiece extends Node2D


const PLACEMENT_COYOTE_TIME: float = 0.5
const INSTANT_PLACE_COYOTE_TIME: float = 0.1
const FALL_TIME_DEFAULT: float = 1.0
const FALL_TIME_MINIMUM: float = 0.2
const FALL_TIME_ROUND_DECREASE: float = 0.03

const SPAWN_POSITION: Vector2i = Vector2i(3, 0)
const SPAWN_POSITION_INVERTED: Vector2i = Vector2i(3, BOARD_HEIGHT - 3)

const ROTATION_CLOCKWISE: int = 1
const ROTATION_COUNTERCLOCKWISE: int = -1
const ROTATION_180: int = 2


static var _self: MovingPiece


var current_piece_data: Dictionary = {}
var current_rotation: int = 0
var grid_position: Vector2i = Vector2i(0, 0)

var time_since_spawn: float = 0.0
var rotated: bool = false

var fall_time: float = FALL_TIME_DEFAULT

const BOARD_WIDTH: int = 10
const BOARD_HEIGHT: int = 20

var move_timer: float = 0.0
var gravity_timer_counter: float = 0.0

var previous_horizontal_input: int = 0
var current_horizontal_input: int = 0

var is_first_horizontal_move: bool = true

var placement_coyote_timer: float = 0.0
var is_grounded: bool = false

var position_tween: Tween
var movement_enabled: bool = true
var input_coyote_time: float = 0.03

@onready var board: Board = get_parent()
@onready var piece_renderer: PieceRenderer = $PieceRenderer
@onready var ghost_renderer: PieceRenderer = $GhostRenderer


static func create(parent: Node, next_piece_data: Dictionary) -> MovingPiece:
	var instance: MovingPiece = preload("res://scenes/moving_piece.tscn").instantiate()

	parent.add_child(instance)
	if OS.is_debug_build():
		print("[RenderDebug] MovingPiece.create() parent=", parent.name, " data=", next_piece_data)

	instance.name = "MovingPiece"


	var spawn_position: Vector2i
	if GameManager.current_boss == GameData.BossTypes.FALL_UP:
		spawn_position = SPAWN_POSITION_INVERTED
	else:
		spawn_position = SPAWN_POSITION

	instance.set_piece(next_piece_data.shape, spawn_position, next_piece_data.type)

	return instance


func _ready() -> void :
	fall_time = max(FALL_TIME_MINIMUM, FALL_TIME_DEFAULT - (GameManager.current_round * FALL_TIME_ROUND_DECREASE))

	ghost_renderer.modulate.a = 0.2

	if GameManager.current_boss == GameData.BossTypes.BLINDFOLDED:
		ghost_renderer.visible = false

	if GameManager.current_boss == GameData.BossTypes.DIZZY:
		GameManager.second_passed.connect(_on_dizzy_second_passed)


func _on_dizzy_second_passed() -> void :

	if GameManager.paused or not movement_enabled:
		return


	if GameManager.time_passed_in_seconds % GameData.DIZZY_ROTATION_INTERVAL == 0:
		rotate_piece(ROTATION_CLOCKWISE)
		#AudioManager.play(AudioManager.SoundEffects.POP, randf_range(0.4, 0.6))


func _unhandled_input(event: InputEvent) -> void :
	if GameManager.paused or not movement_enabled or input_coyote_time > 0:
		return

	if event.is_action_pressed("user_rotate_clockwise"):
		rotate_piece(ROTATION_CLOCKWISE)
	elif event.is_action_pressed("user_rotate_counterclockwise"):
		rotate_piece(ROTATION_COUNTERCLOCKWISE)
	elif event.is_action_pressed("user_rotate_180"):
		rotate_piece(ROTATION_180)

	if event.is_action_pressed("user_place") and time_since_spawn >= INSTANT_PLACE_COYOTE_TIME:
		instant_place()

	if event.is_action_pressed("user_hold"):
		hold_piece()

	if event.is_action_pressed("user_right"):
		move_horizontal(1)
		move_timer = 0.0
	elif event.is_action_pressed("user_left"):
		move_horizontal(-1)
		move_timer = 0.0


func _process(delta: float) -> void :
	if input_coyote_time > 0:
		input_coyote_time = max(0, input_coyote_time - delta)

	if GameManager.paused or not movement_enabled:
		return

	time_since_spawn += delta

	if time_since_spawn >= 4.0 and GameManager.is_perk_active(GameData.Perks.AUTOMAGIC):
		instant_place()
		return

	var current_fall_speed: float = GameManager.settings.soft_drop_rate if Input.is_action_pressed("user_down") else fall_time

	gravity_timer_counter += delta * GameManager.timescale

	if gravity_timer_counter >= current_fall_speed:
		if GameManager.current_boss == GameData.BossTypes.FALL_UP:
			move_up()
		else:
			move_down()
		gravity_timer_counter = 0.0


	if is_grounded:
		placement_coyote_timer -= delta

		if placement_coyote_timer <= 0.0:
			land_piece()
			return

	previous_horizontal_input = current_horizontal_input
	current_horizontal_input = 0

	if Input.is_action_pressed("user_left"):
		current_horizontal_input = -1
	elif Input.is_action_pressed("user_right"):
		current_horizontal_input = 1


	if current_horizontal_input != previous_horizontal_input:
		move_timer = 0.0
		is_first_horizontal_move = true

	if current_horizontal_input != 0 and input_coyote_time <= 0:
		move_timer += delta

		var delay_threshold: float = GameManager.settings.input_repeat_delay if (is_first_horizontal_move) else GameManager.settings.input_repeat_rate

		if move_timer >= delay_threshold:
			move_horizontal(current_horizontal_input)
			move_timer = 0.0
			is_first_horizontal_move = false
	else:

		move_timer = 0.0
		is_first_horizontal_move = true


func set_piece(shape_type: PieceRenderer.ShapeType, spawn_position: Vector2i = SPAWN_POSITION, block_type: String = GameData.BLOCK_TYPES.NORMAL) -> void :
	current_piece_data = {"type": block_type, "shape": shape_type}
	current_rotation = 0


	if GameManager.current_boss == GameData.BossTypes.FALL_UP and spawn_position == SPAWN_POSITION:
		grid_position = SPAWN_POSITION_INVERTED
	else:
		grid_position = spawn_position

	is_grounded = false
	placement_coyote_timer = 0.0

	piece_renderer.set_piece(current_piece_data.shape, current_rotation, true, block_type)
	ghost_renderer.set_piece(current_piece_data.shape, current_rotation, false, block_type)

	if OS.is_debug_build():
		print("[RenderDebug] MovingPiece.set_piece() shape=", shape_type, " block_type=", block_type, " grid_position=", grid_position)

	update_visual_position()
	update_ghost_position()


func move_horizontal(direction: int) -> void :
	if GameManager.current_boss == GameData.BossTypes.REVERSED:
		direction *= -1

	var new_position = grid_position + Vector2i(direction, 0)

	if is_valid_position(new_position, current_rotation):
		grid_position = new_position
		update_visual_position()
		update_ghost_position()


		reset_placement_timer()



		if is_grounded:
			var fall_direction: Vector2i = Vector2i(0, 1) if GameManager.current_boss != GameData.BossTypes.FALL_UP else Vector2i(0, -1)
			if is_valid_position(grid_position + fall_direction, current_rotation):
				is_grounded = false


func move_down() -> void :
	if is_grounded:
		return

	var new_position = grid_position + Vector2i(0, 1)


	if is_valid_position(new_position, current_rotation):
		grid_position = new_position
		update_visual_position()
		update_ghost_position()
		is_grounded = false
	else:

		if not is_grounded:
			is_grounded = true
			reset_placement_timer()


func move_up() -> void :
	if is_grounded:
		return

	var new_position = grid_position + Vector2i(0, -1)


	if is_valid_position(new_position, current_rotation):
		grid_position = new_position
		update_visual_position()
		update_ghost_position()
		is_grounded = false
	else:

		if not is_grounded:
			is_grounded = true
			reset_placement_timer()


func land_piece() -> void :
	if not board:
		push_error("MovingPiece: No board reference set!")
		return

	if OS.is_debug_build():
		print("[RenderDebug] land_piece() blocks=", get_current_blocks(), " type=", current_piece_data.type)

	if GameManager.current_moving_piece == self:
		GameManager.current_moving_piece = null


	if GameManager.current_boss == GameData.BossTypes.DIZZY:
		if GameManager.second_passed.is_connected(_on_dizzy_second_passed):
			GameManager.second_passed.disconnect(_on_dizzy_second_passed)

	set_process(false)

	GameManager.pieces_played += 1

	var current_blocks: Array[Vector2i] = get_current_blocks()
	var sprite_path: String

	if current_piece_data.type in [GameData.BLOCK_TYPES.MOAI, GameData.BLOCK_TYPES.NORMAL, GameData.BLOCK_TYPES.X]:
		sprite_path = PieceRenderer.DECK_SPRITES[GameManager.current_deck][current_piece_data.shape]
	else:
		sprite_path = GameData.get_block_texture_path(current_piece_data.type)
	
	print(sprite_path)
	
	#AchievementManager.discover_block(current_piece_data.type)


	var blocks: Array[PlacedBlock] = board.place_piece(current_blocks, sprite_path, current_piece_data.type, rotated)

	await get_tree().process_frame
	board.check_and_clear_lines()

	GameManager.piece_landed.emit(blocks, rotated)


	if GameManager.is_perk_active(GameData.Perks.AUTOMAGIC):
		GameManager.trigger_perk(GameData.Perks.AUTOMAGIC)

	if GameManager.is_perk_active(GameData.Perks.SPEED_RUN):
		var level: int = GameManager.get_perk_level(GameData.Perks.SPEED_RUN)
		var time_threshold: float = 3.0 if level == 5 else 2.0
		if time_since_spawn <= time_threshold:
			GameManager.trigger_perk(GameData.Perks.SPEED_RUN)

	#AudioManager.play(AudioManager.SoundEffects.DIRT_3, randf_range(1.6, 2.0))

	queue_free()


	if MovingPiece._self == self:
		MovingPiece._self = null


func instant_place() -> void :
	var drop_position: Vector2 = calculate_drop_position()

	grid_position = drop_position
	update_visual_position()

	GameCamera.shake_direction(2, 270, 0.5)

	land_piece()


func hold_piece() -> void :
	if GameManager.current_boss == GameData.BossTypes.THIEF:
		return

	if GameManager.get_remaining_pieces_count() == 0:
		return

	if GameManager.is_perk_active(GameData.Perks.SACRIFICE) and not GameManager.next_piece_cache.is_empty():
		GameManager.trigger_perk(GameData.Perks.SACRIFICE)
		GameManager.spawn_moving_piece()

		queue_free()

		#AudioManager.play(AudioManager.SoundEffects.POP, randf_range(0.5, 0.7))
		return

	if not GameManager.hold_piece_data.is_empty() and GameManager.hold_piece_data.has("shape"):
		if GameManager.hold_piece_data.shape == current_piece_data.shape and GameManager.hold_piece_data.type == current_piece_data.type:
			return

	var piece_to_hold: Dictionary = current_piece_data.duplicate()

	if not GameManager.hold_piece_data.is_empty():
		var held_piece: Dictionary = GameManager.hold_piece_data.duplicate()
		GameManager.hold_piece_data = piece_to_hold


		var spawn_pos: Vector2i
		if GameManager.current_boss == GameData.BossTypes.FALL_UP:
			spawn_pos = SPAWN_POSITION_INVERTED
		else:
			spawn_pos = SPAWN_POSITION

		set_piece(held_piece.shape, spawn_pos, held_piece.type)
	else:
		GameManager.hold_piece_data = piece_to_hold
		GameManager.spawn_moving_piece()
		queue_free()


	#if not GameManager.is_perk_active(GameData.Perks.FORGIVEN):
		##var target_score_panel: ScoreBackgroundPanel = GameManager.get_unique_node("ScoreBackgroundPanel")
		##var hold_background_panel: HoldBackgroundPanel = GameManager.get_unique_node("HoldBackgroundPanel")
#
		#var target_score_increase: Big = GameManager.target_score.multiply(0.1)
#
		#GameManager.target_score = GameManager.target_score.plus(target_score_increase)
		#target_score_panel.target_score_label_value = GameManager.target_score.to_float()
#
		#PointNotification.create_and_slide(hold_background_panel.global_position + hold_background_panel.size / 2 + Vector2(0, 6), PointNotification.GRAY, target_score_increase.to_scientific(true), 1.0, PointNotification.DOWN, 8.0)
#
	#GameManager.hold_piece_changed.emit()
#
	##AudioManager.play(AudioManager.SoundEffects.POP, randf_range(0.8, 1.2))
#
	#time_since_spawn = 0.0
	#rotated = false
#
	#reset_placement_timer()





func rotate_piece(addition: int) -> void :

	if current_piece_data.type == GameData.BLOCK_TYPES.STONE or current_piece_data.type == GameData.BLOCK_TYPES.MOAI:
		return


	if current_piece_data.shape == PieceRenderer.ShapeType.O:
		return

	var new_rotation: int = (current_rotation + addition + 4) % 4

	#AudioManager.play(AudioManager.SoundEffects.BLOOP)

	rotated = true
	GameManager.rotated_piece_on_current_round = true


	reset_placement_timer()


	if is_valid_position(grid_position, new_rotation):
		current_rotation = new_rotation
		piece_renderer.set_piece(current_piece_data.shape, current_rotation, true, current_piece_data.type)
		ghost_renderer.set_piece(current_piece_data.shape, current_rotation, false, current_piece_data.type)
		update_ghost_position()


		if is_grounded:
			var fall_direction: Vector2i = Vector2i(0, 1) if GameManager.current_boss != GameData.BossTypes.FALL_UP else Vector2i(0, -1)
			if is_valid_position(grid_position + fall_direction, current_rotation):
				is_grounded = false

		return


	var kick_offsets: Array[Vector2i]


	if abs(addition) == 2:
		kick_offsets = get_wall_kick_offsets_180(current_rotation, new_rotation)
	else:
		kick_offsets = get_wall_kick_offsets(current_rotation, new_rotation)

	print("Rotation - Current: %d, New: %d, Addition: %d" % [current_rotation, new_rotation, addition])
	print("Kick Offsets: %s" % str(kick_offsets))

	for offset in kick_offsets:
		var test_position: Vector2i = grid_position + offset
		if is_valid_position(test_position, new_rotation):
			grid_position = test_position
			current_rotation = new_rotation
			piece_renderer.set_piece(current_piece_data.shape, current_rotation, true, current_piece_data.type)
			ghost_renderer.set_piece(current_piece_data.shape, current_rotation, false, current_piece_data.type)
			update_visual_position()
			update_ghost_position()


			if is_grounded:
				var fall_direction: Vector2i = Vector2i(0, 1) if GameManager.current_boss != GameData.BossTypes.FALL_UP else Vector2i(0, -1)
				if is_valid_position(grid_position + fall_direction, current_rotation):
					is_grounded = false

			return




func reset_placement_timer() -> void :
	placement_coyote_timer = PLACEMENT_COYOTE_TIME






func get_wall_kick_offsets(from_rotation: int, to_rotation: int) -> Array[Vector2i]:

	if current_piece_data.shape == PieceRenderer.ShapeType.O:
		return []


	if current_piece_data.shape == PieceRenderer.ShapeType.I:
		return get_i_piece_wall_kicks(from_rotation, to_rotation)


	return get_standard_wall_kicks(from_rotation, to_rotation)




func get_jlstz_offset_data(rotation_state: int) -> Array[Vector2i]:
	match rotation_state:
		0:
			return [Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)]
		1:
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)]
		2:
			return [Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)]
		3:
			return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)]
		_:
			return [Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)]





func get_standard_wall_kicks(from_rotation: int, to_rotation: int) -> Array[Vector2i]:
	var from_offsets: Array[Vector2i] = get_jlstz_offset_data(from_rotation)
	var to_offsets: Array[Vector2i] = get_jlstz_offset_data(to_rotation)

	var kicks: Array[Vector2i] = []



	for i in range(5):
		var kick: Vector2i = from_offsets[i] - to_offsets[i]
		kicks.append(kick)

	return kicks





func get_wall_kick_offsets_180(from_rotation: int, to_rotation: int) -> Array[Vector2i]:

	if current_piece_data.shape == PieceRenderer.ShapeType.O:
		return []


	if current_piece_data.shape == PieceRenderer.ShapeType.I:
		var from_offsets: Array[Vector2i] = get_i_piece_offset_data(from_rotation)
		var to_offsets: Array[Vector2i] = get_i_piece_offset_data(to_rotation)

		var kicks: Array[Vector2i] = []

		for i in range(5):
			var kick: Vector2i = from_offsets[i] - to_offsets[i]
			kicks.append(kick)

		return kicks


	var jlstz_from_offsets: Array[Vector2i] = get_jlstz_offset_data(from_rotation)
	var jlstz_to_offsets: Array[Vector2i] = get_jlstz_offset_data(to_rotation)

	var jlstz_kicks: Array[Vector2i] = []

	for i in range(5):
		var kick: Vector2i = jlstz_from_offsets[i] - jlstz_to_offsets[i]
		jlstz_kicks.append(kick)

	return jlstz_kicks




func get_i_piece_offset_data(rotation_state: int) -> Array[Vector2i]:
	match rotation_state:
		0:
			return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, 0)]
		1:
			return [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 2)]
		2:
			return [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-2, -1), Vector2i(1, 0), Vector2i(-2, 0)]
		3:
			return [Vector2i(0, -1), Vector2i(0, -1), Vector2i(0, -1), Vector2i(0, 1), Vector2i(0, -2)]
		_:
			return [Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)]





func get_i_piece_wall_kicks(from_rotation: int, to_rotation: int) -> Array[Vector2i]:
	var from_offsets: Array[Vector2i] = get_i_piece_offset_data(from_rotation)
	var to_offsets: Array[Vector2i] = get_i_piece_offset_data(to_rotation)

	var kicks: Array[Vector2i] = []



	for i in range(5):
		var kick: Vector2i = from_offsets[i] - to_offsets[i]
		kicks.append(kick)

	return kicks


func update_visual_position() -> void :
	if position_tween and position_tween.is_running():
		position_tween.stop()

	var target_position: Vector2 = Vector2(grid_position.x * PieceRenderer.PIECE_SIZE, grid_position.y * PieceRenderer.PIECE_SIZE)

	position = target_position





func update_ghost_position() -> void :
	var ghost_position = calculate_drop_position()

	var absolute_ghost_pos = Vector2(ghost_position.x * PieceRenderer.PIECE_SIZE, ghost_position.y * PieceRenderer.PIECE_SIZE)
	var current_piece_pos = Vector2(grid_position.x * PieceRenderer.PIECE_SIZE, grid_position.y * PieceRenderer.PIECE_SIZE)

	ghost_renderer.position = absolute_ghost_pos - current_piece_pos

func calculate_drop_position() -> Vector2i:
	var test_position = grid_position

	if GameManager.current_boss == GameData.BossTypes.FALL_UP:

		while is_valid_position(test_position + Vector2i(0, -1), current_rotation):
			test_position.y -= 1
	else:

		while is_valid_position(test_position + Vector2i(0, 1), current_rotation):
			test_position.y += 1

	return test_position

func is_valid_position(test_position: Vector2i, test_rotation: int) -> bool:
	if current_piece_data.is_empty():
		return false

	var piece_blocks = piece_renderer.get_piece_blocks(current_piece_data.shape, test_rotation)


	for block in piece_blocks:
		var world_block = test_position + block


		if world_block.x < 0:
			return false


		if world_block.x >= BOARD_WIDTH:
			return false


		if GameManager.current_boss == GameData.BossTypes.FALL_UP:

			if world_block.y < 0:
				return false
		else:

			if world_block.y >= BOARD_HEIGHT:
				return false


		if board and board.is_position_occupied(world_block):
			return false



	return true


func get_current_blocks() -> Array[Vector2i]:

	var piece_blocks = piece_renderer.get_piece_blocks(current_piece_data.shape, current_rotation)
	var world_blocks: Array[Vector2i] = []

	for block in piece_blocks:
		world_blocks.append(grid_position + block)

	return world_blocks

func get_piece_bounds() -> Rect2i:

	var local_bounds = piece_renderer.get_piece_bounds(current_piece_data.shape, current_rotation)
	return Rect2i(
		grid_position + local_bounds.position, 
		local_bounds.size
	)
