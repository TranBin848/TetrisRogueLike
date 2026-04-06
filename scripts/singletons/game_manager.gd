extends Node

signal next_piece_calculated()
signal moving_piece_spawned(moving_piece: MovingPiece)
signal hold_piece_changed()
signal timescale_changed()
signal score_changed(value: Big)
signal points_changed(value: Big)
signal multiplier_changed(value: Big)
signal calculation_finished()
signal calculation_blocker_finished()
signal rolls_changed(value: int)
signal coins_changed(value: int)

signal second_passed()

signal input_remapped()

signal pieces_finished()
signal piece_landed(blocks: Array[PlacedBlock], rotated: bool)
signal block_destroyed(block: PlacedBlock)


const STEAM_URL: String = "https://store.steampowered.com/app/3908810/Stackflow"
const DISCORD_URL: String = "https://discord.com/invite/UbAUwg2Fvc"


const ROUND_SCORES_BASE: Array[int] = [
	50, 
	100, 
	300, 
	600, 
	1500, 
	2500, 
	5000, 
	10000, 
	20000, 
	40000, 
	60000, 
	80000, 
	100000, 
	150000, 
	250000, 
	500000, 
	1000000, 
	2000000, 
	5000000, 
	10000000, 
	25000000
]

const DEMO_LAST_ROUND: int = 12
const BOSS_COOLDOWN_ROUNDS: int = 2
const MOUSE_IDLE_TIMEOUT: float = 2.0



var is_demo_build: bool = _detect_demo_build()


var paused: bool = false

var timescale: float = 1.0:
	set(value):
		timescale = value
		timescale_changed.emit()


var time_passed_raw: float = 0.0
var time_passed: float = 0.0
var time_passed_in_seconds: int = 0

var show_tutorial: bool = true

var settings: SettingsResource

var deathline: bool = false

var current_round: int = 1
var current_boss: GameData.BossTypes = GameData.BossTypes.NONE
var current_deck: GameData.DeckTypes = GameData.DeckTypes.NORMAL

var rotated_piece_on_current_round: bool = false

var score: Big = Big.new(0):
	set(value):
		if value is Big:
			score = value
		else:
			score = Big.new(value)

		score_changed.emit(score)

var target_score: Big = Big.new(0):
	set(value):
		if value is Big:
			target_score = value
		else:
			target_score = Big.new(value)


var points: Big = Big.new(0):
	set(value):
		if value is Big:
			points = value
		else:
			points = Big.new(value)

		points_changed.emit(points)

var multiplier: Big = Big.new(1):
	set(value):
		if value is Big:
			multiplier = value
		else:
			multiplier = Big.new(value)

		multiplier_changed.emit(multiplier)

var rolls_left: int = 5:
	set(value):
		rolls_left = value
		rolls_changed.emit(rolls_left)

var coins: int = 0:
	set(value):
		coins = value
		coins_changed.emit(coins)

const MAX_PERK_SLOTS: int = 6
const MAX_PERK_LEVEL: int = 5
const LEVELED_PERKS: Array[GameData.Perks] = [
	GameData.Perks.SPEED_RUN, 
	GameData.Perks.ACCEPTANCE, 
	GameData.Perks.LAST_BREATH, 
	GameData.Perks.CHAIN_REACTION
]

const SPEED_RUN_STACK_BY_LEVEL: Array[int] = [3, 10, 25, 35, 100]
const ACCEPTANCE_FLOW_BY_LEVEL: Array[int] = [5, 8, 12, 15, 30]
const LAST_BREATH_PERCENT_BY_LEVEL: Array[float] = [0.1, 0.15, 0.2, 0.25, 0.4]
const CHAIN_REACTION_FLOW_BY_LEVEL: Array[int] = [1, 5, 10, 12, 20]

var perk_levels: Dictionary[GameData.Perks, int] = {}
var perks_used: Array[GameData.Perks] = []
var cumulative_perks: Dictionary[GameData.Perks, int] = {}


var boss_usage_history: Dictionary = {}


var pieces_played: int = 0


var best_score: Big = Big.new(0)
var blocks_rolled_count: int = 0
var blocks_skipped_count: int = 0

var last_cleared_line_count: int = 0
var last_combo_points: float = 0.0
var last_combo_multiplier: float = 0.0
var last_combo_total: float = 0.0


var original_pieces: Dictionary[PieceRenderer.ShapeType, Array] = {}
var pieces: Dictionary[PieceRenderer.ShapeType, Array] = {}
var piece_queue: Array[PieceRenderer.ShapeType] = []

var next_piece_cache: Dictionary = {}:
	set(value):
		next_piece_cache = value
		next_piece_calculated.emit()

var hold_piece_data: Dictionary = {}


var placed_blocks_by_type: Dictionary = {}
var placed_blocks_by_group: Dictionary = {}


