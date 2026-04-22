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
