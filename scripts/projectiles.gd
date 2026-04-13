class_name BlockProjectile extends Area2D


const PACKED_SCENE: PackedScene = preload("res://scenes/projectile.tscn")


const PROJECTILE_TEXTURE_MAP: Dictionary = {
	#GameData.BLOCK_TYPES.SKELETON: preload("res://images/projectiles/bone.png"), 
	#GameData.BLOCK_TYPES.FIRE_MAGE: preload("res://images/projectiles/fireball.png"), 
	#GameData.BLOCK_TYPES.PIRATE_CANNONEER: preload("res://images/projectiles/knife.png"), 
	#GameData.BLOCK_TYPES.CANNON: preload("res://images/projectiles/cannon_ball.png"), 
	#GameData.BLOCK_TYPES.UNDEAD_PIRATE: preload("res://images/projectiles/undead_arm.png"), 
}

const PROJECTILE_PARTICLE_COLOR_MAP: Dictionary = {
	GameData.BLOCK_TYPES.FIRE_MAGE: Color("ffc825"), 
	GameData.BLOCK_TYPES.CANNON: Color("5d5d5d"), 
	GameData.BLOCK_TYPES.SKELETON: Color("ffffff64"), 
	GameData.BLOCK_TYPES.PIRATE_CANNONEER: Color("ffffff64"), 
}

const MAXIMUM_LIFETIME: float = 5.0

const JUMP_FORCE: float = 250.0
const GRAVITY: float = 550.0
const HORIZONTAL_SPEED: float = 50.0
const BOARD_WIDTH_PIXELS: float = 120.0
const BOARD_HEIGHT_PIXELS: float = 240.0
const DESTROY_ANIMATION_DURATION: float = 0.15


var associated_block_type: String:
	set(value):
		associated_block_type = value

		if associated_block_type in PROJECTILE_TEXTURE_MAP:
			sprite_shadowed.texture = PROJECTILE_TEXTURE_MAP[associated_block_type]
			sprite_shadowed.shadow_texture = PROJECTILE_TEXTURE_MAP[associated_block_type]

		if associated_block_type in PROJECTILE_PARTICLE_COLOR_MAP:
			particles.emitting = true
			(particles.process_material as ParticleProcessMaterial).color = PROJECTILE_PARTICLE_COLOR_MAP[associated_block_type]
		else:
			particles.emitting = false

		if associated_block_type == GameData.BLOCK_TYPES.SKELETON:
			velocity = Vector2([HORIZONTAL_SPEED, - HORIZONTAL_SPEED].pick_random(), - JUMP_FORCE * _get_up_multiplier())

		elif associated_block_type == GameData.BLOCK_TYPES.PIRATE_CANNONEER:
			velocity = Vector2([150.0, -150.0].pick_random(), 0.0)

		elif associated_block_type == GameData.BLOCK_TYPES.CANNON:
			velocity = Vector2(0.0, -400 * _get_up_multiplier())

		if associated_block_type == GameData.BLOCK_TYPES.UNDEAD_PIRATE:
			velocity = Vector2([HORIZONTAL_SPEED, - HORIZONTAL_SPEED].pick_random(), - JUMP_FORCE * _get_up_multiplier())


var blocks_hit_count: int = 0
var lifetime: float = 0.0

var velocity: Vector2 = Vector2.ZERO
var board_left_boundary: float = 0.0
var board_right_boundary: float = BOARD_WIDTH_PIXELS
var board_top_boundary: float = 0.0
var board_bottom_boundary: float = 0.0
var destroy_animation_requested: bool = false


@onready var sprite_shadowed: SpriteShadowed = $SpriteShadowed
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var lifetime_maximum_timer: Timer = $LifetimeMaximumTimer
@onready var calculation_blocker: CalculationBlocker = $CalculationBlocker


static func create(parent: Node, block_type: String, start_global_position: Vector2) -> BlockProjectile:
	var projectile: BlockProjectile = PACKED_SCENE.instantiate()

	parent.add_child.call_deferred(projectile)
	projectile.set_deferred("global_position", start_global_position)
	projectile.set_deferred("associated_block_type", block_type)

	return projectile


func _ready() -> void :

	var board: Board = GameManager.get_board()

	particles.speed_scale = GameManager.timescale

	calculation_blocker.activate()

	if is_instance_valid(board):
		board_left_boundary = board.global_position.x
		board_right_boundary = board.global_position.x + BOARD_WIDTH_PIXELS
		board_top_boundary = board.global_position.y
		board_bottom_boundary = board.global_position.y + BOARD_HEIGHT_PIXELS

	area_entered.connect( func(block_collision_area: Area2D) -> void :
		if destroy_animation_requested:
			return;
		var hit_block: PlacedBlock = block_collision_area.get_parent() as PlacedBlock
		if !(hit_block && is_instance_valid(hit_block) and hit_block.type == "indestructible"):
			return
		
		if associated_block_type == GameData.BLOCK_TYPES.FIRE_MAGE:
			if lifetime <= 0.3:
				return

			blocks_hit_count += 1

			EventManager.add_projectile_event(BlockChainReaction.fire_mage.bind(block_collision_area.get_parent() as PlacedBlock))
			var countLeft := 3;
			if GameManager.is_perk_active(GameData.Perks.PROJECTILE_HIT):
				countLeft *= 2;
			if blocks_hit_count >= countLeft:
				play_destroy_animation()

		elif associated_block_type == GameData.BLOCK_TYPES.SKELETON:

			var is_falling_with_gravity: bool = (velocity.y > 0 and _get_up_multiplier() > 0) or (velocity.y < 0 and _get_up_multiplier() < 0)
			if not is_falling_with_gravity:
				return

			EventManager.add_projectile_event(BlockChainReaction.skeleton_bone.bind(block_collision_area.get_parent() as PlacedBlock))
			play_destroy_animation()

		elif associated_block_type == GameData.BLOCK_TYPES.UNDEAD_PIRATE:
			velocity.y = - JUMP_FORCE * _get_up_multiplier()
			blocks_hit_count += 1

			EventManager.add_projectile_event(BlockChainReaction.undead_pirate_bone.bind(block_collision_area.get_parent() as PlacedBlock))
			var countLeft := 5;
			if GameManager.is_perk_active(GameData.Perks.PROJECTILE_HIT):
				countLeft *= 2;
			if blocks_hit_count >= countLeft:
				play_destroy_animation()
				return

		elif associated_block_type == GameData.BLOCK_TYPES.PIRATE_CANNONEER:
			if lifetime <= 0.1:
				return

			EventManager.add_projectile_event(BlockChainReaction.pirate_cannoneer_knife.bind(block_collision_area.get_parent() as PlacedBlock))
			play_destroy_animation()

		elif associated_block_type == GameData.BLOCK_TYPES.CANNON:
			if lifetime <= 0.2:
				return

			EventManager.add_projectile_event(BlockChainReaction.cannon_cannonball.bind(block_collision_area.get_parent() as PlacedBlock))
	)

	lifetime_maximum_timer.timeout.connect( func() -> void :
		play_destroy_animation()
	)