var next_action_frame: int = 0

var main_viewport: SubViewport

var is_calculating: bool = false
var awaiting_calculation_blocker: bool = false

var current_modal: ModalRect = null
var current_moving_piece: MovingPiece

var _mouse_idle_timer: float = 0.0
var is_gamepad_connected: bool = false


func _ready() -> void :
	load_and_apply_settings()
	generate_piece_queue()
	#load_game_save()


	if OS.is_debug_build():
		verify_all_translations()


	is_gamepad_connected = Input.get_connected_joypads().size() > 0


	Input.joy_connection_changed.connect( func(_device: int, _connected: bool):
		is_gamepad_connected = Input.get_connected_joypads().size() > 0

		if is_gamepad_connected:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)

	EventManager.queue_finished.connect( func():
		if awaiting_calculation_blocker:
			return

		if CalculationBlocker.active_count > 0:
			awaiting_calculation_blocker = true

			print("[GameManager] Waiting for CalculationBlocker to finish...")
			await calculation_blocker_finished
			print("[GameManager] CalculationBlocker finished.")

		await get_tree().create_timer(1.0 / timescale).timeout

		var total: Big = points.multiply(multiplier)

		score = score.plus(total)
		last_combo_total = total.to_float()
		last_combo_points = points.to_float()
		last_combo_multiplier = multiplier.to_float()

		#if multiplier.is_greater_than_or_equal_to(100):
			#AchievementManager.unlock(AchievementManager.AchievementId.THE_X)
#
		#AchievementManager.set_progress(AchievementManager.AchievementId.POINTS_100_000_COMBO, total.to_float())
		#AchievementManager.set_progress(AchievementManager.AchievementId.POINTS_500_000_COMBO, total.to_float())

		PlacedBlock.destroy_base_pitch = randf_range(0.4, 0.6)

		points = Big.new(0)
		multiplier = Big.new(1)
		calculation_finished.emit()

		awaiting_calculation_blocker = false
	)


	var second_timer: Timer = Timer.new()
	add_child(second_timer)

	second_timer.wait_time = 1.0
	second_timer.one_shot = false
	second_timer.start()

	second_timer.timeout.connect( func():
		#if is_game_busy():
			#return

		time_passed_in_seconds += 1
		second_passed.emit()
	)


func _process(delta: float) -> void :
	time_passed_raw += delta
	time_passed += delta * timescale

	_mouse_idle_timer += delta


	if is_gamepad_connected and _mouse_idle_timer >= MOUSE_IDLE_TIMEOUT:
		if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _input(event: InputEvent) -> void :
	if event is InputEventMouseMotion:
		_mouse_idle_timer = 0.0
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if OS.is_debug_build():
		if event is InputEventKey:
			if event.pressed:
				if event.keycode == KEY_1:
					_debug_create_piece(PieceRenderer.ShapeType.O, GameData.BLOCK_TYPES.GOLD)
					
				elif event.keycode == KEY_2:
					_debug_create_piece(PieceRenderer.ShapeType.I, GameData.BLOCK_TYPES.BLUE_C)
					
				elif event.keycode == KEY_3:
					_debug_create_piece(PieceRenderer.ShapeType.T, GameData.BLOCK_TYPES.RED_C)
					
				elif event.keycode == KEY_4:
					_debug_create_piece(PieceRenderer.ShapeType.O, GameData.BLOCK_TYPES.SAND)
					
				elif event.keycode == KEY_5:
					_debug_create_piece(PieceRenderer.ShapeType.J, GameData.BLOCK_TYPES.RAINBOW)

				#elif event.keycode == KEY_F5:
					#AchievementManager.reset_all_achievements()


func load_and_apply_settings() -> void :
	settings = SettingsResource.load_from_disk()

	if settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	#VisualEffects.enabled = settings.bloom

	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(settings.music_volume))
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(settings.effect_volume))

	timescale = settings.game_speed

	TranslationServer.set_locale(settings.locale)


	#if settings.speedrun_timer_enabled:
		#SpeedrunTimerLayer.activate()
	#else:
		#SpeedrunTimerLayer.deactivate()


#func save_game() -> void :
	#var save_resource: SaveResource = SaveResource.new()
	#save_resource.current_round = current_round
	#save_resource.perk_levels = perk_levels.duplicate()
	#save_resource.original_pieces = original_pieces.duplicate(true)
	#save_resource.rolls_left = rolls_left
	#save_resource.boss_usage_history = boss_usage_history.duplicate()
	#save_resource.deck_type = current_deck
	#save_resource.best_score = best_score.to_plain_scientific()
	#save_resource.blocks_rolled_count = blocks_rolled_count
	#save_resource.blocks_skipped_count = blocks_skipped_count
	#save_resource.speedrun_time = SpeedrunTimerLayer.timepassed
	#save_resource.seed_string = Random.get_current_seed_string()
	#save_resource.cumulative_perks = cumulative_perks.duplicate()
	#save_resource.write()

