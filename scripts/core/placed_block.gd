class_name PlacedBlock extends Node2D

signal destroyed()

const GROUP_NAME: String = "PlacedBlocks"

const OBSIDIAN_FORTRESS_VARIABLE: StringName = &"fortress_blocks_destroyed"
const CFOUR_VARIABLE: StringName = &"cfour_tick_count"
const CFOUR_ACTIVATION_THRESHOLD: int = 5

const SPAWN_ANIMATION_DURATION: float = 0.3
const SPAWN_ANIMATION_START: Vector2 = Vector2.ONE * 1.5
const DESTROY_ANIMATION_DELAY: float = 0.08


const Y_ANIMATION_DURATION: float = 0.3
const DESTROY_ANIMATION_DURATION: float = 0.3

const PLACEMENT_ANIMATION_DURATION: float = 0.3
const PLACEMENT_ANIMATION_FORCE: float = 5.0


const POINT_NOTIFICATION_SCENE: PackedScene = preload("res://scenes/point_notification.tscn")


static var destroy_base_pitch: float = randf_range(0.4, 0.6)

var type: String:
	set(value):

		_cleanup_timers()

		type = value

		var block_name: String = GameData.get_block_name(value)

		title = tr("BLOCK_" + block_name)
		description = GameManager.replace_tags(tr("BLOCK_" + block_name + "_DESCRIPTION"))

		add_to_group(GameData.get_block_name(value))
		const ACCELERATOR_MULT = 0.5;
		match type:
			GameData.BLOCK_TYPES.CFOUR:
				var tick_timer: Timer = Timer.new()
				add_child(tick_timer)

				tick_timer.name = "CFOURTickTimer"
				tick_timer.wait_time = 1.0 / GameManager.timescale
				if GameManager.is_perk_active(GameData.Perks.ACCELERATOR):
					tick_timer.wait_time *= ACCELERATOR_MULT;
				tick_timer.one_shot = false

				tick_timer.timeout.connect( func() -> void :
					if destroy_animation_requested:
						tick_timer.stop()
						tick_timer.queue_free()
						return

					if GameManager.is_game_busy():
						return

					custom_variables[CFOUR_VARIABLE] = (custom_variables.get(CFOUR_VARIABLE, 0)) + 1
					pulse_animation()


					#AudioManager.play(AudioManager.SoundEffects.SINGLE_CLICK_3, 1.6 + (custom_variables[CFOUR_VARIABLE] * 0.05))

					if custom_variables[CFOUR_VARIABLE] >= CFOUR_ACTIVATION_THRESHOLD:
						destroy()
				)

				tick_timer.start()

			GameData.BLOCK_TYPES.URANIUM:
				var morph_timer: Timer = Timer.new()

				add_child(morph_timer)

				morph_timer.name = "UraniumMorphTimer"
				morph_timer.wait_time = 5.0 / GameManager.timescale
				if GameManager.is_perk_active(GameData.Perks.ACCELERATOR):
					morph_timer.wait_time *= ACCELERATOR_MULT;
				morph_timer.one_shot = false

				morph_timer.timeout.connect( func() -> void :
					if destroy_animation_requested:
						morph_timer.stop()
						morph_timer.queue_free()
						return

					if GameManager.is_game_busy():
						return

					var adjacent_blocks: Array[PlacedBlock] = get_adjacent_blocks()
					var possible_blocks: Array[PlacedBlock] = []


					for block in adjacent_blocks:
						if is_instance_valid(block) and not block.destroy_animation_requested and not GameData.is_block_on_group(block.type, GameData.BlockGroups.NUCLEAR) and block.type != "indestructible":
							possible_blocks.append(block)


					if possible_blocks.size() > 0:
						var target_block: PlacedBlock = Random.pick_random(possible_blocks)
						target_block.morph(GameData.BLOCK_TYPES.URANIUM)

						GameCamera.shake_randomly(1, 0.1)
						#AudioManager.play(AudioManager.SoundEffects.RADIOACTIVE, randf_range(0.4, 0.6))

						var reactor_queue: Array[Callable] = []

						for reactor_block in GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.REACTOR):
							reactor_queue.append(BlockChainReaction.reactor.bind(reactor_block))

						EventManager.execute_queue_events(reactor_queue)
				)

				morph_timer.start()


var grid_position: Vector2i = Vector2i.ZERO

var y_target_value: float = 0.0
var animation_tween: Tween
var placement_animation_tween: Tween
var destroy_animation_requested: bool = false

var custom_variables: Dictionary = {}

var hover_tween: Tween
var pulse_animation_tween: Tween

var activation_count: int = 0

var title: String = ""
var description: String = ""

