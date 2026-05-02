extends Node

const DEFAULT_DELAY: float = 0.09


func common_destroy(block: PlacedBlock, cleared_lines_count: int = 1) -> float:
	if block.destroy_animation_requested:
		return 0.0
	if block.type == "indestructible":
		return 0.0

	block.destroy_animation_requested = true
	block.destroy()

	if block.grid_position.x == 9:
		if GameManager.current_deck == GameData.DeckTypes.X:
			GameManager.add_points(cleared_lines_count)
			PointNotification.create_and_slide(block.get_center_position(), PointNotification.BLUE, cleared_lines_count, 1.8, 0)
		else:
			GameManager.add_multiplier(cleared_lines_count)
			PointNotification.create_and_slide(block.get_center_position(), PointNotification.RED, cleared_lines_count, 1.8, 0)

	return DEFAULT_DELAY


func brick(block: PlacedBlock) -> float:
	block.pulse_animation()
	block.activation_count += 1

	GameManager.add_multiplier(1)
	PointNotification.create_and_slide(block.get_center_position(), PointNotification.RED, 1)

	return DEFAULT_DELAY


func granite(block: PlacedBlock) -> float:
	block.pulse_animation()
	block.activation_count += 1

	GameManager.points = GameManager.points.minus(1)
	PointNotification.create_and_slide(block.get_center_position(), PointNotification.BLUE, -1)

	return DEFAULT_DELAY


func jackpot(block: PlacedBlock) -> float:
	block.pulse_animation()
	block.execute_destroy_effect()

	return DEFAULT_DELAY


func worker_bee(block: PlacedBlock, adjacent_colony_block_count: int) -> float:
	var points: int = adjacent_colony_block_count * 0.5


	var honey_blocks_count: int = block.get_adjacent_blocks_of_type(GameData.BLOCK_TYPES.HONEY).size()

	if honey_blocks_count > 0:
		points *= honey_blocks_count * 2

	if points >= 1:
		block.pulse_animation()
		block.activation_count += 1

		GameManager.add_points(points)
		PointNotification.create_and_slide(block.get_center_position(), PointNotification.BLUE, points)
		#AudioManager.play(AudioManager.SoundEffects.COLONY, randf_range(0.8, 1.2))

		return DEFAULT_DELAY

	return 0.0


func queen_bee(block: PlacedBlock, adjacent_colony_block_count: int) -> float:
	var points: int = adjacent_colony_block_count * 0.5


	var honey_blocks_count: int = block.get_adjacent_blocks_of_type(GameData.BLOCK_TYPES.HONEY).size()

	if honey_blocks_count > 0:
		points *= honey_blocks_count * 2

	if points >= 1:
		block.pulse_animation()
		block.activation_count += 1

		GameManager.add_multiplier(points)
		PointNotification.create_and_slide(block.get_center_position(), PointNotification.RED, points)
		#AudioManager.play(AudioManager.SoundEffects.COLONY, randf_range(0.8, 1.2))

		return DEFAULT_DELAY

	return 0.0


func reactor(block: PlacedBlock) -> float:
	GameManager.add_multiplier(1)

	block.pulse_animation()
	PointNotification.create_and_slide(block.get_center_position(), PointNotification.RED, 1)

	return DEFAULT_DELAY


func nuke(block: PlacedBlock) -> float:
	var points: int = 1

	if GameData.is_block_on_group(block.type, GameData.BlockGroups.NUCLEAR):
		points = 5

	GameManager.add_points(points)
	PointNotification.create_and_slide(block.get_center_position(), PointNotification.BLUE, points)

	block.destroy()

	return DEFAULT_DELAY


func tnt(block: PlacedBlock) -> float:
	block.destroy()

	GameManager.add_points(3)
	PointNotification.create_and_slide(block.get_center_position(), PointNotification.BLUE, 3)

	#AudioManager.play(AudioManager.SoundEffects.DYNAMITE, randf_range(0.8, 1.2))

	return DEFAULT_DELAY


func bomb(block: PlacedBlock) -> float:
	block.destroy()

	GameManager.add_multiplier(1)
	PointNotification.create_and_slide(block.get_center_position(), PointNotification.RED, 1)

	#AudioManager.play(AudioManager.SoundEffects.DYNAMITE, randf_range(0.6, 0.8))

	return DEFAULT_DELAY


func cfour(block: PlacedBlock) -> float:
	block.destroy()

	GameManager.add_points(3)
	PointNotification.create_and_slide(block.get_center_position(), PointNotification.BLUE, 3)

	#AudioManager.play(AudioManager.SoundEffects.DYNAMITE, randf_range(0.8, 1.2))

	return DEFAULT_DELAY


func detonator(block: PlacedBlock) -> float:
	block.destroy()

	return DEFAULT_DELAY