#func load_game_save() -> void :
	#var save_resource: SaveResource = SaveResource.load_from_disk()
#
	#if save_resource != null:
		#current_round = save_resource.current_round
#
#
		#if save_resource.perk_levels != null and save_resource.perk_levels.size() > 0:
			#perk_levels = save_resource.perk_levels.duplicate()
		#elif save_resource.current_perks != null and save_resource.current_perks.size() > 0:
#
			#perk_levels.clear()
			#for perk: GameData.Perks in save_resource.current_perks:
				#perk_levels[perk] = 1
			#print("🔄 Migrated old perk system: converted %d perks to level 1" % perk_levels.size())
		#else:
			#perk_levels.clear()
#
		#original_pieces.assign(_migrate_original_pieces(save_resource.original_pieces.duplicate(true)))
		#target_score = Big.new(calculate_round_score(current_round))
#
		#if not save_resource.seed_string.is_empty():
			#Random.set_custom_seed(save_resource.seed_string)
#
#
		#rolls_left = save_resource.rolls_left if save_resource.rolls_left > 0 else 5
#
#
		#if save_resource.boss_usage_history != null:
			#boss_usage_history = save_resource.boss_usage_history.duplicate()
			#print("🔄 Loaded boss usage history from save file")
		#else:
			#boss_usage_history.clear()
			#print("🎲 Starting fresh boss usage history")
#
#
		#current_deck = save_resource.deck_type as GameData.DeckTypes
		#print("🎨 Loaded deck type: %d" % current_deck)
#
#
		#best_score = Big.new(save_resource.best_score) if save_resource.best_score != "" else Big.new(0)
		#blocks_rolled_count = save_resource.blocks_rolled_count
		#blocks_skipped_count = save_resource.blocks_skipped_count
		#print("📊 Loaded statistics - Best: %s, Rolled: %d, Skipped: %d" % [best_score.to_scientific(true), blocks_rolled_count, blocks_skipped_count])
#
#
		#SpeedrunTimerLayer.timepassed = save_resource.speedrun_time
		#print("⏱️ Loaded speedrun time: %.2f seconds" % save_resource.speedrun_time)
#
#
		#if save_resource.cumulative_perks != null:
			#cumulative_perks = save_resource.cumulative_perks.duplicate()
			#print("📈 Loaded cumulative perks: %s" % str(cumulative_perks))
		#else:
			#cumulative_perks.clear()
#
		#pieces.clear()
		#for shape_type: PieceRenderer.ShapeType in original_pieces:
			#pieces[shape_type] = original_pieces[shape_type].duplicate()
	#else:
#
		#boss_usage_history.clear()
		#perk_levels.clear()


func _migrate_original_pieces(raw_pieces: Dictionary) -> Dictionary:
	var migrated: Dictionary = {}
	for shape_type in raw_pieces:
		var block_list: Array = raw_pieces[shape_type]
		var migrated_list: Array = []
		for bt in block_list:
			if bt is int:
				migrated_list.append(GameData.migrate_block_type_from_int(bt))
			else:
				migrated_list.append(bt)
		migrated[shape_type] = migrated_list
	return migrated


#func has_save_file() -> bool:
	#return SaveResource.save_exists()
#
#
#func delete_save_file() -> void :
	#SaveResource.delete_save()


func get_current_scene() -> Node:
	var viewport = get_tree().current_scene.find_child("MainViewport", true, false)
	if viewport and viewport.get_child_count() > 0:
		return viewport.get_child(0)
	return get_tree().current_scene


func get_unique_node(unique_name: String) -> Node:
	var scene = get_current_scene()
	if scene:
		return scene.get_node_or_null("%" + unique_name)
	return null



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
			var block_type: String = _weighted_pick_block_type(pieces_of_shape)
			next_piece_cache = {"type": block_type, "shape": next_shape, "queue_index": i}
			return


	for shape_type in pieces.keys():
		if pieces[shape_type].size() > 0:

			piece_queue.append(shape_type)
			var block_type: String = _weighted_pick_block_type(pieces[shape_type])
			next_piece_cache = {"type": block_type, "shape": shape_type, "queue_index": piece_queue.size() - 1}
			return


	if not hold_piece_data.is_empty():
		next_piece_cache = {"type": hold_piece_data.type, "shape": hold_piece_data.shape}
		hold_piece_data = {}
		hold_piece_changed.emit()
		print("[GameManager] Used piece from hold: ", GameData.get_block_name(next_piece_cache.type))
		return

	# Fallback: if no pieces available, use default block
	print("\n[GameManager] No pieces available in the queue!")
	print("[GameManager] Remaining count: ", get_remaining_pieces_count())
	print("[GameManager] Using fallback default block")
	
	var fallback_shape = PieceRenderer.ShapeType.I
	var fallback_block = get_current_default_block()
	next_piece_cache = {"type": fallback_block, "shape": fallback_shape, "queue_index": 0}
	if piece_queue.is_empty():
		piece_queue.append(fallback_shape)
	
	pieces_finished.emit()