@onready var sprite_shadowed: SpriteShadowed = $SpriteShadowed
@onready var collision_area: Area2D = $CollisionArea
@onready var calculation_blocker: CalculationBlocker = $CalculationBlocker

func _ready() -> void :
	add_to_group(GROUP_NAME)

	GameManager.block_destroyed.connect( func(block: PlacedBlock) -> void :
		if type == GameData.BLOCK_TYPES.OBSIDIAN and GameData.is_block_on_group(block.type, GameData.BlockGroups.FORTRESS):
			custom_variables[OBSIDIAN_FORTRESS_VARIABLE] = (custom_variables.get(OBSIDIAN_FORTRESS_VARIABLE, 0)) + 1
			pulse_animation()
	)


func set_texture(texture: CompressedTexture2D) -> void :
	sprite_shadowed.main_sprite.modulate = Color.WHITE
	sprite_shadowed.texture = texture
	sprite_shadowed.shadow_texture = PieceRenderer.PIECE_SHADOW_SPRITE
	sprite_shadowed.shadow_color = PieceRenderer.PIECE_SHADOW_COLOR

	if destroy_animation_requested:
		return

	pulse_animation(false)


func set_grid_position(grid_pos: Vector2i, piece_size: int) -> void :
	grid_position = grid_pos
	position = Vector2(grid_pos.x * piece_size, grid_pos.y * piece_size)

	name = "PlacedBlock_" + str(grid_pos.x) + "x" + str(grid_pos.y)


	var is_deathline: bool = false

	if GameManager.current_boss == GameData.BossTypes.FALL_UP:

		is_deathline = grid_pos.y >= Board.DEATHLINE_BOTTOM_ROWS
	else:

		is_deathline = grid_pos.y <= Board.DEATHLINE_TOP_ROWS

	if is_deathline:
		#AudioManager.play(AudioManager.SoundEffects.DEATHLINE, randf_range(0.8, 1.2))
		GameCamera.shake_direction(4, 0, 0.5)
		GameManager.deathline = true

		var flash_tween: Tween = create_tween().set_loops()

		flash_tween.tween_callback( func():
			sprite_shadowed.visible = not sprite_shadowed.visible
		).set_delay(0.1)

		await get_tree().create_timer(2.0).timeout

		sprite_shadowed.visible = true
		flash_tween.kill()


func get_center_position() -> Vector2:
	return global_position + Vector2(PieceRenderer.PIECE_SIZE / 2, PieceRenderer.PIECE_SIZE / 2)


func morph(new_type: String) -> void :
	if type == new_type:
		return
	if type == "indestructible": return;

	var old_type: String = type
	type = new_type
	set_texture(load(GameData.get_block_texture_path(new_type)))


	GameManager.remove_placed_block(self, old_type)
	GameManager.add_placed_block(self, new_type)


func animate_y(target_y: float) -> void :
	if not is_inside_tree():
		return

	y_target_value = target_y

	if animation_tween and animation_tween.is_valid():
		animation_tween.kill()

	animation_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	animation_tween.tween_property(self, "position:y", target_y, Y_ANIMATION_DURATION)


func pulse_animation(flash_animation_enabled: bool = true) -> void :
	if destroy_animation_requested:
		return

	if pulse_animation_tween and pulse_animation_tween.is_valid():
		pulse_animation_tween.kill()

	pulse_animation_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
	pulse_animation_tween.tween_property(sprite_shadowed.main_sprite, "scale", Vector2.ONE, 0.5 / GameManager.timescale).from(Vector2.ONE * 1.5)
	pulse_animation_tween.tween_property(sprite_shadowed.shadow_sprite, "scale", Vector2.ONE, 0.5 / GameManager.timescale).from(Vector2.ONE * 1.5)

	if flash_animation_enabled:
		pulse_animation_tween.set_trans(Tween.TRANS_LINEAR)
		pulse_animation_tween.tween_property(sprite_shadowed.main_sprite, "modulate", Color.WHITE, 0.4 / GameManager.timescale).from(Color(1.5, 1.5, 1.5, 1.0))


func above_placement_animation() -> void :
	if placement_animation_tween and placement_animation_tween.is_valid():
		placement_animation_tween.kill()

	placement_animation_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()

	placement_animation_tween.tween_property(sprite_shadowed, "position:y", 6.0, PLACEMENT_ANIMATION_DURATION / GameManager.timescale).from(6.0 + PLACEMENT_ANIMATION_FORCE)