func bookshelf(block: PlacedBlock, new_type: String) -> float:
	block.morph(new_type)
	block.pulse_animation(true)

	#AudioManager.play(AudioManager.SoundEffects.MAGIC_SPELL, randf_range(0.8, 1.2))

	return DEFAULT_DELAY


func arcanist(block: PlacedBlock) -> float:
	block.pulse_animation()
	block.execute_destroy_effect()

	#AudioManager.play(AudioManager.SoundEffects.SINGLE_CLICK_3, randf_range(0.8, 1.2))

	return DEFAULT_DELAY


func speakers(block: PlacedBlock) -> float:

	block.pulse_animation()
	block.execute_destroy_effect()

	return DEFAULT_DELAY




func pirate_captain(block: PlacedBlock) -> float:
	block.pulse_animation()

	#AudioManager.play(AudioManager.SoundEffects.STRING, randf_range(0.8, 1.2))
	GameCamera.shake_direction(0.5, 0, 0.2)
	BlockProjectile.create(block.get_parent(), block.type, block.get_center_position())
	
	if (GameManager.is_perk_active(GameData.Perks.PROJECTILE_MULT)):
		get_tree().root.create_timer(0.1).timeout.connect(func():
			BlockProjectile.create(block.get_parent(), block.type, block.get_center_position())
		);

	return DEFAULT_DELAY


func pirate_cannoneer_knife(block: PlacedBlock) -> float:
	block.destroy()

	GameCamera.shake_randomly(0.5, 0.2)
	#AudioManager.play(AudioManager.SoundEffects.LINE_BREAK, randf_range(0.8, 1.2))

	return DEFAULT_DELAY




func pirate_cannoneer(block: PlacedBlock) -> float:
	block.pulse_animation()

	GameCamera.shake_direction(0.5, 90, 0.2)
	#AudioManager.play(AudioManager.SoundEffects.CANNON, randf_range(0.8, 1.2))
	BlockProjectile.create(block.get_parent(), block.type, block.get_center_position())
	if (GameManager.is_perk_active(GameData.Perks.PROJECTILE_MULT)):
		get_tree().root.create_timer(0.1).timeout.connect(func():
			BlockProjectile.create(block.get_parent(), block.type, block.get_center_position())
		);

	return DEFAULT_DELAY


func cannon_cannonball(block: PlacedBlock) -> float:
	block.destroy()

	GameCamera.shake_randomly(0.5, 0.2)
	#AudioManager.play(AudioManager.SoundEffects.LINE_BREAK, randf_range(0.8, 1.2))

	return DEFAULT_DELAY


func skeleton_bone(block: PlacedBlock) -> float:
	block.destroy()

	GameManager.add_points(5)
	PointNotification.create_and_slide(block.get_center_position(), PointNotification.BLUE, 5, 1.8, PointNotification.DOWN)

	#AudioManager.play(AudioManager.SoundEffects.BONE_CRACK, randf_range(0.8, 1.2))
	GameCamera.shake_randomly(0.5, 0.2)

	return DEFAULT_DELAY


func undead_pirate_bone(block: PlacedBlock) -> float:
	block.destroy()

	GameManager.add_points(5)
	PointNotification.create_and_slide(block.get_center_position(), PointNotification.BLUE, 5, 1.8, PointNotification.DOWN)

	#AudioManager.play(AudioManager.SoundEffects.BONE_CRACK, randf_range(0.8, 1.2))
	#AudioManager.play(AudioManager.SoundEffects.QUICK_BLOOD, randf_range(0.8, 1.2))

	GameCamera.shake_randomly(0.5, 0.2)

	return DEFAULT_DELAY


func fire_mage(block: PlacedBlock) -> float:
	block.destroy()

	GameManager.add_multiplier(5)
	PointNotification.create_and_slide(block.get_center_position(), PointNotification.RED, 5)

	#AudioManager.play(AudioManager.SoundEffects.LINE_BREAK, randf_range(0.5, 0.6))

	GameCamera.shake_randomly(0.5, 0.2)

	return DEFAULT_DELAY


func honey_bomb(block: PlacedBlock) -> float:
	block.morph(GameData.BLOCK_TYPES.HONEY)

	GameCamera.shake_randomly(0.3, 0.1)
	#AudioManager.play(AudioManager.SoundEffects.RADIOACTIVE, randf_range(1.2, 1.4))

	return DEFAULT_DELAY


func honey_dice(honey_dice_block: PlacedBlock, colony_blocks_count: int) -> float:
	honey_dice_block.pulse_animation()

	var points: int = roundi(colony_blocks_count * 0.5)

	GameManager.add_points(points)
	PointNotification.create_and_slide(honey_dice_block.get_center_position(), PointNotification.BLUE, points)

	#AudioManager.play(AudioManager.SoundEffects.DICE, randf_range(1.2, 1.4))
	#AudioManager.play(AudioManager.SoundEffects.COLONY, randf_range(0.8, 1.2))

	return DEFAULT_DELAY