func _weighted_pick_block_type(available_blocks: Array) -> String:
	var normal_blocks: Array[String] = []
	var special_blocks: Array[String] = []
	var default_block: String = get_current_default_block()

	for block_type: String in available_blocks:
		if block_type == default_block:
			normal_blocks.append(block_type)
		else:
			special_blocks.append(block_type)

	if not special_blocks.is_empty():
		var random_value: float = Random.randf()

		if random_value < 0.7:
			return Random.pick_random(special_blocks)
		elif not normal_blocks.is_empty():
			return Random.pick_random(normal_blocks)
		else:
			return Random.pick_random(special_blocks)

	return Random.pick_random(normal_blocks)


func get_next_piece() -> Dictionary:
	if next_piece_cache.has("type") and next_piece_cache.has("shape"):
		return {"type": next_piece_cache.type, "shape": next_piece_cache.shape}

	return {}


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


func get_remaining_pieces_count() -> int:
	var total_count: int = 0

	for key in pieces:
		total_count += pieces[key].size()

	return total_count


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


func add_piece_to_original_deck(block_type: String, shape_type: PieceRenderer.ShapeType) -> void :
	print("🧱 Add piece to deck: ", GameData.get_block_name(block_type))

	if not original_pieces.has(shape_type):
		original_pieces[shape_type] = []

	original_pieces[shape_type].append(block_type)


func add_points(value) -> void :
	if value is Big:
		points = points.plus(value)
	else:
		points = points.plus(Big.new(value))

func add_coins(value: int) -> void :
	coins += value

func add_multiplier(value) -> void :
	if value is Big:
		multiplier = multiplier.plus(value)
	else:
		multiplier = multiplier.plus(Big.new(value))


func is_game_busy() -> bool:
	return (paused or 
		EventManager.has_pending_events() or 
		is_calculating)


func is_perk_active(perk: GameData.Perks) -> bool:
	return perk_levels.has(perk) and perk_levels[perk] > 0


func get_perk_level(perk: GameData.Perks) -> int:
	return perk_levels.get(perk, 0)


func get_unique_perk_count() -> int:
	return perk_levels.size()


func can_upgrade_perk(perk: GameData.Perks) -> bool:
	if perk not in LEVELED_PERKS:
		return false

	var current_level: int = get_perk_level(perk)
	return current_level < MAX_PERK_LEVEL




func can_select_another_perk() -> bool:
	if get_unique_perk_count() < MAX_PERK_SLOTS:
		return true
	for perk: GameData.Perks in perk_levels:
		if can_upgrade_perk(perk):
			return true
	return false


func is_perk_used(perk: GameData.Perks) -> bool:
	return is_perk_active(perk) and perks_used.has(perk)


func trigger_cumulative_perk(perk: GameData.Perks, amount: int = 1) -> void:
	if not GameManager.perks_used.has(perk):
		GameManager.perks_used.append(perk)

	if not cumulative_perks.has(perk):
		cumulative_perks[perk] = 0

	cumulative_perks[perk] += amount

	if GameManager.is_perk_active(GameData.Perks.CHAIN_REACTION) and perk != GameData.Perks.CHAIN_REACTION:
		GameManager.trigger_perk(GameData.Perks.CHAIN_REACTION)

	match perk:
		GameData.Perks.PAUPER:
			var stack_count: int = cumulative_perks[perk]
			add_points(stack_count * 10)
			#InGamePerksContainer.spawn_point_notification(perk, PointNotification.BLUE, "+%d" % (stack_count * 10))

		GameData.Perks.PERFECTION:
			var stack_count: int = cumulative_perks[perk]
			add_multiplier(stack_count * 5)
			#InGamePerksContainer.spawn_point_notification(perk, PointNotification.RED, "+%d" % (stack_count * 5))

		GameData.Perks.MOMENTUM:
			var stack_count: int = cumulative_perks[perk]
			var total: int = stack_count * 10

			add_points(total)

			#InGamePerksContainer.spawn_point_notification(perk, PointNotification.BLUE, "+%d" % total)


func reset_cumulative_perk(perk: GameData.Perks) -> void:
	if cumulative_perks.has(perk):
		cumulative_perks.erase(perk)