func get_adjacent_blocks() -> Array[PlacedBlock]:
	var adjacent_blocks: Array[PlacedBlock] = []

	for block: PlacedBlock in get_tree().get_nodes_in_group(PlacedBlock.GROUP_NAME):
		if block == self:
			continue

		var manhattan_distance: int = abs(block.grid_position.x - grid_position.x) + abs(block.grid_position.y - grid_position.y)
		if manhattan_distance <= 1:
			adjacent_blocks.append(block)

	return adjacent_blocks


func get_adjacent_blocks_of_type(block_type: String) -> Array[PlacedBlock]:
	var adjacent_blocks: Array[PlacedBlock] = []
	var block_type_name: String = GameData.get_block_name(block_type)

	for block: PlacedBlock in get_tree().get_nodes_in_group(block_type_name):
		if block == self:
			continue

		var manhattan_distance: int = abs(block.grid_position.x - grid_position.x) + abs(block.grid_position.y - grid_position.y)
		if manhattan_distance <= 1:
			adjacent_blocks.append(block)

	return adjacent_blocks


func get_blocks_in_range(search_range: int) -> Array[PlacedBlock]:
	var blocks_in_range: Array[PlacedBlock] = []

	for block: PlacedBlock in get_tree().get_nodes_in_group(PlacedBlock.GROUP_NAME):
		if block == self:
			continue

		var manhattan_distance: int = abs(block.grid_position.x - grid_position.x) + abs(block.grid_position.y - grid_position.y)
		if manhattan_distance <= search_range:
			blocks_in_range.append(block)

	return blocks_in_range


func get_blocks_in_range_of_type(search_range: int, block_type: String) -> Array[PlacedBlock]:
	var blocks_in_range: Array[PlacedBlock] = []
	var block_type_name: String = GameData.get_block_name(block_type)

	for block: PlacedBlock in get_tree().get_nodes_in_group(block_type_name):
		if block == self:
			continue

		var manhattan_distance: int = abs(block.grid_position.x - grid_position.x) + abs(block.grid_position.y - grid_position.y)
		if manhattan_distance <= search_range:
			blocks_in_range.append(block)

	return blocks_in_range


func _get_row_blocks(row: int) -> Array[PlacedBlock]:
	var row_blocks: Array[PlacedBlock] = []

	for block: PlacedBlock in get_tree().get_nodes_in_group(PlacedBlock.GROUP_NAME):
		if block.grid_position.y == row:
			row_blocks.append(block)

	return row_blocks


func _get_column_blocks(column: int) -> Array[PlacedBlock]:
	var column_blocks: Array[PlacedBlock] = []

	for block: PlacedBlock in get_tree().get_nodes_in_group(PlacedBlock.GROUP_NAME):
		if block.grid_position.x == column:
			column_blocks.append(block)

	return column_blocks



func _cleanup_timers() -> void :

	var cfour_timer: Timer = get_node_or_null("CFOURTickTimer")

	if is_instance_valid(cfour_timer):
		cfour_timer.stop()
		cfour_timer.queue_free()


	var uranium_timer: Timer = get_node_or_null("UraniumMorphTimer")

	if is_instance_valid(uranium_timer):
		uranium_timer.stop()
		uranium_timer.queue_free()


func destroy() -> void :
	
	if type == "indestructible":
		return
	calculation_blocker.activate()
	destroy_animation_requested = true

	destroyed.emit()

	remove_from_group(GROUP_NAME)

	var other_blocks: Array[PlacedBlock] = []

	other_blocks.assign(get_tree().get_nodes_in_group(PlacedBlock.GROUP_NAME))
	other_blocks.erase(self)

	#AudioManager.play(AudioManager.SoundEffects.BLOCK_DESTROY, PlacedBlock.destroy_base_pitch)
	PlacedBlock.destroy_base_pitch = min(PlacedBlock.destroy_base_pitch + 0.05, 1.8)

	GameManager.block_destroyed.emit(self)

	if animation_tween and animation_tween.is_valid():
		animation_tween.kill()

	sprite_shadowed.flash_sprite.visible = true

	animation_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	animation_tween.parallel().tween_property(sprite_shadowed.main_sprite, "scale", Vector2(1.2, 0), DESTROY_ANIMATION_DURATION / GameManager.timescale)
	animation_tween.parallel().tween_property(sprite_shadowed.shadow_sprite, "scale", Vector2(1.2, 0), DESTROY_ANIMATION_DURATION / GameManager.timescale)

	animation_tween.tween_callback( func():
		calculation_blocker.deactivate()

		GameManager.remove_placed_block(self, type)
		queue_free()
	)

	execute_destroy_effect()
	if GameManager.is_perk_active(GameData.Perks.RETRIGGER_BLOCK):
		execute_destroy_effect();