func play_destroy_animation() -> void :
	if destroy_animation_requested:
		return

	destroy_animation_requested = true
	particles.emitting = false

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN).set_parallel()

	tween.tween_property(sprite_shadowed.main_sprite, "scale", Vector2.ZERO, DESTROY_ANIMATION_DURATION / GameManager.timescale)
	tween.tween_property(sprite_shadowed.shadow_sprite, "scale", Vector2.ZERO, DESTROY_ANIMATION_DURATION / GameManager.timescale)

	tween.chain().tween_callback( func() -> void :
		calculation_blocker.deactivate()
		queue_free()
	)


func _physics_process(delta: float) -> void :
	if GameManager.paused or destroy_animation_requested:
		return

	lifetime += delta * GameManager.timescale

	if lifetime >= MAXIMUM_LIFETIME:
		play_destroy_animation()
		return

	if associated_block_type == GameData.BLOCK_TYPES.SKELETON:
		sprite_shadowed.rotation += delta * 5.0 * GameManager.timescale

		velocity.y += GRAVITY * delta * GameManager.timescale * _get_up_multiplier()


		if global_position.x <= board_left_boundary:
			global_position.x = board_left_boundary
			velocity.x = abs(velocity.x)
		elif global_position.x >= board_right_boundary:
			global_position.x = board_right_boundary
			velocity.x = - abs(velocity.x)


		if _get_up_multiplier() > 0 and global_position.y >= board_bottom_boundary:
			play_destroy_animation()
			return
		elif _get_up_multiplier() < 0 and global_position.y <= board_top_boundary:
			play_destroy_animation()
			return

	elif associated_block_type == GameData.BLOCK_TYPES.UNDEAD_PIRATE:
		sprite_shadowed.rotation += delta * 5.0 * GameManager.timescale

		velocity.y += GRAVITY * delta * GameManager.timescale * _get_up_multiplier()


		if global_position.x <= board_left_boundary:
			global_position.x = board_left_boundary
			velocity.x = abs(velocity.x)
		elif global_position.x >= board_right_boundary:
			global_position.x = board_right_boundary
			velocity.x = - abs(velocity.x)


		if _get_up_multiplier() > 0 and global_position.y >= board_bottom_boundary:
			play_destroy_animation()
			return
		elif _get_up_multiplier() < 0 and global_position.y <= board_top_boundary:
			play_destroy_animation()
			return


	elif associated_block_type == GameData.BLOCK_TYPES.FIRE_MAGE:

		if global_position.x <= board_left_boundary:
			global_position.x = board_left_boundary
			velocity.x = abs(velocity.x)
		elif global_position.x >= board_right_boundary:
			global_position.x = board_right_boundary
			velocity.x = - abs(velocity.x)


		if _get_up_multiplier() > 0:

			if global_position.y <= board_top_boundary:
				global_position.y = board_top_boundary
				velocity.y = abs(velocity.y)
			if global_position.y >= board_bottom_boundary:
				play_destroy_animation()
				return
		else:

			if global_position.y >= board_bottom_boundary:
				global_position.y = board_bottom_boundary
				velocity.y = - abs(velocity.y)
			if global_position.y <= board_top_boundary:
				play_destroy_animation()
				return

	elif associated_block_type == GameData.BLOCK_TYPES.PIRATE_CANNONEER:
		sprite_shadowed.rotation += delta * 20.0 * GameManager.timescale

		if global_position.x <= board_left_boundary:
			global_position.x = board_left_boundary
			play_destroy_animation()

		elif global_position.x >= board_right_boundary:
			global_position.x = board_right_boundary
			play_destroy_animation()

	elif associated_block_type == GameData.BLOCK_TYPES.CANNON:
		velocity.y += GRAVITY * delta * GameManager.timescale * _get_up_multiplier()

		if global_position.y <= board_top_boundary:
			global_position.y = board_top_boundary
			play_destroy_animation()

		if global_position.y >= board_bottom_boundary:
			global_position.y = board_bottom_boundary
			play_destroy_animation()


	global_position += velocity * delta * GameManager.timescale



func _get_up_multiplier() -> float:
	return -1.0 if GameManager.current_boss == GameData.BossTypes.FALL_UP else 1.0