func trigger_perk(perk: GameData.Perks) -> void:
	GameManager.perks_used.append(perk)

	if GameManager.is_perk_active(GameData.Perks.CHAIN_REACTION) and perk != GameData.Perks.CHAIN_REACTION:
		GameManager.trigger_perk(GameData.Perks.CHAIN_REACTION)

	match perk:

		GameData.Perks.POINT_RUSH:
			pass
			#InGamePerksContainer.pulse_perk_icon(GameData.Perks.POINT_RUSH)

		GameData.Perks.SHORTCUT:
			var shortcut_percentage_value: Big = target_score.multiply(0.25)
			target_score = target_score.minus(shortcut_percentage_value)

		GameData.Perks.AUTOMAGIC:
			add_points(10)

		GameData.Perks.SPEED_RUN:
			var level: int = get_perk_level(GameData.Perks.SPEED_RUN)
			if level == 0:
				level = 1
			level = clamp(level, 1, 5)
			var points_value: int = SPEED_RUN_STACK_BY_LEVEL[level - 1]
			add_points(points_value)

		GameData.Perks.ACCEPTANCE:
			var level: int = get_perk_level(GameData.Perks.ACCEPTANCE)
			if level == 0:
				level = 1
			level = clamp(level, 1, 5)
			var multiplier_value: int = ACCEPTANCE_FLOW_BY_LEVEL[level - 1]
			add_multiplier(multiplier_value)

		GameData.Perks.CHAIN_REACTION:
			var level: int = get_perk_level(GameData.Perks.CHAIN_REACTION)
			if level == 0:
				level = 1
			level = clamp(level, 1, 5)
			var multiplier_value: int = CHAIN_REACTION_FLOW_BY_LEVEL[level - 1]
			add_multiplier(multiplier_value)

		GameData.Perks.LAST_BREATH:
			var level: int = get_perk_level(GameData.Perks.LAST_BREATH)
			if level == 0:
				level = 1
			level = clamp(level, 1, 5)
			var percentage: float = LAST_BREATH_PERCENT_BY_LEVEL[level - 1]
			var target_score_percentage: Big = target_score.multiply(percentage)
			add_points(target_score_percentage)

		GameData.Perks.SACRIFICE:
			var sacrifice_percentage_value: Big = target_score.multiply(0.05)
			target_score = target_score.minus(sacrifice_percentage_value)

		GameData.Perks.STACK_MASTER:
			EventManager.add_event_last( func() -> float:
				GameManager.multiplier = GameManager.multiplier.multiply(2)
				return BlockChainReaction.DEFAULT_DELAY
			)

		GameData.Perks.FULL_CLEAR:
			EventManager.add_event_last( func() -> float:
				if GameManager.get_board().is_fully_clear():
					GameManager.points = GameManager.points.multiply(3)
					GameManager.multiplier = GameManager.multiplier.multiply(3)
				return BlockChainReaction.DEFAULT_DELAY
			)


func add_placed_block(block_instance: PlacedBlock, block_type: String) -> void :

	if not placed_blocks_by_type.has(block_type):
		placed_blocks_by_type[block_type] = []

	placed_blocks_by_type[block_type].append(block_instance)

	var groups: Array[GameData.BlockGroups] = []
	groups.assign(GameData.blocks[block_type].groups)

	for group in groups:
		if not placed_blocks_by_group.has(group):
			placed_blocks_by_group[group] = []

		placed_blocks_by_group[group].append(block_instance)



func remove_placed_block(block_instance: PlacedBlock, block_type: String) -> void :
	if placed_blocks_by_type.has(block_type):
		placed_blocks_by_type[block_type].erase(block_instance)

		if placed_blocks_by_type[block_type].is_empty():
			placed_blocks_by_type.erase(block_type)

	var groups: Array[GameData.BlockGroups] = []
	groups.assign(GameData.blocks[block_type].groups)

	for group in groups:
		if placed_blocks_by_group.has(group):
			placed_blocks_by_group[group].erase(block_instance)

			if placed_blocks_by_group[group].is_empty():
				placed_blocks_by_group.erase(group)


func get_blocks_of_type(block_type: String) -> Array[PlacedBlock]:

	if not placed_blocks_by_type.has(block_type):
		return []


	var valid_blocks: Array[PlacedBlock] = []
	for block in placed_blocks_by_type[block_type]:
		if is_instance_valid(block):
			valid_blocks.append(block)


	placed_blocks_by_type[block_type] = valid_blocks

	return valid_blocks.duplicate()


func get_blocks_of_group(block_group: GameData.BlockGroups) -> Array[PlacedBlock]:

	if not placed_blocks_by_group.has(block_group):
		return []


	var valid_blocks: Array[PlacedBlock] = []
	for block in placed_blocks_by_group[block_group]:
		if is_instance_valid(block):
			valid_blocks.append(block)


	placed_blocks_by_group[block_group] = valid_blocks

	return valid_blocks.duplicate()