func execute_destroy_effect() -> void :
	var all_blocks_on_board: Array[PlacedBlock] = []

	all_blocks_on_board.assign(get_tree().get_nodes_in_group(PlacedBlock.GROUP_NAME))
	all_blocks_on_board.erase(self)

	if GameData.is_block_on_group(type, GameData.BlockGroups.CASINO) and type != GameData.BLOCK_TYPES.HONEY_DICE:
		var honey_dice_blocks: Array[PlacedBlock] = GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.HONEY_DICE)
		var colony_blocks_count: int = GameManager.get_blocks_of_group(GameData.BlockGroups.COLONY).size()

		var honey_dice_event_queue: Array[Callable] = []

		for block in honey_dice_blocks:
			honey_dice_event_queue.append(BlockChainReaction.honey_dice.bind(block, colony_blocks_count))

		if honey_dice_event_queue.size() > 0:
			EventManager.execute_queue_events(honey_dice_event_queue)

	
	if GameManager.is_perk_active(GameData.Perks.MULT_REACTOR):
		GameManager.trigger_perk(GameData.Perks.MULT_REACTOR);
	
	match type:
		GameData.BLOCK_TYPES.NORMAL:
			var points: int = 1

			if GameManager.is_perk_active(GameData.Perks.POINT_RUSH):
				GameManager.trigger_perk(GameData.Perks.POINT_RUSH)
				points *= 2

			GameManager.add_points(points)
			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, points)

		GameData.BLOCK_TYPES.MOAI:
			var points: int = 10

			if GameManager.is_perk_active(GameData.Perks.POINT_RUSH):
				GameManager.trigger_perk(GameData.Perks.POINT_RUSH)
				points *= 2

			GameManager.add_points(points)
			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, points)

		GameData.BLOCK_TYPES.X:
			var multi: int = 1

			if GameManager.is_perk_active(GameData.Perks.POINT_RUSH):
				GameManager.trigger_perk(GameData.Perks.POINT_RUSH)
				multi *= 2

			GameManager.add_multiplier(multi)
			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, multi)

		GameData.BLOCK_TYPES.GOLD:
			#GameManager.add_coins(2)
			PointNotification.create_and_slide(get_center_position(), PointNotification.YELLOW, "+2")

		GameData.BLOCK_TYPES.BLUE_C:
			GameManager.add_points(50)
			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, 50)

		GameData.BLOCK_TYPES.RED_C:
			GameManager.add_multiplier(4)
			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, 4)

		GameData.BLOCK_TYPES.RAINBOW:
			if Random.randf() <= 0.20:
				GameManager.add_multiplier(20)
				PointNotification.create_and_slide(get_center_position(), PointNotification.RED, 20)

		GameData.BLOCK_TYPES.LUCKY:
			var possible_shapes: Array = [PieceRenderer.ShapeType.I, PieceRenderer.ShapeType.O, PieceRenderer.ShapeType.T, PieceRenderer.ShapeType.S, PieceRenderer.ShapeType.Z, PieceRenderer.ShapeType.J, PieceRenderer.ShapeType.L]
			var random_shape = Random.pick_random(possible_shapes)
			var all_types: Array = GameData.BLOCK_TYPES.values()
			var random_type = Random.pick_random(all_types)

			if not GameManager.pieces.has(random_shape):
				GameManager.pieces[random_shape] = []
			
			GameManager.pieces[random_shape].append(random_type)
			var insert_index = Random.randi_range(0, max(0, GameManager.piece_queue.size() - 1))
			GameManager.piece_queue.insert(insert_index, random_shape)
			
			PointNotification.create_and_slide(get_center_position(), PointNotification.YELLOW, "+1 BLOCK")

		GameData.BLOCK_TYPES.GLASS:
			var multi: float = 1.5
			if custom_variables.get("glass_double_trigger", false):
				multi = 2.25
			GameManager.multiplier = GameManager.multiplier.multiply(multi)
			var notif_str = "x1.5" if multi == 1.5 else "x2.25!"
			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, notif_str)

		GameData.BLOCK_TYPES.DANGER:
			GameManager.add_points(10)
			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, "+10")
			
			var danger_blocks = GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.DANGER)
			var has_chain: bool = false
			for db in danger_blocks:
				if is_instance_valid(db) and not db.destroy_animation_requested:
					EventManager.add_event(BlockChainReaction.common_destroy.bind(db, 1))
					has_chain = true
			
			if has_chain:
				EventManager.should_check_lines_after_queue = true

		GameData.BLOCK_TYPES.STONE:
			GameManager.add_multiplier(10)
			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, 10, 1.8, PointNotification.UP, 6.0)

		GameData.BLOCK_TYPES.OBSIDIAN:
			var points: int = custom_variables.get(OBSIDIAN_FORTRESS_VARIABLE, 0)

			GameManager.add_multiplier(points)
			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, points)

			#AudioManager.play(AudioManager.SoundEffects.DICE, randf_range(0.4, 0.6))

		GameData.BLOCK_TYPES.RED_DICE:
			var random_value: int = Random.randi_range(1, 4) * GameManager.current_round

			GameManager.add_multiplier(random_value)
			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, random_value, 1.8, PointNotification.UP, max(2, random_value * 0.5))

			#AudioManager.play(AudioManager.SoundEffects.DICE, randf_range(0.8, 1.2))

		GameData.BLOCK_TYPES.BLUE_DICE:
			var random_value: int = Random.randi_range(1, 4) * GameManager.current_round

			GameManager.add_points(random_value)
			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, random_value, 1.8, PointNotification.UP, max(2, random_value * 0.5))

			#AudioManager.play(AudioManager.SoundEffects.DICE, randf_range(0.8, 1.2))

		GameData.BLOCK_TYPES.MIXED_DICE:
			var random_value: int = Random.randi_range(1, 3) * GameManager.current_round

			if Random.randf() < 0.5:
				GameManager.add_points(random_value)
				PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, random_value, 1.8, PointNotification.UP, max(2, random_value * 0.5))
			else:
				GameManager.add_multiplier(random_value)
				PointNotification.create_and_slide(get_center_position(), PointNotification.RED, random_value, 1.8, PointNotification.UP, max(2, random_value * 0.5))

			#AudioManager.play(AudioManager.SoundEffects.DICE, randf_range(0.8, 1.2))

		GameData.BLOCK_TYPES.RADIOACTIVE:
			GameManager.add_multiplier(1)
			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, 1, 1.8, PointNotification.UP, 6.0)
			#AudioManager.play(AudioManager.SoundEffects.RADIOACTIVE, randf_range(0.8, 1.2))

			Random.shuffle(all_blocks_on_board)

			var possible_blocks: Array[PlacedBlock] = []

			for block in all_blocks_on_board:
				if is_instance_valid(block) and not block.destroy_animation_requested and block.type != GameData.BLOCK_TYPES.RADIOACTIVE and block.type != "indestructible":
					possible_blocks.append(block)

			if possible_blocks.size() > 0:
				var target_block: PlacedBlock = Random.pick_random(possible_blocks)

				target_block.morph(GameData.BLOCK_TYPES.RADIOACTIVE)
				GameCamera.shake_randomly(1, 0.2)

				var reactor_queue: Array[Callable] = []

				for reactor_block in GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.REACTOR):
					reactor_queue.append(BlockChainReaction.reactor.bind(reactor_block))

				EventManager.execute_queue_events(reactor_queue)

		GameData.BLOCK_TYPES.TNT:
			GameCamera.shake_randomly(1, 0.2)
			#AudioManager.play(AudioManager.SoundEffects.DYNAMITE, randf_range(0.8, 1.2))

			for block in get_adjacent_blocks():
				EventManager.add_event(BlockChainReaction.tnt.bind(block))

		GameData.BLOCK_TYPES.BOMB:
			GameCamera.shake_randomly(3, 0.3)
			#AudioManager.play(AudioManager.SoundEffects.DYNAMITE, randf_range(0.6, 0.8))

			var blocks_in_range: Array[PlacedBlock] = get_blocks_in_range(3)

			blocks_in_range.sort_custom( func(a: PlacedBlock, b: PlacedBlock) -> bool:

				var dist_a: int = abs(a.grid_position.x - grid_position.x) + abs(a.grid_position.y - grid_position.y)
				var dist_b: int = abs(b.grid_position.x - grid_position.x) + abs(b.grid_position.y - grid_position.y)
				return dist_a < dist_b
			)

			for block in blocks_in_range:
				EventManager.add_event(BlockChainReaction.bomb.bind(block))

		GameData.BLOCK_TYPES.CFOUR:
			if custom_variables.get(CFOUR_VARIABLE, 0) < CFOUR_ACTIVATION_THRESHOLD:
				return

			GameCamera.shake_randomly(3, 0.3)
			#AudioManager.play(AudioManager.SoundEffects.DYNAMITE, randf_range(0.6, 0.8))

			var blocks_in_range: Array[PlacedBlock] = get_blocks_in_range(3)

			blocks_in_range.sort_custom( func(a: PlacedBlock, b: PlacedBlock) -> bool:

				var dist_a: int = abs(a.grid_position.x - grid_position.x) + abs(a.grid_position.y - grid_position.y)
				var dist_b: int = abs(b.grid_position.x - grid_position.x) + abs(b.grid_position.y - grid_position.y)
				return dist_a < dist_b
			)

			for block in blocks_in_range:
				EventManager.add_event(BlockChainReaction.cfour.bind(block))

			EventManager.execute_events()

		GameData.BLOCK_TYPES.DETONATOR:
			var explosive_blocks: Array[PlacedBlock] = GameManager.get_blocks_of_group(GameData.BlockGroups.EXPLOSIVES)

			#AudioManager.play(AudioManager.SoundEffects.DOUBLE_CLICK, randf_range(1.2, 1.4))

			for block in explosive_blocks:
				if block == self:
					continue

				if block.type != GameData.BLOCK_TYPES.DETONATOR:
					EventManager.add_event(BlockChainReaction.detonator.bind(block))

		GameData.BLOCK_TYPES.NUKE:
			var target_blocks: Array[PlacedBlock] = []

			target_blocks.append_array(_get_column_blocks(grid_position.x))

			GameCamera.shake_randomly(3, 0.3)
			#AudioManager.play(AudioManager.SoundEffects.DYNAMITE, randf_range(0.6, 0.8))

			for block in target_blocks:
				if block != self:
					EventManager.add_event(BlockChainReaction.nuke.bind(block))

		GameData.BLOCK_TYPES.BRONZE:
			var block_count: int = all_blocks_on_board.size()
			var point_value: int = floor(block_count * 0.3)

			for block in get_adjacent_blocks():
				if block.type == GameData.BLOCK_TYPES.DIAMOND:
					block.pulse_animation()
					point_value *= 3

			if point_value > 0:
				GameManager.add_points(point_value)
				PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, point_value, 1.8, PointNotification.UP, 6.0)

		GameData.BLOCK_TYPES.IRON:
			var block_count: int = all_blocks_on_board.size()
			var point_value: int = floor(block_count * 0.1)

			for block in get_adjacent_blocks():
				if block.type == GameData.BLOCK_TYPES.DIAMOND:
					block.pulse_animation()
					point_value *= 3

			if point_value > 0:
				GameManager.add_multiplier(point_value)
				PointNotification.create_and_slide(get_center_position(), PointNotification.RED, point_value, 1.8, PointNotification.UP, 6.0)

		GameData.BLOCK_TYPES.GRANITE:
			GameManager.points = GameManager.points.multiply(2)
			GameManager.multiplier = GameManager.multiplier.multiply(0.75)

			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, "x2", 1.6, PointNotification.UP, 6.0)
			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, "x0.75", 1.6, PointNotification.DOWN, 6.0)

		GameData.BLOCK_TYPES.DIAMOND:
			GameManager.add_points(3)
			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, 3, 1.8, PointNotification.UP, 6.0)

		GameData.BLOCK_TYPES.URANIUM:
			GameManager.add_points(10)
			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, 10, 1.8, PointNotification.UP, 6.0)

		GameData.BLOCK_TYPES.JACKPOT:
			var casino_blocks: Array[PlacedBlock] = GameManager.get_blocks_of_group(GameData.BlockGroups.CASINO)

			for block in casino_blocks:
				if block == self:
					continue

				if block.type != GameData.BLOCK_TYPES.JACKPOT:
					EventManager.add_event(BlockChainReaction.jackpot.bind(block))

		GameData.BLOCK_TYPES.HIVE:
			var queen_bee_count: int = GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.QUEEN_BEE).size()
			var worker_bee_count: int = GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.WORKER_BEE).size()

			if queen_bee_count > 0 and worker_bee_count > 0:
				var points: int = queen_bee_count * worker_bee_count

				var honey_blocks_count: int = get_adjacent_blocks_of_type(GameData.BLOCK_TYPES.HONEY).size()

				if honey_blocks_count > 0:
					points *= honey_blocks_count * 2

				GameManager.add_multiplier(points)
				PointNotification.create_and_slide(get_center_position(), PointNotification.RED, points)

				#AudioManager.play(AudioManager.SoundEffects.COLONY, randf_range(0.8, 1.2))

		GameData.BLOCK_TYPES.HONEY_BOMB:
			#AudioManager.play(AudioManager.SoundEffects.DYNAMITE, randf_range(1.1, 1.3))

			for adjacent_block in get_adjacent_blocks():
				if adjacent_block.type != GameData.BLOCK_TYPES.HIVE:
					EventManager.add_event(BlockChainReaction.honey_bomb.bind(adjacent_block))

		GameData.BLOCK_TYPES.MIMIC:

			var possible_blocks: Array[PlacedBlock] = []


			for block in all_blocks_on_board:
				if is_instance_valid(block) and not block.destroy_animation_requested and block.type != "indestructible":
					possible_blocks.append(block)

			var all_block_types: Array = GameData.BLOCK_TYPES.values()


			all_block_types.erase(GameData.BLOCK_TYPES.NORMAL)
			all_block_types.erase(GameData.BLOCK_TYPES.MOAI)
			all_block_types.erase(GameData.BLOCK_TYPES.X)
			all_block_types.erase(GameData.BLOCK_TYPES.MIMIC)

			if possible_blocks.size() > 0:
				var target_block: PlacedBlock = Random.pick_random(possible_blocks)
				target_block.morph(Random.pick_random(all_block_types))

			GameManager.add_multiplier(3)
			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, 3)
			#AudioManager.play(AudioManager.SoundEffects.EATING, randf_range(0.8, 1.2))

		GameData.BLOCK_TYPES.BOOKSHELF:



			GameManager.add_points(25)
			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, 25)

			var blocks_in_range: Array[PlacedBlock] = get_blocks_in_range(2)
			var block_types: Array = GameData.BLOCK_TYPES.values()


			block_types.erase(GameData.BLOCK_TYPES.NORMAL)
			block_types.erase(GameData.BLOCK_TYPES.MOAI)
			block_types.erase(GameData.BLOCK_TYPES.X)
			block_types.erase(GameData.BLOCK_TYPES.BOOKSHELF)

			for block in blocks_in_range:
				var random_block_type: String = Random.pick_random(block_types)
				EventManager.add_event(BlockChainReaction.bookshelf.bind(block, random_block_type))

		GameData.BLOCK_TYPES.ARCANIST:
			var arcane_blocks: Array[PlacedBlock] = GameManager.get_blocks_of_group(GameData.BlockGroups.ARCANE)

			#AudioManager.play(AudioManager.SoundEffects.MAGIC_SPELL, randf_range(0.6, 0.8))

			for block in arcane_blocks:
				if block == self:
					continue

				if block.type != GameData.BLOCK_TYPES.ARCANIST:
					EventManager.add_event(BlockChainReaction.arcanist.bind(block))

		GameData.BLOCK_TYPES.SLIME:

			var board: Board = GameManager.get_board()

			if is_instance_valid(board):
				var valid_positions: Array[Vector2i] = []


				var current_row: int = grid_position.y
				var start_row: int = current_row + 1


				if GameManager.current_boss == GameData.BossTypes.FALL_UP:

					start_row = current_row - 1
					for row in range(start_row, -1, -1):
						for col in range(Board.BOARD_WIDTH):
							if not board.is_position_occupied(Vector2i(col, row)):
								valid_positions.append(Vector2i(col, row))
				else:

					for row in range(start_row, Board.BOARD_HEIGHT):
						for col in range(Board.BOARD_WIDTH):
							if not board.is_position_occupied(Vector2i(col, row)):
								valid_positions.append(Vector2i(col, row))

				if valid_positions.size() > 0:
					var target_position: Vector2i = Random.pick_random(valid_positions)


					EventManager.add_event( func() -> float:
						board.place_blocks_directly([target_position], GameData.BLOCK_TYPES.SLIME)

						#AudioManager.play(AudioManager.SoundEffects.OWO_LOW, randf_range(0.8, 1.2))
						EventManager.request_line_check_after_queue()

						return BlockChainReaction.DEFAULT_DELAY
					)

		GameData.BLOCK_TYPES.PIANO:

			var piano_blocks_in_row: Array[PlacedBlock] = []
			var row_blocks: Array[PlacedBlock] = _get_row_blocks(grid_position.y)

			for block in row_blocks:
				if block.type == GameData.BLOCK_TYPES.PIANO:
					piano_blocks_in_row.append(block)

			var point_value: int = 4

			if piano_blocks_in_row.size() > 0:
				point_value *= piano_blocks_in_row.size()

			GameManager.add_points(point_value)
			#AudioManager.play(AudioManager.SoundEffects.PIANO, randf_range(0.8, 1.2))

			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, point_value)

		GameData.BLOCK_TYPES.ACOUSTIC_GUITAR:

			var acoustic_guitar_blocks_in_column: Array[PlacedBlock] = []
			var column_blocks: Array[PlacedBlock] = _get_column_blocks(grid_position.x)

			for block in column_blocks:
				if block.type == GameData.BLOCK_TYPES.ACOUSTIC_GUITAR:
					acoustic_guitar_blocks_in_column.append(block)

			var multiplier_value: int = 2

			if acoustic_guitar_blocks_in_column.size() > 0:
				multiplier_value *= acoustic_guitar_blocks_in_column.size()

			GameManager.add_multiplier(multiplier_value)
			#AudioManager.play(AudioManager.SoundEffects.ACOUSTIC_GUITAR, randf_range(0.8, 1.2))

			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, multiplier_value)

		GameData.BLOCK_TYPES.ELECTRIC_GUITAR:

			var electric_guitar_blocks_in_column: Array[PlacedBlock] = []
			var column_blocks: Array[PlacedBlock] = _get_column_blocks(grid_position.x)

			for block in column_blocks:
				if block.type == GameData.BLOCK_TYPES.ELECTRIC_GUITAR:
					electric_guitar_blocks_in_column.append(block)

			var point_value: int = 4

			if electric_guitar_blocks_in_column.size() > 0:
				point_value *= electric_guitar_blocks_in_column.size()

			GameManager.add_points(point_value)
			#AudioManager.play(AudioManager.SoundEffects.ELECTRIC_GUITAR, randf_range(0.8, 1.2))

			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, point_value)

		GameData.BLOCK_TYPES.SPEAKERS:

			var harmony_blocks: Array[PlacedBlock] = GameManager.get_blocks_of_group(GameData.BlockGroups.HARMONY)

			for harmony_block in harmony_blocks:
				if harmony_block == self or harmony_block.type == GameData.BLOCK_TYPES.SPEAKERS or harmony_block.destroy_animation_requested:
					continue

				EventManager.add_event(BlockChainReaction.speakers.bind(harmony_block))

		GameData.BLOCK_TYPES.SKELETON:
			BlockProjectile.create(get_parent(), type, get_center_position() - Vector2(0, PieceRenderer.PIECE_SIZE / 2))

		GameData.BLOCK_TYPES.FIRE_MAGE:
			GameCamera.shake_direction(2, 90, 0.2)
			#AudioManager.play(AudioManager.SoundEffects.FIRE_BALL, randf_range(0.8, 1.2))

			var fireball_1: BlockProjectile = BlockProjectile.create(get_parent(), type, get_center_position() - Vector2(0, PieceRenderer.PIECE_SIZE / 2))
			var fireball_2: BlockProjectile = BlockProjectile.create(get_parent(), type, get_center_position() - Vector2(0, PieceRenderer.PIECE_SIZE / 2))

			fireball_1.velocity = Vector2(BlockProjectile.HORIZONTAL_SPEED, -150.0 * fireball_1._get_up_multiplier())
			fireball_2.velocity = Vector2( - BlockProjectile.HORIZONTAL_SPEED, -150.0 * fireball_2._get_up_multiplier())

		GameData.BLOCK_TYPES.UNDEAD_PIRATE:
			GameCamera.shake_direction(2, 90, 0.2)
			#AudioManager.play(AudioManager.SoundEffects.QUICK_BLOOD, randf_range(0.8, 1.2))

			BlockProjectile.create(get_parent(), type, get_center_position() - Vector2(0, PieceRenderer.PIECE_SIZE / 2))

		GameData.BLOCK_TYPES.PIRATE_CAPTAIN:
			GameManager.add_points(3)
			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, 3, 1.8, PointNotification.UP, 6.0)

			var pirate_cannoneer_blocks: Array[PlacedBlock] = GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.PIRATE_CANNONEER)

			for block in pirate_cannoneer_blocks:
				if block.destroy_animation_requested:
					continue

				EventManager.add_event(BlockChainReaction.pirate_captain.bind(block))

		GameData.BLOCK_TYPES.PIRATE_CANNONEER:
			GameManager.add_multiplier(1)
			PointNotification.create_and_slide(get_center_position(), PointNotification.RED, 1, 1.8, PointNotification.UP, 6.0)

			var cannon_blocks: Array[PlacedBlock] = GameManager.get_blocks_of_type(GameData.BLOCK_TYPES.CANNON)


			for cannon in cannon_blocks:
				if cannon.destroy_animation_requested:
					continue

				EventManager.add_event(BlockChainReaction.pirate_cannoneer.bind(cannon))

		GameData.BLOCK_TYPES.TREASURE_CHEST:

			if Random.randf() < 0.5:
				GameManager.add_points(100)
				PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, 100, 1.8, PointNotification.UP, 6.0)

		GameData.BLOCK_TYPES.CURSED_CHEST:

			if Random.randf() < 0.15:
				GameManager.add_points(1000)
				PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, 1000, 1.8, PointNotification.UP, 6.0)
			else:
				GameManager.add_points(-100)
				PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, "-100", 1.8, PointNotification.UP, 6.0)

		GameData.BLOCK_TYPES.CANNON:
			GameManager.add_points(3)
			PointNotification.create_and_slide(get_center_position(), PointNotification.BLUE, 3, 1.8, PointNotification.UP, 6.0)