func clear_placed_blocks_variables() -> void :
	placed_blocks_by_type.clear()
	placed_blocks_by_group.clear()


func has_block_type_in_original_deck(block_type: String) -> bool:
	for shape_type: PieceRenderer.ShapeType in original_pieces:
		for piece_block_type: String in original_pieces[shape_type]:
			if piece_block_type == block_type:
				return true
	return false



func get_active_groups_in_deck() -> Array[GameData.BlockGroups]:
	var active_groups: Array[GameData.BlockGroups] = []

	for shape_type: PieceRenderer.ShapeType in original_pieces:
		for block_type: String in original_pieces[shape_type]:
			if GameData.blocks.has(block_type):
				var block_data: BlockData = GameData.blocks[block_type]
				for group in block_data.groups:
					if group not in active_groups and group != GameData.BlockGroups.DEFAULT:
						active_groups.append(group)

	return active_groups


#func restart() -> void :
	#Transition.restart( func():
		#reset_variables()
		#SpeedrunTimerLayer.resume_timer()
	#)


func reset_variables() -> void :
	current_round = 1
	pieces_played = 0

	score = Big.new(0)
	target_score = Big.new(calculate_round_score(current_round))

	perk_levels.clear()
	perks_used.clear()
	cumulative_perks.clear()

	deathline = false

	points = Big.new(0)
	multiplier = Big.new(1)
	rolls_left = 5
	is_calculating = false

	hold_piece_data = {}

	last_cleared_line_count = 0
	last_combo_points = 0
	last_combo_multiplier = 0
	last_combo_total = 0

	rotated_piece_on_current_round = false

	clear_placed_blocks_variables()

	CalculationBlocker.active_count = 0

	#AudioManager.set_music_filter_enabled(false)
#
#
	#SpeedrunTimerLayer.reset_timer()
	#SpeedrunTimerLayer.pause_timer()

	generate_piece_queue()
	boss_usage_history.clear()
	hold_piece_changed.emit()


func goto_board() -> void :
	Transition.goto(Transition.Scene.GAME, func():
		score = Big.new(0)
		target_score = Big.new(calculate_round_score(current_round))

		CalculationBlocker.active_count = 0

		hold_piece_data = {}
		hold_piece_changed.emit()

		#AudioManager.set_music_filter_enabled(false)
	)


func goto_level_selection() -> void :
	#SpeedrunTimerLayer.resume_timer()

	Transition.goto(Transition.Scene.LEVEL_SELECTION, func():
		reset_pieces_to_original()
		#AudioManager.set_music_filter_enabled(false)
	)


func get_board() -> Board:
	return get_unique_node("Board") as Board


func spawn_moving_piece() -> MovingPiece:
	var next_piece: Dictionary = consume_next_piece()
	if OS.is_debug_build():
		print("[RenderDebug] spawn_moving_piece() next_piece=", next_piece)
	var moving_piece: MovingPiece = MovingPiece.create(get_unique_node("Board"), next_piece)

	current_moving_piece = moving_piece

	moving_piece_spawned.emit(moving_piece)

	return moving_piece


#func use_roll() -> void :
	#if rolls_left > 0:
		#rolls_left -= 1
		#blocks_rolled_count += 1
		#save_game()
#
#
#func add_rolls(amount: int) -> void :
	#rolls_left += amount
	#save_game()
#
#
#func increment_blocks_skipped() -> void :
	#blocks_skipped_count += 1
	#save_game()


func can_roll() -> bool:
	return rolls_left > 0




func calculate_round_score(round_num: int) -> Big:
	if round_num <= 0:
		return Big.new(0)


	if round_num <= ROUND_SCORES_BASE.size():
		return Big.new(ROUND_SCORES_BASE[round_num - 1])






	var last_known_score: Big = Big.new(ROUND_SCORES_BASE[ROUND_SCORES_BASE.size() - 1])
	var rounds_beyond: int = round_num - ROUND_SCORES_BASE.size()


	var base_score: Big = last_known_score.duplicate()

	for i in range(rounds_beyond):
		var calculated_round: int = ROUND_SCORES_BASE.size() + i + 1
		var position_in_cycle: int = calculated_round % 3

		if position_in_cycle == 1:
			base_score = base_score.multiply(1.5)
		elif position_in_cycle == 2:
			base_score = base_score.multiply(1.75)
		else:
			base_score = base_score.multiply(2.0)

	return base_score


func get_boss_for_round(round_num: int) -> GameData.BossTypes:

	if round_num % 3 != 0:
		return GameData.BossTypes.NONE


	for boss_type in boss_usage_history:
		if boss_usage_history[boss_type] == round_num:
			return boss_type


	var all_boss_types: Array[GameData.BossTypes] = []
	all_boss_types.assign(GameData.BossTypes.values())
	all_boss_types.erase(GameData.BossTypes.NONE)


	var available_bosses: Array[GameData.BossTypes] = []
	for boss_type in all_boss_types:
		var can_use: bool = true

		if boss_usage_history.has(boss_type):
			var last_used_round: int = boss_usage_history[boss_type]
			var boss_rounds_passed: int = (round_num - last_used_round) / 3

			if boss_rounds_passed <= BOSS_COOLDOWN_ROUNDS:
				can_use = false

		if can_use:
			available_bosses.append(boss_type)


	if available_bosses.is_empty():
		available_bosses = all_boss_types.duplicate()


	var selected_boss: GameData.BossTypes = Random.pick_random(available_bosses)
	boss_usage_history[selected_boss] = round_num

	print("🎯 Round %d boss: %s (cooldown system)" % [round_num, GameData.get_boss_name(selected_boss)])

	return selected_boss


func replace_tags(description: String) -> String:

	var group_regex: RegEx = RegEx.new()
	group_regex.compile("\\[group:(\\w+)\\]")

	var group_matches: Array[RegExMatch] = group_regex.search_all(description)
	for match_result: RegExMatch in group_matches:
		var group_name: String = match_result.get_string(1).to_upper()
		var group_key: String = "BLOCK_GROUP_" + group_name


		var block_group: GameData.BlockGroups = GameData.BlockGroups.DEFAULT
		for group_enum_value: GameData.BlockGroups in GameData.BlockGroups.values():
			if GameData.get_block_group_name(group_enum_value) == group_name:
				block_group = group_enum_value
				break


		var font_color: Color = Color.WHITE

		if GameData.GROUP_COLOR_MAP.has(block_group):
			font_color = GameData.GROUP_COLOR_MAP[block_group]["font_color"]


		var replacement: String = "[color=#%s]%s[/color]" % [
			font_color.to_html(false), 
			tr(group_key)
		]

		description = description.replace(match_result.get_string(0), replacement)


	var points_regex: RegEx = RegEx.new()
	points_regex.compile("\\[points:([+-]?x?\\d+(?:\\.\\d+)?(?:-\\d+(?:\\.\\d+)?)?)\\]")

	var points_matches: Array[RegExMatch] = points_regex.search_all(description)
	for match_result: RegExMatch in points_matches:
		var points_value: String = match_result.get_string(1)
		var replacement: String = "[blue]%s %s[white]" % [
			points_value, 
			tr("POINTS")
		]

		description = description.replace(match_result.get_string(0), replacement)


	var multiplier_regex: RegEx = RegEx.new()
	multiplier_regex.compile("\\[multiplier:([+-]?x?\\d+(?:\\.\\d+)?(?:-\\d+(?:\\.\\d+)?)?)\\]")

	var multiplier_matches: Array[RegExMatch] = multiplier_regex.search_all(description)
	for match_result: RegExMatch in multiplier_matches:
		var multiplier_value: String = match_result.get_string(1)
		var replacement: String = "[red]%s %s[white]" % [
			multiplier_value, 
			tr("MULTIPLIER")
		]

		description = description.replace(match_result.get_string(0), replacement)


	var block_regex: RegEx = RegEx.new()
	block_regex.compile("\\[block:(\\w+)\\]")

	var block_matches: Array[RegExMatch] = block_regex.search_all(description)
	for match_result: RegExMatch in block_matches:
		var block_name: String = match_result.get_string(1).to_upper()
		var block_key: String = "BLOCK_" + block_name

		var replacement: String = "[yellow]%s[white]" % tr(block_key)

		description = description.replace(match_result.get_string(0), replacement)

	description = description.replace("[points]", "[blue]%s[white]" % tr("POINTS"))
	description = description.replace("[multiplier]", "[red]%s[white]" % tr("MULTIPLIER"))


	description = description.replace("[perk]", "[yellow]%s[white]" % tr("REWARD_PERK"))
	description = description.replace("[blue]", "[color=#00cdf9]")
	description = description.replace("[red]", "[color=#f5555d]")
	description = description.replace("[yellow]", "[color=#ffeb57]")
	description = description.replace("[white]", "[color=#ffffff]")


	return description


func verify_all_translations() -> void :
	var file: FileAccess = FileAccess.open("res://localization.csv", FileAccess.READ)

	if not file:
		print("🚫 [Translation Verification] Error: Could not open localization.csv file")
		return

	print("🔍 [Translation Verification] Starting translation verification for all languages...")

	var header_line: String = file.get_line()
	var columns: PackedStringArray = header_line.split(",")


	var language_columns: Dictionary = {}
	var language_names: Array[String] = []

	for i in range(1, columns.size()):
		var column_name: String = columns[i].strip_edges()
		if not column_name.is_empty():
			language_columns[column_name] = i
			language_names.append(column_name)

	if language_columns.is_empty():
		print("🚫 [Translation Verification] Error: No language columns found in CSV")
		file.close()
		return

	print("📍 [Translation Verification] Found languages: %s" % str(language_names))


	var language_stats: Dictionary = {}
	var missing_keys_by_language: Dictionary = {}

	for lang in language_names:
		language_stats[lang] = {"missing": 0, "total": 0}
		missing_keys_by_language[lang] = []


	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()

		if line.is_empty():
			continue


		var cells: PackedStringArray = _parse_csv_line(line)

		var key: String = cells[0].strip_edges() if cells.size() > 0 else ""


		if key == "EMPTY":
			continue


		for lang_name in language_names:
			var lang_index: int = language_columns[lang_name]
			language_stats[lang_name]["total"] += 1


			if cells.size() <= lang_index:
				language_stats[lang_name]["missing"] += 1
				missing_keys_by_language[lang_name].append(key)
				continue

			var translation: String = cells[lang_index].strip_edges()


			if _is_translation_empty(translation):
				language_stats[lang_name]["missing"] += 1
				missing_keys_by_language[lang_name].append(key)

	file.close()


	print("\n📊 [Translation Verification] Summary:")
	print("=======================================")

	var all_complete: bool = true

	for lang_name in language_names:
		var stats: Dictionary = language_stats[lang_name]
		var missing: int = stats["missing"]
		var total: int = stats["total"]
		var completion_percentage: float = (float(total - missing) / float(total)) * 100.0 if total > 0 else 0.0

		var status_icon: String = "✅" if missing == 0 else "❌"
		var lang_display: String = lang_name.to_upper()

		if missing == 0:
			print("%s [%s] All translations complete! (%d entries)" % [status_icon, lang_display, total])
		else:
			print("%s [%s] %d missing out of %d entries (%.1f%% complete)" % [status_icon, lang_display, missing, total, completion_percentage])
			all_complete = false

	print("=======================================")

	if all_complete:
		print("🎉 [Translation Verification] All languages are fully translated!")
	else:
		print("🔧 [Translation Verification] Please complete the missing translations in localization.csv")


		var all_missing_keys: Array[String] = []

		for lang_name in language_names:
			var missing_keys: Array = missing_keys_by_language[lang_name]
			for key in missing_keys:
				if not all_missing_keys.has(key):
					all_missing_keys.append(key)

		if not all_missing_keys.is_empty():
			print("\n📋 [Translation Verification] Missing Translation Checklist:")
			print("========================================")

			for key in all_missing_keys:
				print("- [ ] %s" % key)

			print("========================================")


func _parse_csv_line(line: String) -> PackedStringArray:
	"\n    Parse a CSV line handling quoted strings properly.\n    "


	var cells: PackedStringArray = []
	var current_cell: String = ""
	var in_quotes: bool = false
	var i: int = 0

	while i < line.length():
		var character: String = line[i]

		if character == "\"":
			if in_quotes and i + 1 < line.length() and line[i + 1] == "\"":

				current_cell += "\""
				i += 1
			else:

				in_quotes = not in_quotes
		elif character == "," and not in_quotes:

			cells.append(current_cell)
			current_cell = ""
		else:
			current_cell += character

		i += 1


	cells.append(current_cell)

	return cells


func _is_translation_empty(translation: String) -> bool:
	"\n    Check if a translation is considered empty.\n    Returns true if the translation is empty, just quotes, or only whitespace.\n    "



	var cleaned: String = translation.strip_edges()


	if cleaned.is_empty():
		return true


	if cleaned.length() >= 2 and cleaned.begins_with("\"") and cleaned.ends_with("\""):
		var inner_content: String = cleaned.substr(1, cleaned.length() - 2).strip_edges()
		return inner_content.is_empty()

	return false




func _detect_demo_build() -> bool:

	if OS.has_feature("demo"):
		print("Demo mode detected via custom feature flag!")
		return true


	print("Full version detected!")
	return false



func get_max_rounds() -> int:
	if is_demo_build:
		print("Demo build: limiting to ", DEMO_LAST_ROUND, " rounds")
		return DEMO_LAST_ROUND
	else:
		print("Full build: ", ROUND_SCORES_BASE.size(), " rounds available")
		return ROUND_SCORES_BASE.size()


func _debug_create_piece(shape_type: PieceRenderer.ShapeType, block_type: String) -> void :
	if is_instance_valid(current_moving_piece):
		current_moving_piece.queue_free()
		current_moving_piece = null

	var board: Board = get_unique_node("Board")

	if is_instance_valid(board):
		current_moving_piece = MovingPiece.create(board, {
			"type": block_type, 
			"shape": shape_type
		})
